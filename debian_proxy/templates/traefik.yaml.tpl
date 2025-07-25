# Configuration statique Traefik
global:
  checkNewVersion: false
  sendAnonymousUsage: false

# Entrypoints
entryPoints:
  web:
    address: ":${http_port}"
%{ if redirect_http_to_https ~}
    http:
      redirections:
        entrypoint:
          to: websecure
          scheme: https
%{ endif ~}
  websecure:
    address: ":${https_port}"


# Providers
providers:
  file:
    directory: /etc/traefik/dynamic
    watch: true

%{ if enable_dashboard ~}
# API et Dashboard
api:
  dashboard: true
  debug: false
  insecure: false
%{ endif ~}

# Logs
log:
  level: ${traefik_log_level}
  filePath: /var/log/traefik/traefik.log
  format: common

accessLog:
  filePath: /var/log/traefik/access.log
  format: common

%{ if enable_lets_encrypt ~}
# Let's Encrypt
certificatesResolvers:
  letsencrypt:
    acme:
      email: ${lets_encrypt_email}
      storage: /var/lib/traefik/acme.json
      caServer: ${lets_encrypt_staging ? "https://acme-staging-v02.api.letsencrypt.org/directory" : "https://acme-v02.api.letsencrypt.org/directory"}
      httpChallenge:
        entryPoint: web
%{ endif ~}
