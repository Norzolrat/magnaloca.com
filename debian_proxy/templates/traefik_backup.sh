#!/bin/bash

BACKUP_DIR="/var/backups/traefik"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS}
DATE=$(date +%Y%m%d_%H%M%S)

echo "[$(date)] Début de la sauvegarde Traefik" 

# Création du répertoire de sauvegarde
mkdir -p "$BACKUP_DIR"

# Sauvegarde de la configuration
tar -czf "$BACKUP_DIR/traefik_config_${DATE}.tar.gz" \
    -C / \
    etc/traefik \
    var/lib/traefik

# Sauvegarde des logs récents (7 derniers jours)
find /var/log/traefik -name "*.log" -mtime -7 -exec tar -czf "$BACKUP_DIR/traefik_logs_${DATE}.tar.gz" {} +

# Nettoyage des anciennes sauvegardes
find "$BACKUP_DIR" -name "traefik_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "[$(date)] Sauvegarde Traefik terminée"