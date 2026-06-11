#!/bin/bash
# ==============================================================================
# CONFIG ACTIVE DIRECTORY — srv-ad-1 (Jacques)
# Crée les OU, utilisateurs et groupes de l'entreprise NexaMind
# À exécuter en ROOT sur srv-ad-1 (192.168.20.10)
# ==============================================================================

set -e
BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

if [ "$EUID" -ne 0 ]; then echo -e "${RED}Lance en root : su -${NC}"; exit 1; fi

# Vérifier que samba-tool existe
if ! command -v samba-tool >/dev/null 2>&1; then
    echo -e "${RED}samba-tool introuvable. Es-tu bien sur le serveur AD ?${NC}"
    exit 1
fi

DOMAIN="DC=cybernest,DC=local"
PASS="MotDePasse2026!"

echo -e "${BLUE}========================================================${NC}"
echo -e "${BLUE} CONFIG ACTIVE DIRECTORY — NexaMind${NC}"
echo -e "${BLUE}========================================================${NC}"

# ------------------------------------------------------------------------------
# Créer les Unités d'Organisation
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [1/4] Création des Unités d'Organisation ====${NC}"
for OU in Direction IT Clients; do
    if samba-tool ou create "OU=$OU,$DOMAIN" 2>/dev/null; then
        echo -e "${GREEN}OU $OU créée${NC}"
    else
        echo -e "${YELLOW}OU $OU existe déjà${NC}"
    fi
done

# ------------------------------------------------------------------------------
# Créer les utilisateurs
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [2/4] Création des utilisateurs ====${NC}"
# Format : user:OU
USERS="j.dupont:Direction a.durand:Direction m.martin:IT p.bernard:IT client.acme:Clients"
for ENTRY in $USERS; do
    USER="${ENTRY%%:*}"
    OU="${ENTRY##*:}"
    if samba-tool user create "$USER" "$PASS" --userou="OU=$OU" 2>/dev/null; then
        echo -e "${GREEN}Utilisateur $USER créé (OU=$OU)${NC}"
    else
        echo -e "${YELLOW}Utilisateur $USER existe déjà${NC}"
    fi
done

# ------------------------------------------------------------------------------
# Créer les groupes et ajouter les membres
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [3/4] Création des groupes ====${NC}"
for GROUP in "Administrateurs-IT" "Direction-Groupe" "Clients-Externes"; do
    samba-tool group create "$GROUP" 2>/dev/null && echo -e "${GREEN}Groupe $GROUP créé${NC}" || echo -e "${YELLOW}Groupe $GROUP existe déjà${NC}"
done

# Ajouter les membres
samba-tool group addmembers "Administrateurs-IT" m.martin,p.bernard 2>/dev/null || true
samba-tool group addmembers "Direction-Groupe" j.dupont,a.durand 2>/dev/null || true
samba-tool group addmembers "Clients-Externes" client.acme 2>/dev/null || true
echo -e "${GREEN}Membres ajoutés aux groupes${NC}"

# ------------------------------------------------------------------------------
# Activer l'audit des connexions (pour Wazuh)
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [4/4] Activation de l'audit des connexions ====${NC}"
if ! grep -q "auth_audit" /etc/samba/smb.conf; then
    # Ajouter le log level dans la section [global]
    sed -i '/\[global\]/a \    log level = 3 auth_audit:3' /etc/samba/smb.conf
    echo -e "${GREEN}Audit activé dans smb.conf${NC}"
    systemctl restart samba-ad-dc 2>/dev/null || systemctl restart samba 2>/dev/null || true
    echo -e "${GREEN}Samba redémarré${NC}"
else
    echo -e "${YELLOW}Audit déjà activé${NC}"
fi

echo
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}✅ Active Directory configuré !${NC}"
echo -e "${GREEN}========================================================${NC}"
echo
echo -e "${BLUE}Récapitulatif :${NC}"
samba-tool user list 2>/dev/null | grep -E "j.dupont|a.durand|m.martin|p.bernard|client.acme" || true
echo
echo -e "${BLUE}Mot de passe de tous les comptes : ${YELLOW}$PASS${NC}"
echo -e "${YELLOW}(à changer + mettre dans Passbolt)${NC}"
echo
echo -e "${BLUE}PROCHAINE ÉTAPE : joindre le poste Windows au domaine${NC}"
echo -e "${BLUE}(voir le guide Jacques, étape 4)${NC}"
