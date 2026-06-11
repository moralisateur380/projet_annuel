#!/bin/bash

# ==============================================================================
# SCRIPT D'AUTOMATISATION POUR SRV-WAZUH-1 (SOC Wazuh)
# Mis à jour avec les IP réelles du projet NexaMind
# À exécuter en tant que ROOT sur la Debian Wazuh
# ==============================================================================

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}==== [1/5] Configuration initiale de l'identité (Clavier, Hostname, ID) ] ====${NC}"
# Passage du clavier en français
loadkeys fr

# Régénération de l'identité unique du clone
systemd-machine-id-setup
dpkg-reconfigure openssh-server

# Configuration du nom de domaine local
hostnamectl set-hostname srv-wazuh-1

echo -e "${BLUE}==== [2/5] Préparation du système et dépendances ] ====${NC}"
apt update && apt upgrade -y
apt install -y curl python3 python3-pip python3-requests

echo -e "${BLUE}==== [3/5] Lancement de l'installation automatique de Wazuh (4.9) ] ====${NC}"
echo -e "${BLUE}⚠️  Cette étape prend 15 à 20 minutes. Ne coupe pas le terminal !${NC}"
cd /root
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh

# Lancement du script officiel d'installation complète
bash ./wazuh-install.sh -a

echo -e "${BLUE}==== [4/5] Configuration de l'intégration vers le Portail NexaMind ] ====${NC}"
# Création du script Python lié à l'IP réelle du serveur Web (192.168.20.20)
cat << 'EOF' > /var/ossec/integrations/custom-nexamind.py
#!/usr/bin/env python3
import sys
import json
import requests

alert_file = sys.argv[1]
with open(alert_file) as f:
    alert = json.load(f)

level = alert.get("rule", {}).get("level", 0)

if level >= 10:
    niveau = "critique"
elif level >= 7:
    niveau = "moyen"
else:
    niveau = "faible"

payload = {
    "niveau": niveau,
    "source": alert.get("data", {}).get("srcip", "inconnu"),
    "description": alert.get("rule", {}).get("description", "Alerte détectée par le SOC"),
}

# Envoi automatique ciblé vers ton srv-web-1
try:
    requests.post("http://192.168.20.20/api/alerte", json=payload, timeout=5)
except Exception as e:
    pass
EOF

# Droits de sécurité stricts pour l'intégration
chmod +x /var/ossec/integrations/custom-nexamind.py
chmod 750 /var/ossec/integrations/custom-nexamind.py
chown root:wazuh /var/ossec/integrations/custom-nexamind.py

echo -e "${BLUE}==== [5/5] Activation de l'intégration dans ossec.conf ] ====${NC}"
cat << 'EOF' > /tmp/integration_block.xml
  <integration>
    <name>custom-nexamind.py</name>
    <level>7</level>
    <alert_format>json</alert_format>
  </integration>
</ossec_config>
EOF

# Injection du bloc XML dans le fichier principal
sed -i 's/<\/ossec_config>/ /' /var/ossec/etc/ossec.conf
cat /tmp/integration_block.xml >> /var/ossec/etc/ossec.conf
rm -f /tmp/integration_block.xml

# Redémarrage du manager pour appliquer les modifications
systemctl restart wazuh-manager

echo -e "${GREEN}========================================================================${NC}"
echo -e "${GREEN}✅ Script terminé ! Connecte-toi sur : https://192.168.20.21${NC}"
echo -e "${GREEN}   Note bien le MOT DE PASSE admin généré juste au-dessus !${NC}"
echo -e "${GREEN}========================================================================${NC}"