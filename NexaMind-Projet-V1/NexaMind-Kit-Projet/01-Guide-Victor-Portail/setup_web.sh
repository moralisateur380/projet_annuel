#!/bin/bash

# ==============================================================================
# SCRIPT D'AUTOMATISATION POUR SRV-WEB-1 (Nexamind Portal)
# À exécuter en tant que ROOT sur la Debian
# ==============================================================================

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # Pas de couleur

echo -e "${BLUE}==== [1/5] Mise à jour du système et installation des outils ] ====${NC}"
apt update && apt upgrade -y
apt install -y python3 python3-pip python3-venv git nginx

echo -e "${BLUE}==== [2/5] Configuration du dossier projet et de l'environnement Python ] ====${NC}"
# On vérifie si le repo Git est déjà là, sinon on se place au bon endroit
cd /home/projet_annuel/NexaMind-Kit-Projet/NexaMind-Kit-Projet/06-Code-Portail/portail-nexamind

# Création de l'environnement virtuel Python
python3 -m venv venv
source venv/bin/activate

# Installation des dépendances
pip install --upgrade pip
pip install -r requirements.txt
pip install anthropic

echo -e "${BLUE}==== [3/5] Configuration du service permanent Systemd (H24) ] ====${NC}"
# Création du fichier de service pour FastAPI
cat << 'EOF' > /etc/systemd/system/nexamind.service
[Unit]
Description=NexaMind Portal
After=network.target

[Service]
User=root
WorkingDirectory=/home/projet_annuel/NexaMind-Kit-Projet/NexaMind-Kit-Projet/06-Code-Portail/portail-nexamind
ExecStart=/home/projet_annuel/NexaMind-Kit-Projet/NexaMind-Kit-Projet/06-Code-Portail/portail-nexamind/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Rechargement et démarrage du service
systemctl daemon-reload
systemctl enable --now nexamind

echo -e "${BLUE}==== [4/5] Configuration de Nginx (Reverse Proxy & Logs) ] ====${NC}"
# Configuration du bloc serveur Nginx
cat << 'EOF' > /etc/nginx/sites-available/nexamind
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# Activation du site et nettoyage
ln -sf /etc/nginx/sites-available/nexamind /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Redémarrage de Nginx
systemctl restart nginx

echo -e "${BLUE}==== [5/5] Vérification des services ] ====${NC}"
echo "----------------------------------------"
systemctl status nexamind --no-pager | grep "Active:"
systemctl status nginx --no-pager | grep "Active:"
echo "----------------------------------------"

echo -e "${GREEN}✅ Tout est configuré avec succès ! Ton site tourne H24 et est accessible sur le port 80.${NC}"