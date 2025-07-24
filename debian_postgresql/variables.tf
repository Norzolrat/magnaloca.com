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
  default     = "apache-lxc"
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
  default     = "terraform,postgresql,database"
}

# Configuration PostgreSQL

variable "postgres_version" {
  description = "Version de PostgreSQL à installer"
  type        = string
  default     = "15"
  validation {
    condition = contains([
      "13", "14", "15", "16"
    ], var.postgres_version)
    error_message = "Version PostgreSQL supportée: 13, 14, 15, 16"
  }
}

variable "postgres_root_password" {
  description = "Mot de passe pour l'utilisateur postgres"
  type        = string
  # sensitive   = true
  default     = "postgres_secure_password"
}

variable "postgres_database_name" {
  description = "Nom de la base de données à créer"
  type        = string
  default     = "app_database"
}

variable "postgres_app_user" {
  description = "Nom de l'utilisateur applicatif PostgreSQL"
  type        = string
  default     = "app_user"
}

variable "postgres_app_password" {
  description = "Mot de passe de l'utilisateur applicatif"
  type        = string
  # sensitive   = true
  default     = "app_secure_password"
}

variable "postgres_port" {
  description = "Port d'écoute PostgreSQL"
  type        = number
  default     = 5432
}

variable "postgres_max_connections" {
  description = "Nombre maximum de connexions PostgreSQL"
  type        = number
  default     = 100
}

variable "postgres_shared_buffers" {
  description = "Taille des shared_buffers PostgreSQL (ex: 512MB)"
  type        = string
  default     = "512MB"
}

## volumes

variable "postgres_data_size" {
  description = "Taille du volume pour les données PostgreSQL"
  type        = string
  default     = "20G"
}

variable "postgres_logs_size" {
  description = "Taille du volume pour les logs PostgreSQL"
  type        = string
  default     = "2G"
}

variable "enable_backup_volume" {
  description = "Créer un volume dédié pour les sauvegardes"
  type        = bool
  default     = true
}

variable "postgres_backup_size" {
  description = "Taille du volume pour les sauvegardes PostgreSQL"
  type        = string
  default     = "10G"
}

## sauvegarde

variable "enable_auto_backup" {
  description = "Activer la sauvegarde automatique"
  type        = bool
  default     = false
}

variable "backup_schedule" {
  description = "Planning cron pour les sauvegardes (ex: '0 2 * * *' pour 2h du matin)"
  type        = string
  default     = "0 2 * * *"
}

variable "backup_retention_days" {
  description = "Nombre de jours de rétention des sauvegardes"
  type        = number
  default     = 7
}

## secu

variable "enable_firewall" {
  description = "Activer le firewall sur le container"
  type        = bool
  default     = true
}

variable "allowed_networks" {
  description = "Réseaux autorisés à se connecter à PostgreSQL (CIDR)"
  type        = list(string)
  default     = ["192.168.1.0/24"]
}

variable "postgres_listen_addresses" {
  description = "Adresses d'écoute PostgreSQL (* pour toutes)"
  type        = string
  default     = "*"
}