#!/bin/bash
# ==============================================================================
# CONFIG SURICATA (IDS réseau) — srv-soc-1 (Marwane)
# Installe et configure Suricata pour la détection d'intrusion réseau
# À exécuter en ROOT sur srv-soc-1 (VM 107)
# ==============================================================================

set -e
BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

if [ "$EUID" -ne 0 ]; then echo -e "${RED}Lance en root : su -${NC}"; exit 1; fi

echo -e "${BLUE}========================================================${NC}"
echo -e "${BLUE} CONFIG SURICATA (IDS réseau) — srv-soc-1${NC}"
echo -e "${BLUE}========================================================${NC}"

# ------------------------------------------------------------------------------
# Détecter l'interface réseau principale
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [1/5] Détection de l'interface réseau ====${NC}"
IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [ -z "$IFACE" ]; then
    IFACE="eth0"
    echo -e "${YELLOW}Interface non détectée, on utilise eth0 par défaut${NC}"
else
    echo -e "${GREEN}Interface détectée : $IFACE${NC}"
fi

# ------------------------------------------------------------------------------
# Installer Suricata
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [2/5] Installation de Suricata ====${NC}"
apt-get update
apt-get install -y suricata jq
echo -e "${GREEN}Suricata installé : $(suricata --build-info | grep -i version | head -1)${NC}"

# ------------------------------------------------------------------------------
# Configurer l'interface à surveiller
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [3/5] Configuration de l'interface ====${NC}"
# Adapter l'interface dans la config Suricata
sed -i "s/interface: eth0/interface: $IFACE/g" /etc/suricata/suricata.yaml 2>/dev/null || true
# Définir le réseau à protéger (HOME_NET)
sed -i 's|HOME_NET:.*|HOME_NET: "[192.168.20.0/24]"|' /etc/suricata/suricata.yaml 2>/dev/null || true
echo -e "${GREEN}Interface $IFACE configurée, HOME_NET = 192.168.20.0/24${NC}"

# ------------------------------------------------------------------------------
# Télécharger les règles de détection
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [4/5] Téléchargement des règles de détection ====${NC}"
suricata-update || echo -e "${YELLOW}suricata-update a rencontré un souci, on continue${NC}"
echo -e "${GREEN}Règles téléchargées${NC}"

# ------------------------------------------------------------------------------
# Démarrer Suricata
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [5/5] Démarrage de Suricata ====${NC}"
# Tester la config avant
if suricata -T -c /etc/suricata/suricata.yaml -i "$IFACE" 2>/dev/null; then
    echo -e "${GREEN}Config Suricata valide${NC}"
fi

systemctl enable --now suricata
sleep 3

if systemctl is-active --quiet suricata; then
    echo -e "${GREEN}Suricata actif${NC}"
else
    echo -e "${YELLOW}Suricata pas encore actif, vérifie : systemctl status suricata${NC}"
fi

echo
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}✅ Suricata configuré !${NC}"
echo -e "${GREEN}========================================================${NC}"
echo
echo -e "${BLUE}Suricata surveille l'interface $IFACE (réseau 192.168.20.0/24)${NC}"
echo
echo -e "${BLUE}Commandes utiles :${NC}"
echo -e "  Voir les détections en direct : ${YELLOW}tail -f /var/log/suricata/eve.json | jq${NC}"
echo -e "  Voir les alertes              : ${YELLOW}grep alert /var/log/suricata/eve.json | jq${NC}"
echo -e "  Statut                        : ${YELLOW}systemctl status suricata${NC}"
echo
echo -e "${BLUE}Pour tester : lance un scan nmap depuis Kali vers ce réseau,${NC}"
echo -e "${BLUE}Suricata devrait le détecter.${NC}"
