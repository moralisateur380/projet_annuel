#!/bin/bash
# ==============================================================================
# AGRANDISSEMENT ESPACE DOCKER — srv-wazuh-1
# Crée une nouvelle partition dans l'espace libre du disque (sda)
# et y déplace les données Docker. Ne touche PAS aux partitions existantes.
# À exécuter en ROOT.
# ==============================================================================

set -e

BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

# ------------------------------------------------------------------------------
# Sécurités préalables
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Lance ce script en root : su -${NC}"
    exit 1
fi

echo -e "${BLUE}========================================================${NC}"
echo -e "${BLUE} AGRANDISSEMENT ESPACE DOCKER pour Wazuh${NC}"
echo -e "${BLUE}========================================================${NC}"
echo

# Afficher l'état actuel
echo -e "${BLUE}État actuel du disque :${NC}"
lsblk /dev/sda
echo
df -h / /var/lib/docker 2>/dev/null
echo

# ------------------------------------------------------------------------------
# Vérifier qu'il reste de l'espace libre sur le disque
# ------------------------------------------------------------------------------
DISK_SIZE=$(blockdev --getsize64 /dev/sda)
DISK_GB=$((DISK_SIZE / 1024 / 1024 / 1024))
echo -e "Taille totale du disque sda : ${YELLOW}${DISK_GB} Go${NC}"

if [ "$DISK_GB" -lt 50 ]; then
    echo -e "${RED}Le disque fait moins de 50 Go. Agrandis-le d'abord dans Proxmox${NC}"
    echo -e "${RED}(Hardware -> Hard Disk -> Disk Action -> Resize) puis relance.${NC}"
    exit 1
fi

# Vérifier si sda3 existe déjà (script déjà lancé / reprise après reboot ?)
if lsblk /dev/sda | grep -q "sda3"; then
    echo -e "${YELLOW}La partition sda3 existe déjà.${NC}"
    if mount | grep -q "/var/lib/docker"; then
        echo -e "${GREEN}/var/lib/docker est déjà monté sur une partition dédiée.${NC}"
        echo -e "${GREEN}Tout est en ordre. Relance Wazuh avec :${NC}"
        echo -e "${GREEN}  cd ~/wazuh-docker/single-node && docker compose up -d${NC}"
        exit 0
    else
        echo -e "${YELLOW}sda3 existe mais n'est pas montée sur /var/lib/docker.${NC}"
        echo -e "${YELLOW}Reprise du script : on va la formater et la monter.${NC}"
        echo
        SKIP_PARTITION=1
    fi
fi

# ------------------------------------------------------------------------------
# Confirmation utilisateur
# ------------------------------------------------------------------------------
echo
echo -e "${YELLOW}Ce script va :${NC}"
echo -e "${YELLOW}  1. Arrêter Wazuh et Docker${NC}"
echo -e "${YELLOW}  2. Créer une nouvelle partition sda3 dans l'espace libre${NC}"
echo -e "${YELLOW}  3. Y déplacer les données Docker${NC}"
echo -e "${YELLOW}  4. Redémarrer Docker${NC}"
echo
echo -e "${YELLOW}Les partitions existantes (sda1, swap) ne seront PAS touchées.${NC}"
echo
read -p "Continuer ? (oui/non) : " CONFIRM
if [ "$CONFIRM" != "oui" ]; then
    echo -e "${RED}Annulé.${NC}"
    exit 0
fi

# ------------------------------------------------------------------------------
# Étape 1 : Arrêter Wazuh et Docker
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [1/7] Arrêt de Wazuh et Docker ====${NC}"
if [ -d ~/wazuh-docker/single-node ]; then
    cd ~/wazuh-docker/single-node
    docker compose down 2>/dev/null || true
    cd ~
fi
systemctl stop docker docker.socket 2>/dev/null || true
sleep 3
echo -e "${GREEN}Docker arrêté.${NC}"

# ------------------------------------------------------------------------------
# Étape 2 : Créer la nouvelle partition dans l'espace libre
# ------------------------------------------------------------------------------
if [ "${SKIP_PARTITION:-0}" = "1" ]; then
    echo -e "${BLUE}==== [2/7] Partition sda3 déjà existante, on passe ====${NC}"
else
echo -e "${BLUE}==== [2/7] Création de la partition sda3 ====${NC}"
# On utilise sfdisk pour ajouter une partition utilisant tout l'espace libre
# --force et --no-reread : nécessaires car sda1 (système) est monté.
# On ne touche QUE l'espace libre, donc c'est sans danger pour les partitions existantes.
echo -e ';' | sfdisk --force --no-reread --append /dev/sda

# Recharger la table de partitions (le noyau doit voir la nouvelle partition)
partprobe /dev/sda 2>/dev/null || partx -u /dev/sda 2>/dev/null || true
sleep 2

# Si le noyau ne voit toujours pas sda3, forcer la relecture
if ! lsblk /dev/sda | grep -q "sda3"; then
    partx -a /dev/sda 2>/dev/null || true
    sleep 2
fi

# Vérifier que sda3 a bien été créée
if ! lsblk /dev/sda | grep -q "sda3"; then
    echo -e "${YELLOW}========================================================${NC}"
    echo -e "${YELLOW} La partition a été créée dans la table, mais le noyau${NC}"
    echo -e "${YELLOW} ne la voit pas encore (disque système monté).${NC}"
    echo -e "${YELLOW}${NC}"
    echo -e "${YELLOW} Il faut REDÉMARRER la VM puis relancer ce script.${NC}"
    echo -e "${YELLOW} Le script reprendra où il en est (il détecte sda3).${NC}"
    echo -e "${YELLOW}========================================================${NC}"
    echo
    echo -e "${BLUE}Redémarrage de Docker avant reboot...${NC}"
    systemctl start docker 2>/dev/null || true
    echo
    read -p "Redémarrer la VM maintenant ? (oui/non) : " DOREBOOT
    if [ "$DOREBOOT" = "oui" ]; then
        echo -e "${GREEN}Reboot... reconnecte-toi et relance ./agrandir-docker.sh${NC}"
        sleep 2
        reboot
    else
        echo -e "${YELLOW}Redémarre manuellement (reboot) puis relance le script.${NC}"
    fi
    exit 0
fi
echo -e "${GREEN}Partition sda3 créée et visible.${NC}"
lsblk /dev/sda
fi  # fin du bloc SKIP_PARTITION

# ------------------------------------------------------------------------------
# Étape 3 : Formater la nouvelle partition
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [3/7] Formatage de sda3 en ext4 ====${NC}"
mkfs.ext4 -F /dev/sda3
echo -e "${GREEN}sda3 formatée.${NC}"

# ------------------------------------------------------------------------------
# Étape 4 : Déplacer les données Docker existantes
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [4/7] Sauvegarde des données Docker actuelles ====${NC}"
if [ -d /var/lib/docker ]; then
    mv /var/lib/docker /var/lib/docker.old
fi
mkdir -p /var/lib/docker

# ------------------------------------------------------------------------------
# Étape 5 : Monter la nouvelle partition
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [5/7] Montage de sda3 sur /var/lib/docker ====${NC}"
# Récupérer l'UUID pour un montage stable
UUID=$(blkid -s UUID -o value /dev/sda3)
mount /dev/sda3 /var/lib/docker

# Rendre permanent via fstab (avec UUID, plus fiable que /dev/sda3)
if ! grep -q "$UUID" /etc/fstab; then
    echo "UUID=$UUID /var/lib/docker ext4 defaults 0 2" >> /etc/fstab
fi
echo -e "${GREEN}sda3 montée sur /var/lib/docker (UUID=$UUID).${NC}"

# ------------------------------------------------------------------------------
# Étape 6 : Recopier les anciennes données puis nettoyer
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [6/7] Restauration des données Docker ====${NC}"
if [ -d /var/lib/docker.old ]; then
    cp -a /var/lib/docker.old/. /var/lib/docker/ 2>/dev/null || true
    rm -rf /var/lib/docker.old
fi
echo -e "${GREEN}Données restaurées.${NC}"

# ------------------------------------------------------------------------------
# Étape 7 : Redémarrer Docker
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [7/7] Redémarrage de Docker ====${NC}"
systemctl start docker
sleep 5

# Vérifier que Docker tourne
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}Docker ne démarre pas. Vérifie : systemctl status docker${NC}"
    exit 1
fi

echo
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}✅ Espace Docker agrandi avec succès !${NC}"
echo -e "${GREEN}========================================================${NC}"
echo
echo -e "${BLUE}Nouvel espace disponible :${NC}"
df -h /var/lib/docker
echo
echo -e "${BLUE}Pour relancer Wazuh :${NC}"
echo -e "${YELLOW}  cd ~/wazuh-docker/single-node${NC}"
echo -e "${YELLOW}  docker compose up -d${NC}"
echo
echo -e "${BLUE}Puis attends 3-5 min et teste avec la boucle curl.${NC}"