#!/bin/bash
set -e
cd /tmp

# ====== Préparation système ======
echo "[INFO] Mise à jour du système..."
sleep 10
apt-get update && apt-get upgrade -y
apt-get install -y wget ca-certificates curl jq sudo systemd openssl

# ====== Chargement des variables depuis le fichier Terraform généré ======
source "/tmp/traefik.env"

# Conversion JSON -> tableau bash (requiert jq)
UPSTREAM_SERVICES_JSON="$UPSTREAM_SERVICES"
ALLOWED_NETWORKS=($(echo "$ALLOWED_NETWORKS" | jq -r '.[]'))

# Début script
echo "Déploiement de Traefik $TRAEFIK_VERSION sur $CONTAINER_HOSTNAME..."
echo "Dashboard activé: $ENABLE_DASHBOARD"
echo "Let's Encrypt: $ENABLE_LETS_ENCRYPT"

# ====== Création utilisateur traefik ======
echo "[INFO] Création de l'utilisateur traefik..."
if ! id "traefik" &>/dev/null; then
    useradd --system --shell /bin/false --home-dir /var/lib/traefik traefik
    echo "Utilisateur traefik créé"
else
    echo "Utilisateur traefik existe déjà"
fi

# ====== Préparation des volumes persistants ======
echo "[INFO] Configuration des volumes persistants..."

# Nettoyage des lost+found dans les volumes
find /etc/traefik -name "lost+found" -exec rm -rf {} + 2>/dev/null || true
find /var/lib/traefik -name "lost+found" -exec rm -rf {} + 2>/dev/null || true
find /var/log/traefik -name "lost+found" -exec rm -rf {} + 2>/dev/null || true
find /etc/ssl/traefik -name "lost+found" -exec rm -rf {} + 2>/dev/null || true

# Création des sous-répertoires nécessaires
mkdir -p /etc/traefik/dynamic
mkdir -p /etc/ssl/traefik/certs
mkdir -p /var/lib/traefik
mkdir -p /var/log/traefik

# Permissions
chown -R traefik:traefik /etc/traefik
chown -R traefik:traefik /var/lib/traefik
chown -R traefik:traefik /var/log/traefik
chown -R traefik:traefik /etc/ssl/traefik
chmod 755 /etc/traefik
chmod 755 /etc/traefik/dynamic
chmod 700 /etc/ssl/traefik/certs
chmod 755 /var/lib/traefik
chmod 755 /var/log/traefik

echo "Volumes configurés ✓"

# ====== Téléchargement et installation de Traefik ======
echo "[INFO] Téléchargement de Traefik $TRAEFIK_VERSION..."

# Détection de l'architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        TRAEFIK_ARCH="amd64"
        ;;
    aarch64|arm64)
        TRAEFIK_ARCH="arm64"
        ;;
    armv7l)
        TRAEFIK_ARCH="armv7"
        ;;
    *)
        echo "Architecture non supportée: $ARCH"
        exit 1
        ;;
esac

# URL de téléchargement
TRAEFIK_URL="https://github.com/traefik/traefik/releases/download/${TRAEFIK_VERSION}/traefik_${TRAEFIK_VERSION}_linux_${TRAEFIK_ARCH}.tar.gz"

echo "Téléchargement depuis: $TRAEFIK_URL"

# Téléchargement
wget -O traefik.tar.gz "$TRAEFIK_URL"
tar -xzf traefik.tar.gz
chmod +x traefik
mv traefik /usr/local/bin/

# Vérification
/usr/local/bin/traefik version

# Ajout droits réseaux
setcap 'cap_net_bind_service=+ep' /usr/local/bin/traefik

echo "Traefik installé ✓"

# ====== Configuration Traefik statique ======
echo "[INFO] Configuration de Traefik..."

# Génération du hash du mot de passe pour le dashboard
if [ "$ENABLE_DASHBOARD" = true ]; then
    # Installation d'apache2-utils pour htpasswd
    apt-get install -y apache2-utils
    DASHBOARD_HASH=$(htpasswd -nbB "$DASHBOARD_AUTH_USER" "$DASHBOARD_AUTH_PASSWORD" | cut -d: -f2)
    echo "Hash du mot de passe dashboard généré ✓"
fi

# Configuration statique principale (générée par Terraform)
cp /tmp/templates/traefik.yaml /etc/traefik/traefik.yaml
chown traefik:traefik /etc/traefik/traefik.yaml
chmod 644 /etc/traefik/traefik.yaml

# Configuration dynamique (générée par Terraform) 
cp /tmp/templates/dynamic.yaml /etc/traefik/dynamic/
chown -R traefik:traefik /etc/traefik/dynamic/
chmod 644 /etc/traefik/dynamic/dynamic.yaml

echo "Configurations installées ✓"

# ====== Permissions Let's Encrypt ======
if [ "$ENABLE_LETS_ENCRYPT" = true ]; then
    touch /var/lib/traefik/acme.json
    chmod 600 /var/lib/traefik/acme.json
    chown traefik:traefik /var/lib/traefik/acme.json
    echo "Fichier ACME configuré ✓"
fi

# Installation du service (généré par Terraform)
cp /tmp/templates/traefik.service /etc/systemd/system/
chmod 644 /etc/systemd/system/traefik.service

# Activation du service
systemctl daemon-reload
systemctl enable traefik
echo "Service systemd configuré ✓"

# ====== Configuration du firewall ======
if [ "$ENABLE_FIREWALL" = true ]; then
    echo "[INFO] Configuration du firewall..."
    apt-get install -y ufw
    ufw --force enable
    ufw allow ssh
    ufw allow $HTTP_PORT/tcp
    ufw allow $HTTPS_PORT/tcp
    
    if [ "$ENABLE_DASHBOARD" = true ]; then
        # Permettre l'accès au dashboard seulement depuis les réseaux autorisés
        for network in "${ALLOWED_NETWORKS_ARRAY[@]}"; do
            ufw allow from "$network" to any port "$DASHBOARD_PORT"
        done
    fi
    
    echo "Firewall configuré ✓"
fi

# ====== Scripts de sauvegarde ======
if [ "$ENABLE_BACKUP" = true ]; then
    echo "[INFO] Configuration des sauvegardes..."
    mkdir -p /opt/scripts
    cp /tmp/templates/traefik_backup.sh /opt/scripts/traefik_backup.sh
    chmod +x /opt/scripts/traefik_backup.sh
    
    # Ajout de la variable de rétention dans le script
    sed -i "s/BACKUP_RETENTION_DAYS=7/BACKUP_RETENTION_DAYS=$BACKUP_RETENTION_DAYS/" /opt/scripts/traefik_backup.sh
    
    echo "$BACKUP_SCHEDULE root /opt/scripts/traefik_backup.sh >> /var/log/traefik/backup.log 2>&1" > /etc/cron.d/traefik-backup
    echo "Sauvegarde configurée ✓"
fi

# ====== Rotation des logs ======
cat > /etc/logrotate.d/traefik << 'EOF'
/var/log/traefik/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 traefik traefik
    postrotate
        systemctl reload traefik 2>/dev/null || true
    endscript
}
EOF

# ====== Démarrage de Traefik ======
echo "[INFO] Démarrage de Traefik..."
systemctl start traefik
sleep 10

# ====== Résumé final ======
echo ""
echo "========================================="
echo "🎉 Traefik installé avec succès!"
echo "========================================="
echo "Version: $TRAEFIK_VERSION"
echo "Container: $CONTAINER_HOSTNAME ($CONTAINER_IP_ADDRESS)"
echo "HTTP: http://$CONTAINER_IP_ADDRESS:$HTTP_PORT"
echo "HTTPS: https://$CONTAINER_IP_ADDRESS:$HTTPS_PORT"

if [ "$ENABLE_DASHBOARD" = true ]; then
    echo "Dashboard: http://$CONTAINER_IP_ADDRESS:$DASHBOARD_PORT"
    echo "Authentification: $DASHBOARD_AUTH_USER / ********"
fi

if [ "$ENABLE_LETS_ENCRYPT" = true ]; then
    echo "Let's Encrypt: ✅ Activé ($LETS_ENCRYPT_EMAIL)"
    if [ "$LETS_ENCRYPT_STAGING" = true ]; then
        echo "  Mode: STAGING (test)"
    else
        echo "  Mode: PRODUCTION"
    fi
fi

echo "Logs: /var/log/traefik/"
echo "Config: /etc/traefik/"

if [ "$ENABLE_BACKUP" = true ]; then
    echo "Sauvegarde: $BACKUP_SCHEDULE (rétention: $BACKUP_RETENTION_DAYS jours)"
fi

echo ""
echo "🔧 Commandes utiles:"
echo "systemctl status traefik     # Statut du service"
echo "journalctl -u traefik -f     # Logs en temps réel"
echo "curl http://localhost:$DASHBOARD_PORT/ping    # Test API"

echo ""
echo "✅ Installation terminée!"