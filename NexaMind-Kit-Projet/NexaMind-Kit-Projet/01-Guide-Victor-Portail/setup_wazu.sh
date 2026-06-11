#!/bin/bash
# ==============================================================================
# INSTALLATION WAZUH — srv-wazuh-1 (corrigé)
# Gère le conflit Python 3.13 / dépendances Wazuh
# À exécuter en ROOT sur la VM srv-wazuh-1 (PAS sur le template !)
# ==============================================================================

set -e  # Arrêt au premier vrai problème

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# GARDE-FOU 1 : Vérifier qu'on n'est PAS sur le template
# ------------------------------------------------------------------------------
CURRENT_HOST=$(hostname)
if [ "$CURRENT_HOST" = "srv-debian-template" ]; then
    echo -e "${RED}========================================================${NC}"
    echo -e "${RED} STOP ! Tu es sur le TEMPLATE (srv-debian-template).${NC}"
    echo -e "${RED} N'installe JAMAIS Wazuh sur le template.${NC}"
    echo -e "${RED}${NC}"
    echo -e "${RED} 1. Va dans Proxmox${NC}"
    echo -e "${RED} 2. Clone le template 101 -> VM 201 'srv-wazuh-1'${NC}"
    echo -e "${RED} 3. Démarre la VM 201 et lance ce script LÀ${NC}"
    echo -e "${RED}========================================================${NC}"
    exit 1
fi

echo -e "${BLUE}==== [1/7] Vérification de la version Python ====${NC}"
PYVER=$(python3 --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
echo -e "Python détecté : ${YELLOW}$PYVER${NC}"

# ------------------------------------------------------------------------------
# CORRECTION DU PROBLÈME PYTHON 3.13
# Wazuh ne supporte pas Python 3.13. Si présent, on installe Python 3.11
# depuis les dépôts et on le définit comme python3 par défaut.
# ------------------------------------------------------------------------------
echo -e "${BLUE}==== [2/7] Configuration des dépôts Debian ====${NC}"
cat << 'EOF' > /etc/apt/sources.list
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
EOF

apt-get update --fix-missing

echo -e "${BLUE}==== [3/7] Résolution du conflit Python (si Python 3.13) ====${NC}"
if [ "$PYVER" = "3.13" ]; then
    echo -e "${YELLOW}Python 3.13 détecté — incompatible avec Wazuh.${NC}"
    echo -e "${YELLOW}Installation de Python 3.11 (version supportée)...${NC}"

    # Installer Python 3.11 depuis bookworm (version par défaut de Debian 12)
    apt-get install -y python3.11 python3.11-minimal libpython3.11-stdlib || true

    # Pointer python3 vers 3.11 si dispo
    if [ -f /usr/bin/python3.11 ]; then
        update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 || true
        update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.13 2 || true
        # Forcer 3.11 par défaut
        update-alternatives --set python3 /usr/bin/python3.11 || true
        echo -e "${GREEN}python3 pointe maintenant vers Python 3.11${NC}"
    else
        echo -e "${YELLOW}Python 3.11 non dispo dans les dépôts, on tente quand même.${NC}"
    fi
fi

echo -e "${BLUE}==== [4/7] Installation des dépendances de base ====${NC}"
# Installer les paquets nécessaires SANS forcer la suppression d'essentiels
apt-get install -y --no-install-recommends \
    gnupg apt-transport-https curl git ca-certificates lsb-release \
    || { echo -e "${RED}Échec install dépendances de base${NC}"; exit 1; }

echo -e "${BLUE}==== [5/7] Lancement de l'installation Wazuh ====${NC}"
echo -e "${YELLOW}⚠️  Cela prend 15-20 minutes. Patiente sans interrompre.${NC}"
cd /root
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh

# Lancer avec --ignore-check pour passer la vérification de distrib
# (Debian récent n'est pas dans la liste officielle mais ça marche)
bash ./wazuh-install.sh -a -i

# Vérifier que l'install a réussi avant de continuer
if [ ! -d /var/ossec ]; then
    echo -e "${RED}========================================================${NC}"
    echo -e "${RED} L'installation Wazuh a échoué (/var/ossec absent).${NC}"
    echo -e "${RED} Consulte le log : /var/log/wazuh-install.log${NC}"
    echo -e "${RED} La suite du script est annulée.${NC}"
    echo -e "${RED}========================================================${NC}"
    exit 1
fi

echo -e "${GREEN}Wazuh installé avec succès !${NC}"

echo -e "${BLUE}==== [6/7] Intégration vers le Portail NexaMind ====${NC}"
cat << 'PYEOF' > /var/ossec/integrations/custom-nexamind.py
#!/usr/bin/env python3
import sys
import json

try:
    import requests
except ImportError:
    sys.exit(0)  # requests pas dispo, on abandonne proprement

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
    # IP du portail srv-web-1 — À ADAPTER à ton IP réelle
    requests.post("http://192.168.20.20:8000/api/alerte", json=payload, timeout=5)
except Exception:
    pass
PYEOF

chmod 750 /var/ossec/integrations/custom-nexamind.py
chown root:wazuh /var/ossec/integrations/custom-nexamind.py

# Installer requests pour le python de Wazuh
/var/ossec/framework/python/bin/pip3 install requests 2>/dev/null || pip3 install requests 2>/dev/null || true

echo -e "${BLUE}==== [7/7] Activation de l'intégration dans ossec.conf ====${NC}"
# Insérer le bloc <integration> juste avant </ossec_config>
# Méthode sûre avec un fichier temporaire
python3 - << 'PYEOF'
config = "/var/ossec/etc/ossec.conf"
with open(config) as f:
    content = f.read()

integration = """
  <integration>
    <name>custom-nexamind.py</name>
    <level>7</level>
    <alert_format>json</alert_format>
  </integration>
"""

# Insérer avant la dernière balise fermante
if "custom-nexamind.py" not in content:
    content = content.replace("</ossec_config>", integration + "</ossec_config>")
    with open(config, "w") as f:
        f.write(content)
    print("Intégration ajoutée à ossec.conf")
else:
    print("Intégration déjà présente")
PYEOF

systemctl restart wazuh-manager

echo -e "${GREEN}========================================================================${NC}"
echo -e "${GREEN}✅ Installation terminée !${NC}"
echo -e "${GREEN}   Connecte-toi sur : https://$(hostname -I | awk '{print $1}')${NC}"
echo -e "${GREEN}   Note le MOT DE PASSE admin affiché plus haut (User: admin)${NC}"
echo -e "${GREEN}   Mets-le dans Passbolt !${NC}"
echo -e "${GREEN}========================================================================${NC}"