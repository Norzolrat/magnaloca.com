# Configuration du provider Proxmox
terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

# Configuration du provider avec token
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = "${var.proxmox_user}!${var.proxmox_token_name}"
  pm_api_token_secret = var.proxmox_token
  pm_tls_insecure     = true
}

# Volume pour les données Traefik
resource "proxmox_lxc" "traefik_container" {
  vmid         = var.container_id
  target_node  = var.proxmox_node
  hostname     = var.container_hostname
  ostemplate   = "${var.proxmox_template_storage}:vztmpl/debian-magnaloca.tar.xz"
  unprivileged = true
  onboot       = true
  start        = true

  # Configuration réseau
  network {
    name     = "eth0"
    bridge   = var.network_bridge
    ip       = var.container_ip
    gw       = var.container_gateway
    firewall = false
  }
  
  # Configuration des ressources
  memory = var.container_memory
  swap   = var.container_swap
  cores  = var.container_cores
  
  # Configuration du stockage
  rootfs {
    storage = var.proxmox_storage
    size    = var.container_disk_size
  }

# TODO Volumes
  
  # Configuration SSH si clé publique fournie
  ssh_public_keys = var.ssh_public_keys != "" ? var.ssh_public_keys : null
  
  # Pas de mot de passe root - accès direct via shell
  password = "sdfedc"

  # Tags pour organiser tes ressources
  tags = "terraform,debian,traefik"
}

# Attendre que le container soit démarré
resource "time_sleep" "wait_for_container" {
  depends_on      = [proxmox_lxc.traefik_container]
  create_duration = "60s"
}

# Génération du hash du mot de passe dashboard
locals {
  dashboard_password_hash = var.enable_dashboard ? bcrypt(var.dashboard_auth_password) : ""
}

# Template de configuration statique Traefik
resource "local_file" "traefik_config" {
  filename = "${path.module}/templates/traefik.yaml"
  content = templatefile("${path.module}/templates/traefik.yaml.tpl", {
    http_port             = var.http_port
    https_port            = var.https_port
    dashboard_port        = var.dashboard_port
    traefik_log_level     = var.traefik_log_level
    enable_dashboard      = var.enable_dashboard
    enable_lets_encrypt   = var.enable_lets_encrypt
    redirect_http_to_https = var.redirect_http_to_https
    lets_encrypt_email    = var.lets_encrypt_email
    lets_encrypt_staging  = var.lets_encrypt_staging
  })
}

# Template de configuration dynamique
resource "local_file" "traefik_dynamic_config" {
  filename = "${path.module}/templates/dynamic.yaml"
  content = templatefile("${path.module}/templates/dynamic.yaml.tpl", {
    upstream_services           = var.upstream_services
    enable_dashboard           = var.enable_dashboard
    enable_lets_encrypt        = var.enable_lets_encrypt
    dashboard_auth_user        = var.dashboard_auth_user
    dashboard_auth_password_hash = local.dashboard_password_hash
  })
}

# Template du service systemd
resource "local_file" "traefik_service" {
  filename = "${path.module}/templates/traefik.service"
  content = templatefile("${path.module}/templates/traefik.service.tpl", {
    traefik_version = var.traefik_version
  })
}

# Génération du fichier d'environnement (simplifié)
resource "local_file" "env_export" {
  filename = "${path.module}/traefik.env"
  content = <<EOF
# Configuration Container
CONTAINER_HOSTNAME="${var.container_hostname}"
CONTAINER_IP_ADDRESS="${var.container_ip_address}"
TRAEFIK_VERSION="${var.traefik_version}"

# Sécurité
ENABLE_FIREWALL=${var.enable_firewall}
ALLOWED_NETWORKS='${jsonencode(var.allowed_networks)}'

# Sauvegarde
ENABLE_BACKUP=${var.enable_backup}
BACKUP_SCHEDULE="${var.backup_schedule}"
BACKUP_RETENTION_DAYS=${var.backup_retention_days}

# Configuration de base
HTTP_PORT=${var.http_port}
HTTPS_PORT=${var.https_port}
DASHBOARD_PORT=${var.dashboard_port}
ENABLE_LETS_ENCRYPT=${var.enable_lets_encrypt}
ENABLE_DASHBOARD=${var.enable_dashboard}
EOF
}

resource "null_resource" "traefik_setup" {
  depends_on = [
    time_sleep.wait_for_container,
    local_file.env_export,
    local_file.traefik_config,
    local_file.traefik_dynamic_config,
    local_file.traefik_service
  ]

  # Déclencher à chaque fois que le container change
  triggers = {
    container_id       = proxmox_lxc.traefik_container.id
    traefik_version    = var.traefik_version
    env_hash          = local_file.env_export.content_md5
    config_hash       = local_file.traefik_config.content_md5
    dynamic_hash      = local_file.traefik_dynamic_config.content_md5
    service_hash      = local_file.traefik_service.content_md5
  }

  connection {
    type        = "ssh"
    host        = var.container_ip_address
    user        = "root"
    timeout     = "5m"
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/traefik.env"
    destination = "/tmp/traefik.env"
  }

    provisioner "file" {
    source      = "${path.module}/templates"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "${path.module}/scripts"
    destination = "/tmp/"
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/scripts/*.sh",
      "/bin/bash -c 'source /tmp/traefik.env && bash /tmp/scripts/deploy.sh'"
    ]
  }
}

# Sortie de l'adresse IP du container
output "container_ip" {
  value       = proxmox_lxc.traefik_container.network[0].ip
  description = "Adresse IP du container Proxy Traefik"
}

output "traefik_connection" {
  value       = "http://@${var.container_ip_address}:8080"
  description = "URL par défaut pour accéder au dashboard"
}

output "ssh_access" {
  value       = "ssh -i ${var.ssh_private_key_path} root@${var.container_ip_address}"
  description = "Commande SSH pour accéder au container"
}