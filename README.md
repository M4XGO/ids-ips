# Infrastructure de Sécurité AWS IDS/IPS

## Description
Solution de sécurité réseau utilisant Suricata comme IDS/IPS sur AWS, avec surveillance et alertes en temps réel.
### Contenu : 
- Une fonction Lambda pour la détection d'alertes Suricata
- Un VPC avec une architecture réseau complète
- Deux instances EC2 :
    - Une machine Suricata agissant comme proxy/IDS
    - Une machine Web protégée derrière Suricata
- Un système de logging avec CloudWatch

## Architecture

```
                   Internet
                      │
                      ▼
               ┌──────────────┐
               │  Suricata VM │ 
               │   (Public)   │
               └──────┬───────┘
                      │
                      ▼
               ┌──────────────┐
               │    Web VM    │
               │   (Private)  │
               └──────────────┘
```

## Structure du Projet
```
.cloud/terraform/
├── main.tf           # Configuration principale
├── variables.tf      # Définition des variables
├── outputs.tf        # Sorties
├── providers.tf      # Configuration du provider AWS
├── network.tf        # Configuration réseau (VPC, subnet...)  
├── ec2.tf           # Configuration des instances EC2
├── iam.tf           # Rôles et politiques IAM
├── cloudwatch.tf    # Configuration CloudWatch
├── modules/         # Modules personnalisés
│   └── lambda/      # Module Lambda
```


### Composants Principaux
Réseau (`network.tf`)
- VPC avec CIDR 10.0.0.0/16
- Subnet public
- Internet Gateway
- Table de routage

### Instances EC2 (`ec2.tf`)
1. Suricata VM:
    - Instance t2.micro avec Amazon Linux 2
    - IP publique
    - Configuration Suricata et Nginx
    - Forwarding du trafic vers Web VM

2. Web VM:
    - Instance t2.micro avec Apache
    - IP privée uniquement
    - Accessible uniquement via Suricata

### Lambda (`modules/lambda/`)
   - Fonction de traitement des logs Suricata
   - Intégration avec CloudWatch Logs
   - Notification Discord des alertes

### Surveillance (`cloudwatch.tf`)
    - Groupe de logs pour Suricata
    - Flux de logs
    - Filtres de métriques


## Variables Importantes
```hcl
variable "function_name" {...}
variable "discord_webhook_url" {...}
variable "source_code_path" {...}
variable "shared_credential_file"  {...}
```


## Sécurité
- Suricata VM agit comme proxy/IDS
- Politique de sécurité restrictive sur Web VM
- Logging complet des événements
- Notifications des alertes via Discord