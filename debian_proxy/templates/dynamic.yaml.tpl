http:
  routers:
%{ for service in upstream_services ~}
    # Service: ${service.name}
    ${service.name}:
      rule: "${service.path_prefix != "/" && service.path_prefix != "" ? "Host(`${service.host}`) && PathPrefix(`${service.path_prefix}`)" : "Host(`${service.host}`)"}"
      service: ${service.name}-service
      entryPoints: ${service.enable_https ? "[\"web\", \"websecure\"]" : "[\"web\"]"}
%{ if length(service.middlewares) > 0 || service.strip_prefix ~}
      middlewares: 
%{ if service.strip_prefix && service.path_prefix != "/" && service.path_prefix != "" ~}        
        - "${service.name}-stripprefix"
%{ endif ~}
%{ for middleware in service.middlewares ~}
        - "${middleware}"
%{ endfor ~}
%{ endif ~}
%{ if service.enable_https && enable_lets_encrypt ~}
      tls:
        certResolver: letsencrypt
%{ endif ~}

%{ endfor ~}

  services:
%{ for service in upstream_services ~}
    # Backend: ${service.name}
    ${service.name}-service:
      loadBalancer:
        servers:
          - url: "${service.backend_url}"

%{ endfor ~}

  middlewares:
%{ if enable_dashboard ~}
    # Authentification Dashboard
    dashboard-auth:
      basicAuth:
        users:
          - "${dashboard_auth_user}:${dashboard_auth_password_hash}"
%{ endif ~}

%{ for service in upstream_services ~}
%{ if service.strip_prefix && service.path_prefix != "/" && service.path_prefix != "" ~}
    # Strip prefix pour ${service.name}
    ${service.name}-stripprefix:
      stripPrefix:
        prefixes:
          - "${service.path_prefix}"

%{ endif ~}
%{ endfor ~}