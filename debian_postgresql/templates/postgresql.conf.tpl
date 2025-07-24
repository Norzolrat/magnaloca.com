# Configuration PostgreSQL optimisée

data_directory = '/var/lib/postgresql/${postgres_version}/main'
hba_file = '/etc/postgresql/${postgres_version}/main/pg_hba.conf'
ident_file = '/etc/postgresql/${postgres_version}/main/pg_ident.conf'
external_pid_file = '/var/run/postgresql/${postgres_version}-main.pid'

# Connexions
listen_addresses = '${postgres_listen_addresses}'
port = ${postgres_port}
max_connections = ${postgres_max_connections}

# Mémoire
shared_buffers = ${postgres_shared_buffers}
effective_cache_size = 1GB
maintenance_work_mem = 256MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100

# Logs
log_destination = 'stderr'
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_truncate_on_rotation = off
log_rotation_age = 1d
log_rotation_size = 100MB
log_line_prefix = '%t [%p-%l] %q%u@%d '
log_timezone = 'UTC'

# Locale
datestyle = 'iso, mdy'
timezone = 'UTC'
# lc_messages = 'en_US.UTF-8'
# lc_monetary = 'en_US.UTF-8'  
# lc_numeric = 'en_US.UTF-8'
# lc_time = 'en_US.UTF-8'
lc_messages = 'C.UTF-8'
lc_monetary = 'C.UTF-8'
lc_numeric = 'C.UTF-8'
lc_time = 'C.UTF-8'
default_text_search_config = 'pg_catalog.english'