#!/bin/bash
# ============================================
# Lancement rapide du portail NexaMind (Linux/Mac)
# Usage : bash LANCER-LINUX.sh
# ============================================

echo "===================================="
echo "  NexaMind Portal - Démarrage"
echo "===================================="
echo

# Créer le venv s'il n'existe pas
if [ ! -d "venv" ]; then
    echo "Création de l'environnement Python..."
    python3 -m venv venv
fi

# Activer le venv
source venv/bin/activate

# Installer les dépendances
echo "Installation des dépendances..."
pip install -r requirements.txt --quiet

# Lancer
echo
echo "===================================="
echo "  Portail lancé !"
echo "  Ouvre : http://127.0.0.1:8000"
echo "  Login : admin / admin123"
echo "  (Ctrl+C pour arrêter)"
echo "===================================="
echo
uvicorn main:app --reload --host 0.0.0.0 --port 8000
