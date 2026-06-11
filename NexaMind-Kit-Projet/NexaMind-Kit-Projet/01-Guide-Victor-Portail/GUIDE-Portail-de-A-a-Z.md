# 👤 GUIDE VICTOR — Portail Client NexaMind (de A à Z)

> **Ta mission** : construire et déployer le portail web de NexaMind.
> Le code est déjà fait (dossier `06-Code-Portail`). Ton job : le déployer, l'intégrer, le présenter.
> **Suis ce guide dans l'ordre, étape par étape.**

---

# 🎯 Vue d'ensemble de TA mission

Tu construis le **portail client** qui sert à 2 choses :
1. **Côté business** : les clients voient leurs audits, devis, alertes
2. **Côté démo** : c'est LA CIBLE de l'attaque (brute-force sur le login → détecté par Wazuh)

Le code est prêt et **testé**. Tu vas :
- ✅ Le tester sur ton PC (5 min)
- ✅ Créer une VM `srv-web-1` sur Proxmox
- ✅ Y déployer le portail
- ✅ Le rendre accessible H24 (service systemd)
- ✅ L'intégrer avec Wazuh (recevoir les alertes)
- ✅ Brancher l'API Claude (générer des devis)

---

# 📍 ÉTAPE 1 — Tester le portail sur ton PC (5 min)

Avant de déployer sur le serveur, valide que ça marche chez toi.

## 1.1 — Prérequis

Installe (si pas déjà fait) :
- **Python 3.12+** : https://www.python.org/downloads/ (coche "Add to PATH")
- **VS Code** : https://code.visualstudio.com/

## 1.2 — Lancer le portail

Ouvre le dossier `06-Code-Portail/portail-nexamind/` et dans un terminal :

```bash
# Windows
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload

# Linux/Mac
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

## 1.3 — Tester

Ouvre http://127.0.0.1:8000

- Login : `admin` / `admin123`
- Tu vois le dashboard, les alertes, les audits, les devis ✅

🎉 **Si ça marche, ton portail tourne. Passe à l'étape 2.**

---

# 📍 ÉTAPE 2 — Créer la VM serveur web (srv-web-1)

## 2.1 — Vérifier l'espace disque AVANT

⚠️ **Important** : avant de créer une VM, vérifie qu'il y a de la place.

1. Connecte-toi à Proxmox (https://192.168.20.254:8006/, via VPN)
2. Clic sur `srv-prox-01` → onglet **Summary**
3. Regarde le widget **HD space** : il doit rester au moins **30 Go libres**

Si c'est trop juste → voir `08-Procedures-Communes/Liberer-espace-disque.md`

## 2.2 — Cloner le template Debian

1. **Clic droit sur `101 (srv-debian-template)`** → **Clone**
2. Paramètres :

| Champ | Valeur |
|---|---|
| VM ID | `200` |
| Name | `srv-web-1` |
| Mode | `Full Clone` |
| Storage | `local` |

3. **Clone** → patiente ~1 min

## 2.3 — Première config de la VM

1. Démarre la VM 200 (bouton Start)
2. Ouvre la **Console**
3. Connecte-toi : `nexa` / `NexaMind2026!`
4. Lance ces commandes :

```bash
# Passer root
su -
# (mot de passe : NexaMind2026!)

# Régénérer l'identité (car cloné depuis template)
systemd-machine-id-setup
dpkg-reconfigure openssh-server

# Renommer la machine
hostnamectl set-hostname srv-web-1

# Donner sudo à nexa (au cas où)
usermod -aG sudo nexa

# Voir l'IP attribuée (NOTE-LA !)
ip a
# Cherche une ligne "inet 192.168.20.XX" -> c'est l'IP de ton serveur web

# Mettre à jour
apt update && apt upgrade -y
```

📝 **Note bien l'IP** (genre `192.168.20.50`), tu en as besoin partout ensuite.

---

# 📍 ÉTAPE 3 — Déployer le portail sur srv-web-1

## 3.1 — Installer les dépendances système

Sur la VM srv-web-1, en tant que `nexa` :

```bash
sudo apt install -y python3 python3-pip python3-venv git
```

## 3.2 — Transférer le code du portail

**Option A — Via Git (recommandé)**

Si tu as poussé le portail sur le repo :
```bash
cd /home/nexa
git clone https://github.com/VOTRE-EQUIPE/Projet-Pro_4esgi.git
cd Projet-Pro_4esgi/portail-nexamind
```

**Option B — Copier-coller manuel**

Si pas encore sur Git, tu peux recréer les fichiers à la main avec `nano`,
ou utiliser SCP/WinSCP pour transférer le dossier depuis ton PC.

## 3.3 — Installer et lancer

```bash
cd /home/nexa/portail-nexamind   # ou le chemin où est le code
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Lancer (écoute sur toutes les interfaces pour être accessible depuis le LAN)
uvicorn main:app --host 0.0.0.0 --port 8000
```

## 3.4 — Tester depuis ton PC

Depuis ton PC (connecté au VPN), ouvre :
```
http://192.168.20.50:8000/
```
*(remplace par l'IP réelle de srv-web-1)*

Tu dois voir la page de login NexaMind. 🎉

---

# 📍 ÉTAPE 4 — Rendre le portail permanent (service systemd)

Pour que le portail tourne tout le temps, même après reboot.

## 4.1 — Créer le service

```bash
sudo nano /etc/systemd/system/nexamind.service
```

Colle (adapte le chemin si besoin) :
```ini
[Unit]
Description=NexaMind Portal
After=network.target

[Service]
User=nexa
WorkingDirectory=/home/nexa/portail-nexamind
ExecStart=/home/nexa/portail-nexamind/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

Sauvegarde (Ctrl+O, Entrée, Ctrl+X).

## 4.2 — Activer le service

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now nexamind
sudo systemctl status nexamind
```

Tu dois voir **active (running)** en vert ✅

Maintenant le portail redémarre tout seul, même après un reboot de la VM.

---

# 📍 ÉTAPE 5 — Intégrer l'API Claude (générateur de devis)

## 5.1 — Récupérer une clé API

1. Va sur https://console.anthropic.com/
2. Crée un compte / connecte-toi
3. **API Keys** → **Create Key** → copie la clé (`sk-ant-...`)

⚠️ **NE COMMIT JAMAIS cette clé sur Git !**

## 5.2 — Activer le code Claude

Dans `main.py`, trouve la fonction `generer_devis()`. Il y a 2 versions :
- La version "mock" (active par défaut)
- La version "API CLAUDE" (commentée)

Pour activer Claude :
1. Installe la lib : `pip install anthropic`
2. Décommente le bloc "VERSION AVEC API CLAUDE"
3. Remplace `"TA_CLE_API"` par ta vraie clé

**Mieux : utilise une variable d'environnement** (plus sécurisé) :
```python
import os
client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
```
Et lance avec :
```bash
ANTHROPIC_API_KEY="sk-ant-..." uvicorn main:app --host 0.0.0.0 --port 8000
```

## 5.3 — Tester

Va sur la page Devis du portail, tape un besoin, clic "Générer".
→ Claude génère un vrai devis structuré. ✨

---

# 📍 ÉTAPE 6 — Intégration avec Wazuh (recevoir les alertes)

Le portail a déjà un endpoint pour recevoir les alertes du SOC :
```
POST http://srv-web-1:8000/api/alerte
```

La personne en charge de Wazuh (voir `02-Guide-SOC-Wazuh`) configurera Wazuh
pour envoyer les alertes vers cette URL. Toi, tu n'as rien à faire de plus côté portail —
les alertes apparaîtront automatiquement dans la page Alertes.

**Test manuel** (pour vérifier que ça marche) :
```bash
curl -X POST http://192.168.20.50:8000/api/alerte \
  -H "Content-Type: application/json" \
  -d '{"niveau":"critique","source":"1.2.3.4","description":"Test alerte"}'
```
Puis recharge la page Alertes → l'alerte test apparaît. ✅

---

# ✅ CHECKLIST DE TA MISSION

## Phase 1 — Local
- [ ] Portail testé sur mon PC (login admin/admin123 marche)

## Phase 2 — Déploiement
- [ ] VM srv-web-1 (200) créée depuis le template
- [ ] IP de la VM notée
- [ ] Portail déployé et accessible via http://192.168.20.XX:8000
- [ ] Service systemd actif (survit au reboot)

## Phase 3 — Intégrations
- [ ] API Claude activée (devis fonctionnels)
- [ ] Endpoint /api/alerte testé (reçoit les alertes Wazuh)

## Phase 4 — Finitions
- [ ] Code poussé sur Git
- [ ] Documenté dans le repo
- [ ] Captures d'écran pour le rapport
- [ ] Testé pour la démo (le login se fait attaquer)

---

# 🎤 Ton rôle en soutenance

Quand vient ta partie (vers 20-25 min de la démo) :
1. Montre le portail (login, dashboard, navigation)
2. Explique le stack (FastAPI + Jinja2 + SQLite + bcrypt)
3. Montre le générateur de devis IA (tape un besoin → Claude répond)
4. **Le moment clé** : montre que quand Wazuh détecte l'attaque, l'alerte
   apparaît dans TON portail → tu fais le lien entre la sécu et le business

**Phrase à dire** : *"Le portail n'est pas qu'une vitrine, c'est aussi le point
de convergence : les alertes de notre SOC y remontent, et notre assistant IA les analyse."*

---

# 🆘 Dépannage

| Problème | Solution |
|---|---|
| Portail inaccessible depuis le PC | Vérifier VPN + `sudo systemctl status nexamind` |
| "Address already in use" | Un autre process utilise le port 8000, change de port ou kill le process |
| Erreur bcrypt | `pip install --upgrade bcrypt` |
| Page blanche | Vérifier les logs : `sudo journalctl -u nexamind -f` |
| Devis IA ne marche pas | Vérifier la clé API + `pip install anthropic` |

---

*Tu as tout pour réussir ta partie. Suis les étapes dans l'ordre, teste à chaque palier. 💪*
