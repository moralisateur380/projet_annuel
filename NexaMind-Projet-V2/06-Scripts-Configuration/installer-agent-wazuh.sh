#!/bin/bash
# ==============================================================================
# INSTALLATION AGENT WAZUH — sur n'importe quelle VM Linux à surveiller
# Connecte la VM au SOC Wazuh (srv-wazuh-1)
# À exécuter en ROOT sur la VM à surveiller (ex: srv-ad-1)
# ==============================================================================

set -e
BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

if [ "$EUID" -ne 0 ]; then echo -e "${RED}Lance en root : su -${NC}"; exit 1; fi

WAZUH_MANAGER="192.168.20.22"   # IP du SOC Wazuh (srv-wazuh-1)

echo -e "${BLUE}========================================================${NC}"
echo -e "${BLUE} INSTALLATION AGENT WAZUH${NC}"
echo -e "${BLUE} Manager : $WAZUH_MANAGER${NC}"
echo -e "${BLUE} Cette machine : $(hostname)${NC}"
echo -e "${BLUE}========================================================${NC}"

# Garde-fou : pas sur le template
if [ "$(hostname)" = "srv-debian-template" ]; then
    echo -e "${RED}Tu es sur le template ! Clone-le d'abord.${NC}"; exit 1
fi

echo -e "${BLUE}==== [1/3] Téléchargement de l'agent ====${NC}"
cd /root
wget -q https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.9.2-1_amd64.deb
echo -e "${GREEN}Agent téléchargé${NC}"

echo -e "${BLUE}==== [2/3] Installation (manager = $WAZUH_MANAGER) ====${NC}"
WAZUH_MANAGER="$WAZUH_MANAGER" dpkg -i ./wazuh-agent_4.9.2-1_amd64.deb
echo -e "${GREEN}Agent installé${NC}"

echo -e "${BLUE}==== [3/3] Démarrage de l'agent ====${NC}"
systemctl daemon-reload
systemctl enable --now wazuh-agent
sleep 3

if systemctl is-active --quiet wazuh-agent; then
    echo -e "${GREEN}Agent Wazuh actif${NC}"
else
    echo -e "${RED}L'agent ne démarre pas. Vérifie : systemctl status wazuh-agent${NC}"
    exit 1
fi

rm -f /root/wazuh-agent_4.9.2-1_amd64.deb

echo
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}✅ Agent Wazuh installé et démarré !${NC}"
echo -e "${GREEN}========================================================${NC}"
echo
echo -e "${BLUE}Vérifie dans le dashboard Wazuh (https://$WAZUH_MANAGER) :${NC}"
echo -e "  Menu ☰ → Endpoints → $(hostname) doit apparaître en Active"
echo
echo -e "${YELLOW}Si l'agent reste 'Disconnected', vérifie que les ports${NC}"
echo -e "${YELLOW}1514 et 1515 passent dans le firewall pfSense.${NC}"
