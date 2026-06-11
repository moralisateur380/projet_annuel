#!/bin/bash
# ==============================================================================
# INSTALLATION WAZUH VIA DOCKER — srv-wazuh-1
# Méthode officielle, indépendante de la version Debian
# À exécuter en ROOT sur une VM srv-wazuh-1 PROPRE (pas le template !)
# ==============================================================================

set -e

BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

# ------------------------------------------------------------------------------
# GARDE-FOU : pas sur le template
# ------------------------------------------------------------------------------
if [ "$(hostname)" = "srv-debian-template" ]; then
    echo -e "${RED}STOP : tu es sur le template. Clone-le d'abord en VM 201.${NC}"
    exit 1
fi

echo -e "${BLUE}==== [1/6] Vérifications préalables ====${NC}"

# Vérifier qu'on est root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Lance ce script en root (su -)${NC}"
    exit 1
fi

# Vérifier la RAM disponible
RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
echo -e "RAM détectée : ${YELLOW}${RAM_MB} Mo${NC}"
if [ "$RAM_MB" -lt 3800 ]; then
    echo -e "${RED}⚠️  RAM insuffisante (${RAM_MB} Mo). Wazuh Docker veut 4 Go minimum.${NC}"
    echo -e "${RED}   Éteins la VM, augmente la RAM dans Proxmox, et relance.${NC}"
    exit 1
fi

# Réparer apt si "ip" est cassé (cas des VM abîmées)
if ! command -v ip >/dev/null 2>&1; then
    echo -e "${YELLOW}La commande 'ip' manque, réparation de iproute2...${NC}"
    apt-get update --fix-missing || true
    apt-get install -y --reinstall iproute2 || true
fi

echo -e "${BLUE}==== [2/6] Nettoyage et mise à jour des dépôts ====${NC}"
# Repérer la version Debian pour utiliser le bon dépôt Docker
. /etc/os-release
echo -e "Distribution : ${YELLOW}${PRETTY_NAME}${NC}"

apt-get update --fix-missing
apt-get install -y ca-certificates curl gnupg lsb-release

echo -e "${BLUE}==== [3/6] Installation de Docker ====${NC}"
# Méthode officielle Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Déterminer le nom de code Debian (bookworm pour 12, trixie pour 13)
DEBIAN_CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
# Docker n'a pas toujours de repo pour trixie ; on retombe sur bookworm si besoin
if [ "$DEBIAN_CODENAME" = "trixie" ]; then
    echo -e "${YELLOW}Debian 13 (trixie) : utilisation du dépôt Docker bookworm (compatible).${NC}"
    DEBIAN_CODENAME="bookworm"
fi

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $DEBIAN_CODENAME stable" > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Démarrer Docker
systemctl enable --now docker

# Vérifier Docker
if ! docker --version >/dev/null 2>&1; then
    echo -e "${RED}Échec de l'installation de Docker.${NC}"
    exit 1
fi
echo -e "${GREEN}Docker installé : $(docker --version)${NC}"

echo -e "${BLUE}==== [4/6] Configuration système pour Wazuh ====${NC}"
# Wazuh/OpenSearch a besoin d'une valeur élevée de max_map_count
sysctl -w vm.max_map_count=262144
# Rendre permanent
if ! grep -q "vm.max_map_count" /etc/sysctl.conf; then
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf
fi

echo -e "${BLUE}==== [5/6] Récupération de Wazuh Docker ====${NC}"
cd /root
# Cloner le dépôt officiel wazuh-docker
if [ ! -d wazuh-docker ]; then
    git clone https://github.com/wazuh/wazuh-docker.git -b v4.9.2
fi
cd wazuh-docker/single-node

echo -e "${YELLOW}Génération des certificats SSL...${NC}"
docker compose -f generate-indexer-certs.yml run --rm generator

echo -e "${BLUE}==== [6/6] Démarrage de Wazuh ====${NC}"
echo -e "${YELLOW}⚠️  Premier démarrage : 5-10 min (téléchargement des images).${NC}"
docker compose up -d

# Attendre un peu que les conteneurs montent
sleep 30

echo -e "${GREEN}========================================================================${NC}"
echo -e "${GREEN}✅ Wazuh Docker démarré !${NC}"
echo -e "${GREEN}========================================================================${NC}"
echo -e "${GREEN}Dashboard : https://$(hostname -I | awk '{print $1}')${NC}"
echo -e "${GREEN}   Identifiants par défaut :${NC}"
echo -e "${GREEN}   User     : admin${NC}"
echo -e "${GREEN}   Password : SecretPassword${NC}"
echo -e "${YELLOW}   ⚠️  CHANGE ce mot de passe par défaut ! (voir doc Wazuh)${NC}"
echo -e "${GREEN}========================================================================${NC}"
echo
echo -e "${BLUE}Commandes utiles :${NC}"
echo -e "  Voir les conteneurs : ${YELLOW}docker ps${NC}"
echo -e "  Voir les logs       : ${YELLOW}docker compose logs -f${NC}  (dans /root/wazuh-docker/single-node)"
echo -e "  Arrêter Wazuh       : ${YELLOW}docker compose down${NC}"
echo -e "  Redémarrer Wazuh    : ${YELLOW}docker compose up -d${NC}"
echo
echo -e "${YELLOW}Note : si le dashboard ne répond pas tout de suite, attends 2-3 min${NC}"
echo -e "${YELLOW}que tous les conteneurs finissent de démarrer. Vérifie avec 'docker ps'.${NC}"
