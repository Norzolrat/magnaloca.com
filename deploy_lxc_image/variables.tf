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

# Configuration de l'image GitHub
variable "github_image_url" {
  description = "URL de téléchargement de l'image LXC depuis GitHub"
  type        = string
  # Exemple : https://github.com/username/repo/releases/download/v1.0/image.tar.gz
}

variable "image_name" {
  description = "nom de l'image LXC"
  type        = string
}