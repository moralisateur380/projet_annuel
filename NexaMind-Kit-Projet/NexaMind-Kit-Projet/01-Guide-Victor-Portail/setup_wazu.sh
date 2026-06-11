#!/bin/bash

# ==============================================================================
# SCRIPT D'AUTOMATISATION POUR SRV-WAZUH-1 (SOC Wazuh)
# Version auto-correctrice pour les dépôts Debian
# À exécuter en tant que ROOT sur la Debian Wazuh
# ==============================================================================

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}==== [1/6] Réparation des dépôts internet (sources.list) ] ====${NC}"
# Configuration forcée des dépôts officiels Debian Bookworm
cat << 'EOF' > /etc/apt/sources.list
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
EOF

echo -e "${BLUE}==== [2/6] Configuration initiale de l'identité (Clavier, Hostname, ID) ] ====${NC}"
loadkeys fr
systemd-machine-id-setup
dpkg-reconfigure openssh-server
hostnamectl set-hostname srv-wazuh-1

echo -e "${BLUE}==== [3/6] Préparation du système et dépendances nécessaires ] ====${NC}"
apt update --fix-missing
apt install -y software-properties-common gnupg apt-transport-https curl python3 python3-pip python3-requests git

echo -e "${BLUE}==== [4/6] Lancement de l'installation automatique de Wazuh (4.9) ] ====${NC}"
echo -e "${BLUE}⚠️  Cette étape prend 15 à 20 minutes. Ne coupe pas le terminal !${NC}"
cd /root
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
bash ./wazuh-install.sh -a

echo -e "${BLUE}==== [5/6] Configuration de l'intégration vers le Portail NexaMind ] ====${NC}"
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

try:
    requests.post("http://192.168.20.20/api/alerte", json=payload, timeout=5)
except Exception as e:
    pass
EOF

chmod +x /var/ossec/integrations/custom-nexamind.py
chmod 750 /var/ossec/integrations/custom-nexamind.py
chown root:wazuh /var/ossec/integrations/custom-nexamind.py

echo -e "${BLUE}==== [6/6] Activation de l'intégration dans ossec.conf ] ====${NC}"
cat << 'EOF' > /tmp/integration_block.xml
  <integration>
    <name>custom-nexamind.py</name>
    <level>7</level>
    <alert_format>json</alert_format>
  </integration>
</ossec_config>
EOF

sed -i 's/<\/ossec_config>/ /' /var/ossec/etc/ossec.conf
cat /tmp/integration_block.xml >> /var/ossec/etc/ossec.conf
rm -f /tmp/integration_block.xml

systemctl restart wazuh-manager

echo -e "${GREEN}========================================================================${NC}"
echo -e "${GREEN}✅ Script terminé ! Connecte-toi sur : https://192.168.20.21${NC}"
echo -e "${GREEN}   Note bien le MOT DE PASSE admin généré juste au-dessus !${NC}"
echo -e "${GREEN}========================================================================${NC}"