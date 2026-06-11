#!/bin/bash

# ==============================================================================
# SCRIPT DE FORCE BRUTE POUR SRV-WAZUH-1 (SOC Wazuh)
# Résolution agressive des conflits Python 3.13 / Debian Bookworm
# À exécuter en tant que ROOT sur la Debian Wazuh
# ==============================================================================

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}==== [1/6] Nettoyage et forçage des versions Python standards ] ====${NC}"
# Passage du clavier en français pour la console
loadkeys fr

# Réécriture propre des sources Debian
cat << 'EOF' > /etc/apt/sources.list
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
EOF

# Nettoyage agressif des paquets qui bloquent la version 3.12 standard
apt-get remove -y python3-dbus python3-gi libglib2.0-0t64 libelf1t64 --allow-remove-essential
apt-get autoremove -y
apt-get clean

echo -e "${BLUE}==== [2/6] Réinstallation propre de la base de paquets ] ====${NC}"
apt update --fix-missing
# On force l'installation de la version standard nécessaire pour software-properties-common
apt install -y -f
apt install -y python3 python3-minimal python3-gi python3-dbus software-properties-common gnupg apt-transport-https curl git

echo -e "${BLUE}==== [3/6] Configuration de l'identité de la machine ] ====${NC}"
systemd-machine-id-setup
dpkg-reconfigure openssh-server
hostnamectl set-hostname srv-wazuh-1

echo -e "${BLUE}==== [4/6] Lancement de l'installation officielle de Wazuh ] ====${NC}"
echo -e "${BLUE}⚠️  L'installation prend environ 15-20 minutes si le conflit est résolu !${NC}"
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
niveau = "critique" if level >= 10 else "moyen" if level >= 7 else "faible"

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

echo -e "${BLUE}==== [6/6] Activation de l'intégration XML dans ossec.conf ] ====${NC}"
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