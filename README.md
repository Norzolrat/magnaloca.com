# Infrastructure as Code avec Terraform et Proxmox

Ce projet a pour objectif de développer une infrastructure entièrement automatisée avec Terraform sur Proxmox. Il s'agit d'un projet d'apprentissage et de montée en compétences dans le domaine de l'Infrastructure as Code (IaC).

## Objectifs du projet

- **Automatisation complète** : Déploiement d'infrastructure sans intervention manuelle
- **Images personnalisées** : Utilisation d'images LXC et VM cloud-init custom
- **Évolutivité** : Architecture modulaire permettant l'ajout de nouveaux services
- **Bonnes pratiques** : Respect des standards de sécurité et de documentation

## Architecture actuelle

Le projet se compose actuellement de deux modules principaux :

### 1. Déploiement d'images LXC (`deploy_lxc_image/`)

Module responsable de l'importation automatique d'images LXC personnalisées depuis GitHub vers Proxmox.

**Fonctionnalités :**
- Téléchargement automatique depuis GitHub Releases
- Upload vers le storage Proxmox via API
- Nettoyage des fichiers temporaires
- Gestion des erreurs et retry

### 2. Container Debian Apache (`debian_helloworld/`)

Déploiement d'un container LXC Debian avec service Apache affichant "Hello World!".

**Fonctionnalités :**
- Container LXC basé sur image Debian personnalisée
- Installation et configuration automatique d'Apache2
- Configuration réseau statique ou DHCP
- Accès SSH par clé publique
- Page web personnalisée

## Prérequis

### Infrastructure
- Serveur Proxmox VE fonctionnel
- Bridge réseau configuré (ex: vmbr1)
- Stockage disponible pour templates et containers

### Outils
- Terraform >= 1.0
- Accès SSH au serveur Proxmox
- Clés SSH configurées

### Permissions Proxmox
L'utilisateur Terraform doit disposer des permissions suivantes :
- `VM.Allocate` sur le nœud
- `VM.Clone`, `VM.Config.*` sur les ressources
- `Datastore.AllocateSpace` sur les storages
- `SDN.Use` sur les bridges réseau

## Configuration

### 1. Cloner le repository
```bash
git clone https://github.com/Norzolrat/magnaloca.com
cd magnaloca.com
```

### 2. Configurer les variables

Pour chaque module, copier le fichier d'exemple et l'adapter :

```bash
# Module déploiement d'images
cd deploy_lxc_image
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec vos valeurs

# Module container Apache
cd ../debian_helloworld
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec vos valeurs
```

### 3. Créer un token API Proxmox

1. Interface Proxmox : **Datacenter > Permissions > API Tokens**
2. Créer un token pour l'utilisateur `terraform@pve`
3. Noter le Token ID et Secret pour la configuration

### 4. Configurer SSH

```bash
# Générer une paire de clés dédiée
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_terraform

# Récupérer la clé publique
cat ~/.ssh/id_ed25519_terraform.pub
```

## Utilisation

### Déploiement d'une image LXC

```bash
cd deploy_lxc_image
terraform init
terraform plan
terraform apply
```

### Déploiement du container Apache

```bash
cd debian_helloworld
terraform init
terraform plan
terraform apply
```

### Accès aux services

Une fois déployé, le container Apache est accessible :
- **Web** : `http://<container-ip>/`
- **SSH** : `ssh -i ~/.ssh/id_ed25519_terraform root@<container-ip>`
- **Console Proxmox** : Interface web ou `pct enter <container-id>`

## Structure du projet

```
magnaloca.com/
├── README.md
├── deploy_lxc_image/          # Module d'importation d'images
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars.example
│   └── .gitignore
├── debian_helloworld/         # Module container Apache
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── .gitignore
└── images/                    # Images personnalisées (GitHub Releases)
```

## Roadmap

### Phase 1 : Fondations (En cours)
- [x] Module d'importation d'images LXC
- [x] Container Debian Apache basique
- [x] Documentation et exemples

### Phase 2 : Services de base
- [x] Container de base de données (PostgreSQL)
- [x] Container reverse proxy (Traefik)
- [ ] Gestion des volumes persistants

### Phase 3 : VM et Cloud-init
- [x] Images VM personnalisées avec Cloud-init
- [ ] Déploiement de VMs Ubuntu/Debian
- [ ] Configuration automatique via Cloud-init

### Phase 4 : Orchestration
- [ ] Load balancer automatique
- [ ] Monitoring et métriques
- [ ] Sauvegarde automatisée
- [ ] CI/CD pour l'infrastructure

### Phase 5 : Sécurité et production
- [ ] Chiffrement des secrets
- [ ] Segmentation réseau avancée
- [ ] Audit et logging centralisé
- [ ] Disaster recovery

## Sécurité

### Bonnes pratiques implémentées
- Authentification par token API au lieu de mot de passe
- Clés SSH dédiées pour l'accès aux containers
- Fichiers de configuration sensibles exclus du versioning
- Variables sensibles marquées dans Terraform

### Fichiers sensibles
Les fichiers suivants ne doivent **jamais** être committé :
- `terraform.tfvars` (contient tokens et secrets)
- `*.tfstate` (état de l'infrastructure)
- Clés privées SSH

## Support

Pour toute question ou problème :
- Ouvrir une issue sur GitHub
- Vérifier la documentation Terraform Proxmox Provider
- Consulter les logs Terraform (`terraform.log`)

## Licence

Ce projet est sous aucune licence pour le moment.

---

**Note** : Ce projet est à des fins d'apprentissage et de développement de compétences. Il n'est pas recommandé pour un usage en production sans adaptations supplémentaires.