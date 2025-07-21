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

# Configuration console
variable "enable_console_autologin" {
  description = "Activer l'autologin root sur la console"
  type        = bool
  default     = true
}