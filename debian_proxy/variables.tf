# Configuration Proxmox
variable "proxmox_api_url" {
  description = "URL de l'API Proxmox"
  type        = string
  default     = "https://172.16.1.1:8006/api2/json"
}

variable "proxmox_user" {
  description = "Utilisateur Proxmox"
  type        = string
  default     = "terraform@pve"
}

variable "proxmox_password" {
  description = "Mot de passe Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_token_name" {
  description = "Name API Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_token" {
  description = "Jeton API Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Ignorer les certificats TLS invalides"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Nom du nœud Proxmox"
  type        = string
  default     = "pve"
}

variable "proxmox_template_storage" {
  description = "Storage pour uploader les templates (type Directory)"
  type        = string
  default     = "local"
}

variable "proxmox_storage" {
  description = "Storage Proxmox pour les templates et disques"
  type        = string
  default     = "local"
}

variable "proxmox_host" {
  description = "Adresse IP/hostname du serveur Proxmox"
  type        = string
  default     = "192.168.1.100"
}

# Configuration du container
variable "container_hostname" {
  description = "Nom d'hôte du container LXC"
  type        = string
  default     = "lxc"
}

variable "container_id" {
  description = "ID du container"
  type        = number
  default     = null
}

variable "container_memory" {
  description = "Mémoire allouée au container (MB)"
  type        = number
  default     = 1024
}

variable "container_cores" {
  description = "Nombre de cœurs CPU"
  type        = number
  default     = 2
}

variable "container_swap" {
  description = "Swap alloué au container (MB)"
  type        = number
  default     = 512
}

variable "container_disk_size" {
  description = "Taille du disque racine"
  type        = string
  default     = "8G"
}

# Configuration réseau
variable "network_bridge" {
  description = "Bridge réseau Proxmox"
  type        = string
  default     = "vmbr1"
}

variable "container_ip" {
  description = "Adresse IP du container (CIDR)"
  type        = string
  default     = "dhcp"
  # Exemple statique : "192.168.1.200/24"
}

variable "container_gateway" {
  description = "Passerelle réseau"
  type        = string
  default     = "192.168.1.1"
}

variable "container_ip_address" {
  description = "Adresse IP du container pour SSH (sans CIDR)"
  type        = string
  default     = "192.168.1.200"
}

# Sécurité
variable "enable_firewall" {
  description = "Activer le firewall UFW sur le container"
  type        = bool
  default     = false
}

variable "allowed_networks" {
  description = "Réseaux autorisés à accéder au dashboard (CIDR)"
  type        = list(string)
  default     = ["192.168.1.0/24"]
}

# Configuration SSH
variable "ssh_public_keys" {
  description = "Clés SSH publiques pour l'accès au container"
  type        = string
  default     = ""
}

variable "ssh_private_key_path" {
  description = "Chemin vers la clé privée SSH"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# Configuration avancé
variable "enable_console_autologin" {
  description = "Activer l'autologin root sur la console"
  type        = bool
  default     = true
}

variable "container_tags" {
  description = "Tags à appliquer au container"
  type        = string
  default     = "terraform,traefik,proxy"
}

# Configuration volumes persistants
variable "traefik_config_size" {
  description = "Taille du volume pour la configuration Traefik"
  type        = string
  default     = "1G"
}

variable "traefik_logs_size" {
  description = "Taille du volume pour les logs Traefik"
  type        = string
  default     = "2G"
}

variable "traefik_certs_size" {
  description = "Taille du volume pour les certificats SSL"
  type        = string
  default     = "1G"
}

variable "traefik_data_size" {
  description = "Taille du volume pour les données Traefik"
  type        = string
  default     = "1G"
}

# Sauvegarde
variable "enable_backup" {
  description = "Activer les sauvegardes automatiques"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Planning cron pour les sauvegardes (ex: '0 3 * * *' pour 3h du matin)"
  type        = string
  default     = "0 3 * * *"
}

variable "backup_retention_days" {
  description = "Nombre de jours de rétention des sauvegardes"
  type        = number
  default     = 7
}

# Configuration Traefik
variable "traefik_version" {
  description = "Version de Traefik à installer"
  type        = string
  default     = "v3.0"
  
  validation {
    condition = can(regex("^v[0-9]+\\.[0-9]+", var.traefik_version))
    error_message = "La version Traefik doit commencer par 'v' suivi d'un numéro (ex: v3.0, v2.10)."
  }
}

variable "traefik_log_level" {
  description = "Niveau de log Traefik"
  type        = string
  default     = "INFO"
  
  validation {
    condition = contains(["DEBUG", "INFO", "WARN", "ERROR", "FATAL", "PANIC"], var.traefik_log_level)
    error_message = "Le niveau de log doit être: DEBUG, INFO, WARN, ERROR, FATAL, ou PANIC."
  }
}
# Dashboard Traefik
variable "enable_dashboard" {
  description = "Activer le dashboard Traefik"
  type        = bool
  default     = true
}

variable "dashboard_port" {
  description = "Port pour le dashboard Traefik"
  type        = number
  default     = 8080
}

variable "dashboard_auth_user" {
  description = "Utilisateur pour l'authentification du dashboard"
  type        = string
  default     = "admin"
}

variable "dashboard_auth_password" {
  description = "Mot de passe pour l'authentification du dashboard"
  type        = string
  sensitive   = true
  default     = "traefik_admin_123!"
}

# Let's Encrypt SSL
variable "enable_lets_encrypt" {
  description = "Activer Let's Encrypt pour les certificats automatiques"
  type        = bool
  default     = false
}

variable "lets_encrypt_email" {
  description = "Email pour Let's Encrypt (obligatoire si Let's Encrypt activé)"
  type        = string
  default     = ""
  
  validation {
    condition = var.enable_lets_encrypt == false || (var.enable_lets_encrypt == true && can(regex("^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$", var.lets_encrypt_email)))
    error_message = "Un email valide est requis si Let's Encrypt est activé."
  }
}

variable "lets_encrypt_staging" {
  description = "Utiliser l'environnement de staging Let's Encrypt (pour les tests)"
  type        = bool
  default     = true
}
# UPSTREAM & ENTRYPOINT
variable "upstream_services" {
  description = "Liste des services à proxifier"
  type = list(object({
    name         = string
    host         = string
    path_prefix  = string
    backend_url  = string
    enable_https = bool
    strip_prefix = bool
    middlewares  = list(string)
  }))
  default = [
    {
      name         = "traefik-dashboard"
      host         = "traefik.local"
      path_prefix  = "/"
      backend_url  = "http://127.0.0.1:8080"
      enable_https = false
      strip_prefix = false
      middlewares  = ["dashboard-auth"]
    }
  ]
}

variable "http_port" {
  description = "Port HTTP pour Traefik"
  type        = number
  default     = 80
}

variable "https_port" {
  description = "Port HTTPS pour Traefik"
  type        = number
  default     = 443
}

variable "redirect_http_to_https" {
  description = "Rediriger automatiquement HTTP vers HTTPS"
  type        = bool
  default     = false
}