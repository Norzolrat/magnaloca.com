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

# Création du container LXC
resource "proxmox_lxc" "debian_apache_container" {
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
  
  # Configuration SSH si clé publique fournie
  ssh_public_keys = var.ssh_public_keys != "" ? var.ssh_public_keys : null
  
  # Pas de mot de passe root - accès direct via shell
  password = "sdfedc"

  # Tags pour organiser tes ressources
  tags = "terraform,debian,apache2"
}

# Attendre que le container soit démarré
resource "time_sleep" "wait_for_container" {
  depends_on      = [proxmox_lxc.debian_apache_container]
  create_duration = "45s"
}

# Configuration d'Apache2 via provisioner
resource "null_resource" "apache_setup" {
  depends_on = [time_sleep.wait_for_container]
  
  # Déclencher à chaque fois que le container change
  triggers = {
    container_id = proxmox_lxc.debian_apache_container.id
  }
  
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = var.container_ip_address
      user        = "root"
      timeout     = "5m"
      private_key = file(var.ssh_private_key_path)
    }
    
    inline = [
      # Attendre que le réseau soit prêt
      "sleep 10",
      
      # Mise à jour du système
      "apt-get update",
      "apt-get upgrade -y",
      
      # Installation d'Apache2
      "apt-get install -y apache2",
      
      # Création de la page Hello World
      "cat > /var/www/html/index.html << 'EOF'",
      "Hello World!",
      "EOF",
      
      # Démarrage et activation d'Apache2
      "systemctl enable apache2",
      "systemctl start apache2",
      
      # Vérification du statut
      "systemctl status apache2 --no-pager"
    ]
  }
}

# Sortie de l'adresse IP du container
output "container_ip" {
  value       = proxmox_lxc.debian_apache_container.network[0].ip
  description = "Adresse IP du container Debian Apache2"
}

output "apache_url" {
  value       = "http://${proxmox_lxc.debian_apache_container.network[0].ip}"
  description = "URL pour accéder à Apache2"
}