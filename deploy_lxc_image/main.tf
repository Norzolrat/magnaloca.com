terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

# Configuration du provider Proxmox
provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = var.proxmox_tls_insecure
}

# Téléchargement de l'image LXC depuis GitHub
resource "null_resource" "download_lxc_image" {
  provisioner "local-exec" {
    command = <<-EOT
      # Créer le dossier de destination s'il n'existe pas
      mkdir -p ./images
      
      # Télécharger l'image LXC depuis GitHub
      wget -O ./images/"${var.image_name}" "${var.github_image_url}"
      
      # Optionnel : vérifier l'intégrité si tu as un checksum
      # sha256sum ./images/"${var.image_name}"
    EOT
  }

  triggers = {
    # Relancer si l'URL change
    image_url = var.github_image_url
  }
}

# Upload de l'image vers Proxmox
resource "null_resource" "upload_lxc_template" {
  depends_on = [null_resource.download_lxc_image]

  provisioner "local-exec" {
    command = <<-EOT
      # Upload de l'image vers le storage Proxmox
      # scp ./images/"${var.image_name}" root@${var.proxmox_host}:/var/lib/vz/template/cache/
      
      # Ou utiliser l'API Proxmox pour l'upload
      curl -k -X POST \
        -H "Authorization: PVEAPIToken=${var.proxmox_user}:${var.proxmox_token}" \
        -F "content=vztmpl" \
        -F "filename=@./images/"${var.image_name}"" \
        "${var.proxmox_api_url}/nodes/${var.proxmox_node}/storage/${var.proxmox_template_storage}/upload"
    EOT
  }
}

# Suppression de l'image LXC Local apres Upload
resource "null_resource" "cleanup_lxc_image" {
  depends_on = [null_resource.upload_lxc_template]

  provisioner "local-exec" {
    command = <<-EOT
      # Télécharger l'image LXC depuis GitHub
      rm ./images/"${var.image_name}" && echo "Image supprimée localement"
    EOT
  }
}