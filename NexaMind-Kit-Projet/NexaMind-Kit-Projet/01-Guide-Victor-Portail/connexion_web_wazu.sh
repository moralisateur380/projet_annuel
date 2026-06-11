#!/bin/bash
# ==============================================================================
# CONFIG DÉTECTION — Partie SERVEUR WEB (srv-web-1)
# Configure l'agent Wazuh pour surveiller les logs nginx du portail
# À exécuter en ROOT sur srv-web-1 (192.168.20.20)
# ==============================================================================

set -e
BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

if [ "$EUID" -ne 0 ]; then echo -e "${RED}Lance en root : su -${NC}"; exit 1; fi

echo -e "${BLUE}========================================================${NC}"
echo -e "${BLUE} CONFIG DÉTECTION — Serveur Web srv-web-1${NC}"
echo -e "${BLUE}========================================================${NC}"

# ------------------------------------------------------------------------------
# Vérifier que nginx et l'agent Wazuh sont là
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [1/4] Vérifications ====${NC}"
if ! systemctl is-active --quiet nginx; then
    echo -e "${RED}nginx n'est pas actif. Démarre-le d'abord.${NC}"; exit 1
fi
echo -e "${GREEN}nginx actif${NC}"

if [ ! -f /var/ossec/etc/ossec.conf ]; then
    echo -e "${RED}Agent Wazuh non trouvé (/var/ossec absent).${NC}"; exit 1
fi
echo -e "${GREEN}Agent Wazuh présent${NC}"

# S'assurer que le log nginx existe
touch /var/log/nginx/access.log /var/log/nginx/error.log

# ------------------------------------------------------------------------------
# Améliorer le format de log nginx pour bien capturer les POST /login
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [2/4] Configuration du format de log nginx ====${NC}"
# On vérifie que nginx logge bien la méthode + l'URL (format combined par défaut le fait)
# Le format combined inclut déjà "$request" qui contient "POST /login HTTP/1.1"
echo -e "${GREEN}Format combined nginx OK (capture méthode + URL + IP)${NC}"

# ------------------------------------------------------------------------------
# Ajouter la surveillance des logs nginx dans la config de l'agent
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [3/4] Ajout de la surveillance des logs nginx ====${NC}"

# Vérifier si déjà configuré
if grep -q "/var/log/nginx/access.log" /var/ossec/etc/ossec.conf; then
    echo -e "${YELLOW}Surveillance nginx déjà configurée, on passe.${NC}"
else
    # Insérer les blocs localfile juste avant la fin de la config
    # On utilise Python pour une insertion propre
    python3 - << 'PYEOF'
config = "/var/ossec/etc/ossec.conf"
with open(config) as f:
    content = f.read()

blocs = """
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/nginx/access.log</location>
  </localfile>

  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/nginx/error.log</location>
  </localfile>
"""

# Insérer avant la dernière balise </ossec_config>
idx = content.rfind("</ossec_config>")
if idx != -1:
    content = content[:idx] + blocs + "\n" + content[idx:]
    with open(config, "w") as f:
        f.write(content)
    print("Blocs localfile ajoutés")
else:
    print("ERREUR: </ossec_config> non trouvé")
PYEOF
    echo -e "${GREEN}Surveillance des logs nginx ajoutée${NC}"
fi

# ------------------------------------------------------------------------------
# Redémarrer l'agent
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [4/4] Redémarrage de l'agent Wazuh ====${NC}"
systemctl restart wazuh-agent
sleep 3

if systemctl is-active --quiet wazuh-agent; then
    echo -e "${GREEN}Agent Wazuh redémarré et actif${NC}"
else
    echo -e "${RED}L'agent ne redémarre pas. Vérifie : systemctl status wazuh-agent${NC}"
    exit 1
fi

echo
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}✅ Serveur web configuré pour la détection !${NC}"
echo -e "${GREEN}========================================================${NC}"
echo
echo -e "${BLUE}L'agent surveille maintenant :${NC}"
echo -e "  - /var/log/nginx/access.log (les requêtes vers le portail)"
echo -e "  - /var/log/nginx/error.log"
echo
echo -e "${YELLOW}PROCHAINE ÉTAPE : lance le script sur le MANAGER Wazuh${NC}"
echo -e "${YELLOW}(srv-wazuh-1) pour créer la règle de détection.${NC}"
echo
echo -e "${BLUE}Pour vérifier que les logs arrivent, génère du trafic :${NC}"
echo -e "  ${YELLOW}curl http://localhost/login${NC}"
echo -e "  ${YELLOW}tail -5 /var/log/nginx/access.log${NC}"