#!/bin/bash
# ==============================================================================
# CONFIG DÉTECTION — Partie MANAGER WAZUH (srv-wazuh-1)
# Crée les règles de détection brute-force sur le portail + intégration portail
# À exécuter en ROOT sur srv-wazuh-1 (192.168.20.22)
# ==============================================================================

set -e
BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

if [ "$EUID" -ne 0 ]; then echo -e "${RED}Lance en root : su -${NC}"; exit 1; fi

CONTAINER="single-node-wazuh.manager-1"
WEB_IP="192.168.20.20"   # IP du portail srv-web-1

echo -e "${BLUE}========================================================${NC}"
echo -e "${BLUE} CONFIG DÉTECTION — Manager Wazuh srv-wazuh-1${NC}"
echo -e "${BLUE}========================================================${NC}"

# ------------------------------------------------------------------------------
# Vérifier que le conteneur manager tourne
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [1/5] Vérification du conteneur Wazuh ====${NC}"
if ! docker ps --format '{{.Names}}' | grep -q "$CONTAINER"; then
    echo -e "${RED}Le conteneur $CONTAINER ne tourne pas.${NC}"
    echo -e "${RED}Lance Wazuh : cd ~/wazuh-docker/single-node && docker compose up -d${NC}"
    exit 1
fi
echo -e "${GREEN}Conteneur $CONTAINER actif${NC}"

# ------------------------------------------------------------------------------
# Créer la règle de détection brute-force
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [2/5] Création de la règle de détection brute-force ====${NC}"

# On écrit la règle dans un fichier temporaire sur l'hôte
cat > /tmp/local_rules.xml << 'XMLEOF'
<!-- Règles personnalisées NexaMind -->
<group name="nexamind,attack,web,">

  <!-- Détecte un POST vers /login (tentative de connexion) -->
  <rule id="100090" level="3">
    <if_sid>31100</if_sid>
    <url>/login</url>
    <regex>POST</regex>
    <description>NexaMind: Tentative de connexion au portail</description>
  </rule>

  <!-- Détecte un brute-force : 6+ tentatives de login en 30s depuis la même IP -->
  <rule id="100100" level="10" frequency="6" timeframe="30">
    <if_matched_sid>100090</if_matched_sid>
    <same_source_ip />
    <description>NexaMind: Brute-force detecte sur le portail (6+ tentatives en 30s)</description>
    <group>authentication_failures,attack,</group>
  </rule>

  <!-- Détecte un scan/grand volume : 20+ requêtes en 10s -->
  <rule id="100101" level="12" frequency="20" timeframe="10">
    <if_matched_sid>31100</if_matched_sid>
    <same_source_ip />
    <description>NexaMind: Volume anormal de requetes (scan probable)</description>
    <group>attack,recon,</group>
  </rule>

</group>
XMLEOF

# Copier le fichier dans le conteneur
docker cp /tmp/local_rules.xml "$CONTAINER":/var/ossec/etc/rules/local_rules.xml
# Mettre les bons droits
docker exec "$CONTAINER" chown wazuh:wazuh /var/ossec/etc/rules/local_rules.xml
docker exec "$CONTAINER" chmod 660 /var/ossec/etc/rules/local_rules.xml
rm -f /tmp/local_rules.xml
echo -e "${GREEN}Règles de détection créées${NC}"

# ------------------------------------------------------------------------------
# Créer le script d'intégration vers le portail
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [3/5] Création de l'intégration vers le portail ====${NC}"

cat > /tmp/custom-nexamind.py << PYEOF
#!/usr/bin/env python3
import sys
import json

try:
    import requests
except ImportError:
    sys.exit(0)

alert_file = sys.argv[1]
with open(alert_file) as f:
    alert = json.load(f)

level = alert.get("rule", {}).get("level", 0)
niveau = "critique" if level >= 10 else "moyen" if level >= 7 else "faible"
payload = {
    "niveau": niveau,
    "source": alert.get("data", {}).get("srcip", alert.get("agent", {}).get("ip", "inconnu")),
    "description": alert.get("rule", {}).get("description", "Alerte detectee par le SOC"),
}

try:
    requests.post("http://${WEB_IP}:8000/api/alerte", json=payload, timeout=5)
except Exception:
    pass
PYEOF

docker cp /tmp/custom-nexamind.py "$CONTAINER":/var/ossec/integrations/custom-nexamind.py
docker exec "$CONTAINER" chown root:wazuh /var/ossec/integrations/custom-nexamind.py
docker exec "$CONTAINER" chmod 750 /var/ossec/integrations/custom-nexamind.py
rm -f /tmp/custom-nexamind.py
echo -e "${GREEN}Script d'intégration créé${NC}"

# Installer requests dans le conteneur si besoin
docker exec "$CONTAINER" /var/ossec/framework/python/bin/pip3 install requests 2>/dev/null || true

# ------------------------------------------------------------------------------
# Activer l'intégration dans ossec.conf du conteneur
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [4/5] Activation de l'intégration ====${NC}"

# Récupérer la config actuelle, ajouter le bloc integration, la remettre
docker exec "$CONTAINER" cat /var/ossec/etc/ossec.conf > /tmp/ossec.conf

if grep -q "custom-nexamind.py" /tmp/ossec.conf; then
    echo -e "${YELLOW}Intégration déjà activée, on passe.${NC}"
else
    python3 - << 'PYEOF'
config = "/tmp/ossec.conf"
with open(config) as f:
    content = f.read()

integration = """
  <integration>
    <name>custom-nexamind.py</name>
    <level>7</level>
    <alert_format>json</alert_format>
  </integration>
"""

idx = content.rfind("</ossec_config>")
if idx != -1:
    content = content[:idx] + integration + "\n" + content[idx:]
    with open(config, "w") as f:
        f.write(content)
    print("Intégration ajoutée")
PYEOF
    # Remettre la config dans le conteneur
    docker cp /tmp/ossec.conf "$CONTAINER":/var/ossec/etc/ossec.conf
    docker exec "$CONTAINER" chown root:wazuh /var/ossec/etc/ossec.conf
    echo -e "${GREEN}Intégration activée${NC}"
fi
rm -f /tmp/ossec.conf

# ------------------------------------------------------------------------------
# Redémarrer le manager
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [5/5] Redémarrage du manager Wazuh ====${NC}"
docker restart "$CONTAINER"
echo -e "${YELLOW}Le manager redémarre (30-60s)...${NC}"
sleep 30

echo
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}✅ Manager Wazuh configuré pour la détection !${NC}"
echo -e "${GREEN}========================================================${NC}"
echo
echo -e "${BLUE}Règles créées :${NC}"
echo -e "  - 100090 : détecte une tentative de connexion (POST /login)"
echo -e "  - 100100 : détecte un brute-force (6+ tentatives en 30s)"
echo -e "  - 100101 : détecte un scan (20+ requêtes en 10s)"
echo
echo -e "${BLUE}Intégration :${NC}"
echo -e "  Les alertes niveau 7+ sont envoyées au portail (${WEB_IP}:8000/api/alerte)"
echo
echo -e "${YELLOW}PROCHAINE ÉTAPE : lancer une attaque de test pour vérifier !${NC}"
echo -e "${YELLOW}(je te donne le script d'attaque ensuite)${NC}"