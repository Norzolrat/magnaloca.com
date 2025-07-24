#!/bin/bash
set -e
cd /tmp

# ====== Préparation système ======
echo "[INFO] Mise à jour du système..."
sleep 10
apt-get update && apt-get upgrade -y
apt-get install -y wget ca-certificates gnupg lsb-release curl sudo jq

# ====== Chargement des variables depuis le fichier Terraform généré ======
source "/tmp/postgres.env"

# Conversion JSON -> tableau bash (requiert jq)
ALLOWED_NETWORKS=($(echo "$ALLOWED_NETWORKS" | jq -r '.[]'))

# ====== Dépôt PostgreSQL officiel ======
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
apt-get update

# ====== Installation PostgreSQL ======
apt-get install -y "postgresql-$POSTGRES_VERSION" \
                   "postgresql-client-$POSTGRES_VERSION" \
                   "postgresql-contrib-$POSTGRES_VERSION"

# Préparation des volumes
systemctl stop postgresql
find /var/lib/postgresql -name "lost+found" -prune -o -type f -exec chown postgres:postgres {} \;
find /var/lib/postgresql -name "lost+found" -prune -o -type d -exec chown postgres:postgres {} \;
find /var/log/postgresql -name "lost+found" -prune -o -type f -exec chown postgres:postgres {} \;
find /var/log/postgresql -name "lost+found" -prune -o -type d -exec chown postgres:postgres {} \;
chmod 700 /var/lib/postgresql

if [ "$ENABLE_BACKUP_VOLUME" = true ]; then
  mkdir -p /var/backups/postgresql
  find /var/backups/postgresql -name "lost+found" -prune -o -type f -exec chown postgres:postgres {} \;
  find /var/backups/postgresql -name "lost+found" -prune -o -type d -exec chown postgres:postgres {} \;
fi

# ====== Initialisation si nécessaire ======
if [ ! -d "/var/lib/postgresql/$POSTGRES_VERSION/main" ]; then
  sudo -u postgres /usr/lib/postgresql/$POSTGRES_VERSION/bin/initdb -D "/var/lib/postgresql/$POSTGRES_VERSION/main"
fi

# ====== Configuration PostgreSQL ======
cp "/tmp/templates/postgresql.conf" "/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"
# sed -i "s|__LISTEN_ADDRESSES__|$POSTGRES_LISTEN_ADDRESSES|" "/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"
# sed -i "s|__PORT__|$POSTGRES_PORT|" "/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"
# sed -i "s|__MAX_CONNECTIONS__|$POSTGRES_MAX_CONNECTIONS|" "/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"
# sed -i "s|__SHARED_BUFFERS__|$POSTGRES_SHARED_BUFFERS|" "/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"

# ====== pg_hba.conf ======
cat > "/etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf" <<EOF
local   all             postgres                                peer
local   all             all                                     peer
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
EOF
for net in "${ALLOWED_NETWORKS[@]}"; do
  echo "host    all             all             ${net}                 scram-sha-256" >> "/etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf"
done

# ====== Démarrage PostgreSQL ======
systemctl enable postgresql
systemctl start postgresql
sleep 10

# ====== Création utilisateurs et base de données ======

# sudo -u postgres psql -c "ALTER USER root PASSWORD '$POSTGRES_ROOT_PASSWORD';"

database_exists() {
    sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$1"
}

if database_exists "$POSTGRES_DATABASE_NAME"; then
    echo "[INFO] ✅ Base $POSTGRES_DATABASE_NAME existe"
else
    sudo -u postgres createdb "$POSTGRES_DATABASE_NAME"
fi

user_exists() {
    sudo -u postgres psql -t -c "SELECT 1 FROM pg_roles WHERE rolname='$1'" | grep -q 1
}

if user_exists "$POSTGRES_APP_USER"; then
    echo "[INFO] ✅ Utilisateur $POSTGRES_APP_USER existe"
    sudo -u postgres psql -c "ALTER USER $POSTGRES_APP_USER WITH ENCRYPTED PASSWORD '$POSTGRES_APP_PASSWORD';"
else
    sudo -u postgres psql -c "CREATE USER $POSTGRES_APP_USER WITH ENCRYPTED PASSWORD '$POSTGRES_APP_PASSWORD';"
fi

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DATABASE_NAME TO $POSTGRES_APP_USER;"
sudo -u postgres psql -c "ALTER USER $POSTGRES_APP_USER CREATEDB;"

# ====== Script de sauvegarde ======
if [ "$ENABLE_AUTO_BACKUP" = true ]; then
  mkdir -p /opt/scripts
  cp "/tmp/templates/postgres_backup.sh" /opt/scripts/postgres_backup.sh
  chmod +x /opt/scripts/postgres_backup.sh
  echo "$BACKUP_SCHEDULE root /opt/scripts/postgres_backup.sh >> /var/log/postgresql/backup.log 2>&1" > /etc/cron.d/postgres-backup
fi

# ====== Firewall ======
if [ "$ENABLE_FIREWALL" = true ]; then
  apt-get install -y ufw
  ufw --force enable
  ufw allow ssh
  ufw allow "$POSTGRES_PORT"
fi

# ====== Vérifications ====== <!> bloque le terminal <!>
# systemctl status postgresql@$POSTGRES_VERSION-main --no-pager --lines=5
# sudo -u postgres psql -c 'SELECT version();'
# sudo -u postgres psql -c '\l'

# ====== Résumé ======
echo '=========================='
echo "🐘 PostgreSQL $POSTGRES_VERSION installé avec succès!"
echo "Container: $CONTAINER_HOSTNAME"
echo "IP: $CONTAINER_IP_ADDRESS"
echo "Port: $POSTGRES_PORT"
echo "Base de données: $POSTGRES_DATABASE_NAME"
echo "Utilisateur app: $POSTGRES_APP_USER"
echo "Volumes persistants configurés ✓"
if [ "$ENABLE_AUTO_BACKUP" = true ]; then
  echo "Sauvegarde automatique: $BACKUP_SCHEDULE ✓"
else
  echo "Sauvegarde automatique: désactivée"
fi
