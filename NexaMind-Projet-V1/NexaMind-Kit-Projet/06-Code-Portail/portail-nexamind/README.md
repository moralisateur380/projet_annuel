# Portail Client NexaMind

Portail web sécurisé pour NexaMind SAS — espace client + interface SOC.

## Stack technique

- **Backend** : FastAPI (Python 3.12)
- **Templates** : Jinja2
- **Base de données** : SQLite
- **Auth** : sessions + bcrypt (mots de passe hashés)
- **Design** : CSS custom (thème "console SOC" sombre)

## Fonctionnalités

- 🔐 Authentification sécurisée (mots de passe hashés bcrypt)
- 📊 Dashboard avec stats (audits, devis, alertes)
- 🚨 Page alertes (remontées du SOC Wazuh)
- ◈ Page audits (suivi des prestations)
- 📋 Page devis avec générateur IA (API Claude)
- 🔌 API REST pour recevoir les alertes de Wazuh (`POST /api/alerte`)

## Installation locale

```bash
# 1. Créer un environnement virtuel
python3 -m venv venv
source venv/bin/activate        # Linux/Mac
# venv\Scripts\activate         # Windows

# 2. Installer les dépendances
pip install fastapi uvicorn jinja2 python-multipart bcrypt itsdangerous

# 3. Lancer le serveur
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Puis ouvrir : http://127.0.0.1:8000

## Comptes de démo

| Identifiant | Mot de passe | Rôle |
|---|---|---|
| `admin` | `admin123` | Administrateur |
| `client1` | `client123` | Client |

⚠️ **À changer en production** + mettre une vraie `secret_key` dans `main.py`.

## Déploiement sur le serveur (srv-web-1)

Voir le guide complet du projet. En résumé :

```bash
# Sur la VM srv-web-1
sudo apt install -y python3 python3-venv git
cd /home/nexa
# (copier les fichiers du portail ici)
cd nexamind-portal
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn jinja2 python-multipart bcrypt itsdangerous
uvicorn main:app --host 0.0.0.0 --port 8000
```

Pour le mettre en service permanent, créer un service systemd (voir guide).

## Intégration API Claude (devis)

Dans `main.py`, fonction `generer_devis()`, décommenter le bloc "VERSION AVEC API CLAUDE"
et ajouter ta clé API Anthropic (depuis https://console.anthropic.com/).

## Intégration Wazuh (alertes)

Wazuh peut pousser les alertes vers le portail via l'endpoint :

```
POST http://srv-web-1:8000/api/alerte
Content-Type: application/json

{"niveau": "critique", "source": "1.2.3.4", "description": "Brute-force détecté"}
```

Configurer une "integration" custom dans Wazuh pour appeler cet endpoint.

## Structure des fichiers

```
nexamind-portal/
├── main.py                  # Application FastAPI (routes + DB)
├── nexamind.db              # Base SQLite (créée au 1er lancement)
├── templates/
│   ├── base.html            # Layout commun (sidebar + design)
│   ├── login.html           # Page de connexion
│   ├── dashboard.html       # Tableau de bord
│   ├── alertes.html         # Journal des alertes SOC
│   ├── audits.html          # Suivi des audits
│   └── devis.html           # Devis + générateur IA
└── static/                  # Fichiers statiques (vide pour l'instant)
```

## Sécurité — notes pour le rapport

- Mots de passe **hashés avec bcrypt** (jamais en clair en base)
- Sessions signées (cookie sécurisé via SessionMiddleware)
- Routes protégées : redirection vers login si pas de session
- ⚠️ Le formulaire de login est **volontairement la cible** de la démo brute-force :
  chaque échec génère un log que Wazuh détecte.

## TODO (évolutions)

- [ ] Authentification via Active Directory (LDAP/Kerberos)
- [ ] HTTPS via reverse proxy nginx + Let's Encrypt
- [ ] Activation de l'API Claude pour les devis
- [ ] Connexion temps réel aux alertes Wazuh
- [ ] Rôles différenciés client vs admin (vues séparées)
