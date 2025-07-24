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
  # pm_user             = var.proxmox_user
  # pm_api_token_id     = var.proxmox_token_name

  pm_api_token_id     = "${var.proxmox_user}!${var.proxmox_token_name}"

  pm_api_token_secret = var.proxmox_token
  pm_tls_insecure     = true
}

# Volume pour les données PostgreSQL
resource "proxmox_lxc" "postgresql_container" {
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

  # Volume persistant pour les données PostgreSQL
  mountpoint {
    key     = "0"
    slot    = 0
    storage = var.proxmox_storage
    size    = var.postgres_data_size
    mp      = "/var/lib/postgresql"
  }
  
  # Volume persistant pour les logs PostgreSQL
  mountpoint {
    key     = "1"
    slot    = 1
    storage = var.proxmox_storage
    size    = var.postgres_logs_size
    mp      = "/var/log/postgresql"
  }
  
  # Volume optionnel pour les sauvegardes
  dynamic "mountpoint" {
    for_each = var.enable_backup_volume ? [1] : []
    content {
      key     = "2"
      slot    = 2
      storage = var.proxmox_storage
      size    = var.postgres_backup_size
      mp      = "/var/backups/postgresql"
    }
  }
  
  # Configuration SSH si clé publique fournie
  ssh_public_keys = var.ssh_public_keys != "" ? var.ssh_public_keys : null
  
  # Pas de mot de passe root - accès direct via shell
  password = "sdfedc"

  # Tags pour organiser tes ressources
  tags = "terraform,debian,postgres"
}

# Attendre que le container soit démarré
resource "time_sleep" "wait_for_container" {
  depends_on      = [proxmox_lxc.postgresql_container]
  create_duration = "60s"
}

# Configuration POSTGRESQL via provisioner
resource "local_file" "env_export" {
  filename = "${path.module}/postgres.env"
  content = <<EOF
POSTGRES_VERSION="${var.postgres_version}"
POSTGRES_LISTEN_ADDRESSES="${var.postgres_listen_addresses}"
POSTGRES_PORT=${var.postgres_port}
POSTGRES_MAX_CONNECTIONS=${var.postgres_max_connections}
POSTGRES_SHARED_BUFFERS="${var.postgres_shared_buffers}"
POSTGRES_ROOT_PASSWORD="${var.postgres_root_password}"
POSTGRES_DATABASE_NAME="${var.postgres_database_name}"
POSTGRES_APP_USER="${var.postgres_app_user}"
POSTGRES_APP_PASSWORD="${var.postgres_app_password}"
CONTAINER_HOSTNAME="${var.container_hostname}"
CONTAINER_IP_ADDRESS="${var.container_ip_address}"
ENABLE_BACKUP_VOLUME=${var.enable_backup_volume}
ENABLE_AUTO_BACKUP=${var.enable_auto_backup}
BACKUP_RETENTION_DAYS=${var.backup_retention_days}
BACKUP_SCHEDULE="${var.backup_schedule}"
ALLOWED_NETWORKS='${jsonencode(var.allowed_networks)}'
ENABLE_FIREWALL=${var.enable_firewall}
EOF
}


resource "null_resource" "postgresql_setup" {
  depends_on = [time_sleep.wait_for_container, local_file.env_export]
  
  # Déclencher à chaque fois que le container change
  triggers = {
    container_id = proxmox_lxc.postgresql_container.id
    postgres_version = var.postgres_version
    env_hash = local_file.env_export.content_md5
  }

  connection {
    type        = "ssh"
    host        = var.container_ip_address
    user        = "root"
    timeout     = "5m"
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/postgres.env"
    destination = "/tmp/postgres.env"
  }

    provisioner "file" {
    source      = "${path.module}/templates"
    destination = "/tmp/"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/postgresql.conf.tpl", {
      postgres_version = var.postgres_version
      postgres_listen_addresses = var.postgres_listen_addresses
      postgres_port = var.postgres_port
      postgres_max_connections = var.postgres_max_connections
      postgres_shared_buffers = var.postgres_shared_buffers
    })
    destination = "/tmp/templates/postgresql.conf"
  }

  provisioner "file" {
    source      = "${path.module}/scripts"
    destination = "/tmp/"
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/scripts/*.sh",
      "/bin/bash -c 'source /tmp/postgres.env && bash /tmp/scripts/deploy.sh'"
    ]
  }
}

# Sortie de l'adresse IP du container
output "container_ip" {
  value       = proxmox_lxc.postgresql_container.network[0].ip
  description = "Adresse IP du container PostgreSQL"
}

output "postgres_connection" {
  value       = "postgresql://${var.postgres_app_user}@${var.container_ip_address}:${var.postgres_port}/${var.postgres_database_name}"
  description = "Chaîne de connexion PostgreSQL (sans mot de passe)"
}

output "ssh_access" {
  value       = "ssh -i ${var.ssh_private_key_path} root@${var.container_ip_address}"
  description = "Commande SSH pour accéder au container"
}