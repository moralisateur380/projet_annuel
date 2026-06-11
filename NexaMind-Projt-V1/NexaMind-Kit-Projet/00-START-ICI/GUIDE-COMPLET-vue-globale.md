# 🚀 GUIDE COMPLET — Projet NexaMind de A à Z
### Là où tu en es → jusqu'à la soutenance

> **Pour** : Victor TASSART
> **Date** : 1er juin 2026
> **Objectif** : Construire le Portail NexaMind + le scénario d'attaque/détection
> **Soutenance** : juillet 2026

---

# 📍 PARTIE 0 — Où on en est (état des lieux)

## Ce qui EXISTE déjà sur le serveur

| VM ID | Nom | Rôle | État |
|---|---|---|---|
| 100 | `srv-pfsense-ro` | Firewall + VPN | ✅ OK |
| 101 | `srv-debian-template` | Template Debian | ✅ Template (ton travail) |
| 102 | `srv-win10-template` | Template Windows | ✅ Template (ton travail) |
| 103 | `srv-passbolt-1` | Coffre mots de passe | ✅ OK |
| 104 | `srv-ad-1` | Active Directory Samba | ✅ OK |
| 105 | `win10-tempon` | Windows de test | 🟡 À clarifier |
| 106 | `client-win-1` | Poste client Windows | ✅ OK |

## Ce qu'il MANQUE (et que tu vas construire)

| Brique | VM à créer | Priorité |
|---|---|---|
| Serveur web (portail NexaMind) | `srv-web-1` | 🔴 Haute |
| SIEM Wazuh | `srv-wazuh-1` | 🔴 Haute |
| Machine d'attaque Kali | `srv-kali-1` | 🟡 Moyenne |

---

# 🗺️ PARTIE 1 — Plan d'ensemble (la carte)

Voici l'architecture cible que tu vas compléter :

```
                          INTERNET
                             │
                             ▼
                    ┌─────────────────┐
                    │  pfSense (100)  │  Firewall + VPN
                    │  LAN 192.168.20 │
                    └────────┬────────┘
                             │ vmbr2 (LAN)
       ┌──────────┬──────────┼──────────┬──────────┐
       ▼          ▼          ▼          ▼          ▼
   ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
   │ AD 104 │ │Passb103│ │ WEB    │ │ WAZUH  │ │ KALI   │
   │.20.10  │ │.20.x   │ │ (NEW)  │ │ (NEW)  │ │ (NEW)  │
   └────────┘ └────────┘ └───┬────┘ └───▲────┘ └───┬────┘
                             │          │          │
                  Portail web│   alertes│   attaque│
                             └──logs────┘◄─────────┘
```

**Le scénario final de démo** :
1. Kali attaque le serveur Web (brute-force sur le login du portail)
2. Wazuh détecte l'attaque via les logs du serveur Web
3. Une alerte apparaît dans le dashboard Wazuh
4. (Bonus) L'API Claude analyse l'alerte en français

---

# 🖥️ PARTIE 2 — Créer les VM (noms + config)

## VM #1 — Serveur Web `srv-web-1`

C'est la VM qui hébergera ton portail NexaMind.

### Création (clone du template Debian)

1. Proxmox → **clic droit sur `101 (srv-debian-template)`** → **Clone**
2. Paramètres :

| Champ | Valeur |
|---|---|
| **VM ID** | `200` |
| **Name** | `srv-web-1` |
| **Mode** | `Full Clone` |
| **Storage** | `local` |

3. **Clone** → patiente ~1 min

### Première config (après le clone)

Démarre la VM 200, ouvre la Console, connecte-toi (`nexa` / ton mdp), puis :

```bash
# Passer root
su -

# Régénérer l'identité unique (IMPORTANT car cloné)
systemd-machine-id-setup
dpkg-reconfigure openssh-server

# Renommer la machine
hostnamectl set-hostname srv-web-1

# Vérifier l'IP obtenue (DHCP pfSense)
ip a
# Note l'IP, genre 192.168.20.50 — tu en auras besoin

# Mettre à jour
apt update && apt upgrade -y
```

### Test VM #1
```bash
ping -c 3 8.8.8.8        # Internet OK ?
hostname                  # doit afficher srv-web-1
```

---

## VM #2 — Serveur Wazuh `srv-wazuh-1`

⚠️ **Wazuh a besoin de ressources** : minimum 4 Go RAM, 2 cores, 50 Go disque. Si ton serveur est short en RAM, on en reparle.

### Création (clone du template Debian)

1. **Clic droit sur `101`** → **Clone**
2. Paramètres :

| Champ | Valeur |
|---|---|
| **VM ID** | `201` |
| **Name** | `srv-wazuh-1` |
| **Mode** | `Full Clone` |
| **Storage** | `local` |

3. **Clone**

### Augmenter les ressources (Wazuh est gourmand)

Avant de démarrer, sur la VM 201 :
1. Onglet **Hardware** → **Memory** → mettre `4096` (4 Go) minimum, idéalement `6144` (6 Go)
2. **Processors** → `2` cores minimum
3. **Hard Disk** → clic → **Disk Action** → **Resize** → ajouter `+30G` (Wazuh stocke beaucoup de logs)

### Première config

```bash
su -
systemd-machine-id-setup
dpkg-reconfigure openssh-server
hostnamectl set-hostname srv-wazuh-1
ip a    # note l'IP, genre 192.168.20.51
apt update && apt upgrade -y
```

---

## VM #3 — Machine d'attaque `srv-kali-1`

⚠️ Kali = OS spécifique, **pas un clone du template Debian**. Il faut télécharger l'ISO Kali.

### Option A — Télécharger l'ISO Kali sur Proxmox

1. Proxmox → `local` → **ISO Images** → **Download from URL**
2. URL : `https://cdimage.kali.org/kali-2024.4/kali-linux-2024.4-installer-amd64.iso`
   *(vérifie la dernière version sur kali.org/get-kali)*
3. **Download**

### Création de la VM

1. **Create VM**
2. Paramètres :

| Champ | Valeur |
|---|---|
| **VM ID** | `202` |
| **Name** | `srv-kali-1` |
| **ISO** | `kali-linux-...iso` |
| **CPU** | `x86-64-v2-AES`, 2 cores |
| **RAM** | `2048` (2 Go) |
| **Disque** | `30` Go SCSI VirtIO |
| **Bridge** | `vmbr2` |
| **BIOS** | SeaBIOS (legacy, OK pour Kali) |

3. Installer Kali (install graphique classique, comme Debian)

### Alternative plus légère

Si Kali est trop lourd, tu peux faire l'attaque **depuis le template Debian** avec juste les outils installés :
```bash
apt install -y hydra nmap nikto
```
→ Pas besoin de Kali complet pour une démo brute-force.

---

# 🌐 PARTIE 3 — Installer le Portail NexaMind (sur srv-web-1)

## 3.1 — Installer les dépendances

Sur `srv-web-1` (VM 200), en tant que `nexa` :

```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv git nginx
```

## 3.2 — Récupérer le code du portail

Le code complet du portail, je te le génère dans un message séparé (c'est un gros morceau). Pour l'instant, prépare le dossier :

```bash
cd /home/nexa
mkdir nexamind-portal
cd nexamind-portal
python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn jinja2 python-multipart passlib bcrypt
```

## 3.3 — Lancer le portail

```bash
# Depuis le dossier nexamind-portal, venv activé
uvicorn main:app --host 0.0.0.0 --port 8000
```

## 3.4 — Test du portail

Depuis ton PC (connecté au VPN), ouvre :
```
http://192.168.20.50:8000/
```
*(remplace par l'IP réelle de srv-web-1)*

Tu dois voir la page de login NexaMind. ✅

## 3.5 — Mettre le portail en service permanent (systemd)

Pour que le portail tourne tout le temps (même après reboot) :

```bash
sudo nano /etc/systemd/system/nexamind.service
```

Colle :
```ini
[Unit]
Description=NexaMind Portal
After=network.target

[Service]
User=nexa
WorkingDirectory=/home/nexa/nexamind-portal
ExecStart=/home/nexa/nexamind-portal/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

Puis :
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now nexamind
sudo systemctl status nexamind   # doit être "active (running)"
```

---

# 🛡️ PARTIE 4 — Installer Wazuh (sur srv-wazuh-1)

## 4.1 — Installation rapide (script officiel)

Sur `srv-wazuh-1` (VM 201), en root :

```bash
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
sudo bash ./wazuh-install.sh -a
```

⏳ Ça installe le manager + indexer + dashboard. **Compte 15-20 min.**

À la fin, le script affiche :
```
User: admin
Password: <un mot de passe généré>
```
**NOTE CE MOT DE PASSE** (et mets-le dans Passbolt).

## 4.2 — Accéder au dashboard Wazuh

Depuis ton PC (VPN) :
```
https://192.168.20.51/
```
*(IP de srv-wazuh-1)*

Login : `admin` / le mot de passe généré.

## 4.3 — Test Wazuh
- Le dashboard s'affiche ✅
- Va dans **Agents** → pour l'instant 0 agent, c'est normal

## 4.4 — Installer l'agent Wazuh sur le serveur Web

C'est ce qui permet à Wazuh de surveiller le portail. Sur `srv-web-1` (VM 200) :

```bash
# Remplace WAZUH_IP par l'IP de srv-wazuh-1
WAZUH_MANAGER="192.168.20.51"
curl -sO https://packages.wazuh.com/4.9/wazuh-agent_4.9.0-1_amd64.deb
sudo WAZUH_MANAGER="192.168.20.51" dpkg -i ./wazuh-agent_4.9.0-1_amd64.deb
sudo systemctl daemon-reload
sudo systemctl enable --now wazuh-agent
```

## 4.5 — Test de l'agent

Sur le dashboard Wazuh → **Agents** → tu dois voir `srv-web-1` apparaître avec le statut **Active** (vert) ✅

---

# 🚨 PARTIE 5 — Configurer la détection d'attaque

## 5.1 — Surveiller les logs du portail dans Wazuh

Pour détecter le brute-force, Wazuh doit lire les logs HTTP. Sur `srv-web-1`, configure l'agent pour surveiller les logs nginx :

```bash
sudo nano /var/ossec/etc/ossec.conf
```

Ajoute dans la section `<ossec_config>` :
```xml
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/nginx/access.log</location>
</localfile>
```

Redémarre l'agent :
```bash
sudo systemctl restart wazuh-agent
```

## 5.2 — Activer la règle brute-force (native Wazuh)

Wazuh a déjà des règles pour détecter les tentatives de connexion répétées. Sur le **manager Wazuh** (VM 201), vérifie que les règles web sont actives :

```bash
sudo nano /var/ossec/etc/rules/local_rules.xml
```

Ajoute une règle custom pour le portail (détecte 5+ échecs de login en 30s) :
```xml
<group name="nexamind,attack,">
  <rule id="100100" level="10" frequency="5" timeframe="30">
    <if_matched_sid>31151</if_matched_sid>
    <description>NexaMind: Possible brute-force sur le portail (5+ echecs en 30s)</description>
    <group>authentication_failures,</group>
  </rule>
</group>
```

Redémarre le manager :
```bash
sudo systemctl restart wazuh-manager
```

---

# ⚔️ PARTIE 6 — Lancer l'attaque (depuis Kali)

## 6.1 — Préparer l'attaque

Sur `srv-kali-1` (ou ta VM Debian avec hydra installé) :

```bash
# Vérifier que hydra est là
hydra -h

# Créer une petite liste de mots de passe pour la démo
echn -e "admin\npassword\n123456\nadmin123\nletmein\nqwerty" > passwords.txt
```

## 6.2 — Le scan de reconnaissance (optionnel mais joli)

```bash
# Scanner le serveur web
nmap -sV 192.168.20.50

# Scan de vulnérabilités web
nikto -h http://192.168.20.50:8000
```

## 6.3 — L'attaque brute-force

```bash
# Brute-force sur le formulaire de login du portail
hydra -l admin -P passwords.txt 192.168.20.50 -s 8000 \
  http-post-form "/login:username=^USER^&password=^PASS^:Invalid"
```

⏳ Hydra lance des dizaines de tentatives en quelques secondes.

## 6.4 — Test de détection

1. Pendant/après l'attaque, va sur le **dashboard Wazuh**
2. **Security Events** ou **Threat Hunting**
3. Tu dois voir des alertes "**NexaMind: Possible brute-force**" apparaître 🚨

🎉 **Si l'alerte apparaît → ta démo fonctionne de bout en bout !**

---

# 🤖 PARTIE 7 — Intégration API Claude (bonus différenciant)

## 7.1 — Récupérer une clé API

1. Va sur https://console.anthropic.com/
2. Crée un compte / connecte-toi
3. **API Keys** → **Create Key** → copie la clé (commence par `sk-ant-...`)

## 7.2 — Script d'analyse d'alerte

Sur `srv-web-1`, crée `analyze_alert.py` :

```python
import anthropic
import json
import sys

client = anthropic.Anthropic(api_key="TA_CLE_API")

def analyser_alerte(alerte_json):
    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=500,
        messages=[{
            "role": "user",
            "content": f"""Tu es un analyste SOC. Voici une alerte Wazuh au format JSON.
Donne en français, en 3 points courts :
1. Le type d'attaque détecté
2. Le niveau de criticité (faible/moyen/élevé/critique)
3. L'action recommandée

Alerte : {json.dumps(alerte_json)}"""
        }]
    )
    return message.content[0].text

if __name__ == "__main__":
    # Exemple d'alerte
    alerte = {
        "rule": {"description": "Possible brute-force sur le portail", "level": 10},
        "src_ip": "192.168.20.52",
        "timestamp": "2026-06-01T19:30:00",
        "attempts": 47
    }
    print(analyser_alerte(alerte))
```

Installe la lib et lance :
```bash
pip install anthropic
python3 analyze_alert.py
```

## 7.3 — Test API Claude

Tu dois voir une analyse en français du type :
```
1. Type d'attaque : Brute-force sur authentification
2. Criticité : Élevé
3. Action recommandée : Bloquer l'IP 192.168.20.52 via pfSense...
```

---

# ✅ PARTIE 8 — Checklist finale de validation

## Infrastructure
- [ ] `srv-web-1` (200) créé et accessible
- [ ] `srv-wazuh-1` (201) créé avec ressources suffisantes
- [ ] `srv-kali-1` (202) créé OU template Debian avec hydra

## Portail
- [ ] Portail accessible sur http://192.168.20.50:8000
- [ ] Page login fonctionnelle
- [ ] Service systemd actif (survit au reboot)

## SOC
- [ ] Wazuh dashboard accessible
- [ ] Agent Wazuh sur srv-web-1 → statut Active
- [ ] Logs nginx surveillés
- [ ] Règle brute-force activée

## Démo d'attaque
- [ ] Attaque hydra lancée depuis Kali
- [ ] Alerte brute-force visible dans Wazuh
- [ ] (Bonus) Analyse Claude de l'alerte fonctionne

## Documentation
- [ ] Tout documenté dans le repo Git (Obsidian)
- [ ] Mots de passe dans Passbolt
- [ ] Reporting hebdo à jour

---

# 📅 PARTIE 9 — Planning suggéré (semaine par semaine)

| Semaine | Objectif |
|---|---|
| **S23 (2-8 juin)** | Créer srv-web-1 + déployer le portail (login + dashboard) |
| **S24 (9-15 juin)** | Créer srv-wazuh-1 + installer Wazuh + agent sur web |
| **S25 (16-22 juin)** | Configurer détection + créer Kali + tester l'attaque |
| **S26 (23-29 juin)** | Intégrer API Claude + peaufiner le portail + rapport |
| **S27 (30 juin-6 juil)** | Répétitions démo + vidéo de secours + finitions |

⚠️ **Reporting tous les dimanches 23h59 !**

---

# 🆘 PARTIE 10 — En cas de problème

| Problème | Solution |
|---|---|
| VM ne démarre pas (erreur CPU) | Changer le type CPU en `x86-64-v2-AES` |
| Pas d'accès à une VM | Vérifier qu'on est connecté au VPN |
| Wazuh trop lourd / RAM saturée | Augmenter la RAM de la VM ou déployer en CT LXC |
| Portail inaccessible | Vérifier `systemctl status nexamind` + firewall pfSense |
| Agent Wazuh pas connecté | Vérifier l'IP du manager dans ossec.conf |
| Manque d'espace disque | Supprimer ISOs inutiles, faire du ménage (voir avec Abdoul) |

---

*Ce guide est ton fil conducteur. Suis-le brique par brique. Pour le CODE COMPLET du portail (qui est trop gros pour ce guide), demande-le moi et je te le génère en fichiers prêts à l'emploi.*
