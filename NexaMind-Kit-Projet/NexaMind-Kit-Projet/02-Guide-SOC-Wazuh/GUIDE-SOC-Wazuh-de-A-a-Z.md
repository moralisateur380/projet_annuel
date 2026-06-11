# 👤 GUIDE SOC — Wazuh + Suricata + Détection (de A à Z)

> **Mission** : construire le SOC (Security Operations Center) de NexaMind.
> C'est le cœur "cyber" du projet : détecter les attaques et générer des alertes.
> **Suis ce guide dans l'ordre.**

---

# 🎯 Vue d'ensemble de la mission SOC

Tu construis le système qui **surveille et détecte les attaques** :

```
[Serveurs surveillés]──logs──> [Wazuh Manager]──alertes──> [Dashboard + Portail]
   (web, AD, etc.)                  (analyse)
        ▲
        │ trafic réseau
   [Suricata IDS]
```

Ce que tu vas faire :
1. ✅ Créer une VM `srv-wazuh-1`
2. ✅ Installer Wazuh (SIEM + dashboard)
3. ✅ Installer des agents Wazuh sur les serveurs à surveiller
4. ✅ Configurer la détection de brute-force
5. ✅ (Bonus) Installer Suricata pour la détection réseau
6. ✅ Envoyer les alertes vers le portail NexaMind

---

# 📍 ÉTAPE 1 — Créer la VM Wazuh (srv-wazuh-1)

## 1.1 — Vérifier les ressources

⚠️ **Wazuh est GOURMAND**. Minimum requis :
- **RAM** : 4 Go (idéalement 6 Go)
- **CPU** : 2 cores
- **Disque** : 50 Go

Vérifie sur Proxmox (`srv-prox-01` → Summary) qu'il reste assez de RAM et de disque.
Si trop juste → voir `08-Procedures-Communes/Liberer-espace-disque.md`.

## 1.2 — Cloner le template Debian

1. **Clic droit sur `101 (srv-debian-template)`** → **Clone**
2. Paramètres :

| Champ | Valeur |
|---|---|
| VM ID | `201` |
| Name | `srv-wazuh-1` |
| Mode | `Full Clone` |
| Storage | `local` |

3. **Clone**

## 1.3 — Augmenter les ressources

Avant de démarrer, sur la VM 201 :
1. Onglet **Hardware** → double-clic **Memory** → `4096` (ou `6144`)
2. **Processors** → `2` cores
3. **Hard Disk** → clic → **Disk Action** → **Resize** → `+30G`

## 1.4 — Première config

Démarre la VM, ouvre la Console, connecte-toi (`nexa` / `NexaMind2026!`) :

```bash
su -
systemd-machine-id-setup
dpkg-reconfigure openssh-server
hostnamectl set-hostname srv-wazuh-1
ip a    # NOTE l'IP (genre 192.168.20.51)
apt update && apt upgrade -y
```

📝 Note l'IP de srv-wazuh-1.

---

# 📍 ÉTAPE 2 — Installer Wazuh

## 2.1 — Installation automatique

Sur srv-wazuh-1, en root :

```bash
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
sudo bash ./wazuh-install.sh -a
```

⏳ Ça installe le manager + indexer + dashboard. **Compte 15-20 min.**

À la fin, le script affiche :
```
INFO: --- Summary ---
INFO: You can access the web interface https://<IP>
    User: admin
    Password: <MOT_DE_PASSE_GÉNÉRÉ>
```

📝 **NOTE CE MOT DE PASSE** et mets-le dans Passbolt !

## 2.2 — Accéder au dashboard

Depuis ton PC (VPN) :
```
https://192.168.20.51/
```
*(IP de srv-wazuh-1)*

Login : `admin` / le mot de passe généré.

⚠️ Avertissement certificat → Avancé → Continuer.

## 2.3 — Test
- Le dashboard Wazuh s'affiche ✅
- Va dans **Agents** → 0 agent pour l'instant (normal)

---

# 📍 ÉTAPE 3 — Installer les agents Wazuh

Les agents tournent sur les serveurs à surveiller et envoient leurs logs à Wazuh.

## 3.1 — Agent sur le serveur web (srv-web-1)

Sur **srv-web-1** (la VM de Victor, 200) :

```bash
WAZUH_MANAGER="192.168.20.51"   # IP de srv-wazuh-1
curl -sO https://packages.wazuh.com/4.9/wazuh-agent_4.9.0-1_amd64.deb
sudo WAZUH_MANAGER="192.168.20.51" dpkg -i ./wazuh-agent_4.9.0-1_amd64.deb
sudo systemctl daemon-reload
sudo systemctl enable --now wazuh-agent
```

## 3.2 — Agent sur l'Active Directory (srv-ad-1)

Pareil sur **srv-ad-1** (VM 104) pour surveiller les connexions AD :
```bash
WAZUH_MANAGER="192.168.20.51"
curl -sO https://packages.wazuh.com/4.9/wazuh-agent_4.9.0-1_amd64.deb
sudo WAZUH_MANAGER="192.168.20.51" dpkg -i ./wazuh-agent_4.9.0-1_amd64.deb
sudo systemctl daemon-reload
sudo systemctl enable --now wazuh-agent
```

## 3.3 — Vérification

Sur le dashboard Wazuh → **Agents** → tu dois voir `srv-web-1` et `srv-ad-1`
avec le statut **Active** (vert) ✅

---

# 📍 ÉTAPE 4 — Configurer la détection de brute-force

## 4.1 — Surveiller les logs du portail

Sur **srv-web-1**, dis à l'agent de lire les logs du portail.

D'abord, il faut que le portail logge les tentatives. Le portail FastAPI logge déjà
les requêtes. Pour une vraie détection, on ajoute nginx devant le portail (reverse proxy)
qui génère un access.log standard :

```bash
# Sur srv-web-1
sudo apt install -y nginx
sudo nano /etc/nginx/sites-available/nexamind
```

Colle :
```nginx
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Active :
```bash
sudo ln -s /etc/nginx/sites-available/nexamind /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
```

Maintenant le portail est accessible sur le **port 80** (via nginx) et nginx logge tout dans `/var/log/nginx/access.log`.

## 4.2 — Dire à Wazuh de lire ce log

Sur srv-web-1 :
```bash
sudo nano /var/ossec/etc/ossec.conf
```

Ajoute dans `<ossec_config>` :
```xml
<localfile>
  <log_format>apache</log_format>
  <location>/var/log/nginx/access.log</location>
</localfile>
```

Redémarre l'agent :
```bash
sudo systemctl restart wazuh-agent
```

## 4.3 — Créer la règle de détection

Sur le **manager Wazuh** (srv-wazuh-1) :
```bash
sudo nano /var/ossec/etc/rules/local_rules.xml
```

Ajoute :
```xml
<group name="nexamind,attack,">
  <!-- Détecte 6+ requêtes 401/403 (échecs login) en 30 secondes depuis la même IP -->
  <rule id="100100" level="10" frequency="6" timeframe="30">
    <if_matched_sid>31151</if_matched_sid>
    <same_source_ip />
    <description>NexaMind: Brute-force détecté sur le portail web</description>
    <group>authentication_failures,attack,</group>
  </rule>
</group>
```

Redémarre le manager :
```bash
sudo systemctl restart wazuh-manager
```

---

# 📍 ÉTAPE 5 — Envoyer les alertes vers le portail NexaMind

Wazuh peut appeler une URL quand une alerte se déclenche (integration custom).

## 5.1 — Créer le script d'intégration

Sur srv-wazuh-1 :
```bash
sudo nano /var/ossec/integrations/custom-nexamind.py
```

Colle :
```python
#!/usr/bin/env python3
import sys, json, requests

alert_file = sys.argv[1]
with open(alert_file) as f:
    alert = json.load(f)

# Mapper le niveau Wazuh vers le portail
level = alert.get("rule", {}).get("level", 0)
niveau = "critique" if level >= 10 else "moyen" if level >= 7 else "faible"

payload = {
    "niveau": niveau,
    "source": alert.get("data", {}).get("srcip", "inconnu"),
    "description": alert.get("rule", {}).get("description", "Alerte Wazuh"),
}

# IP du portail (srv-web-1)
requests.post("http://192.168.20.50:8000/api/alerte", json=payload, timeout=5)
```

Rends-le exécutable :
```bash
sudo chmod +x /var/ossec/integrations/custom-nexamind.py
sudo chmod 750 /var/ossec/integrations/custom-nexamind.py
sudo chown root:wazuh /var/ossec/integrations/custom-nexamind.py
```

## 5.2 — Activer l'intégration

```bash
sudo nano /var/ossec/etc/ossec.conf
```

Ajoute :
```xml
<integration>
  <name>custom-nexamind.py</name>
  <level>7</level>
  <alert_format>json</alert_format>
</integration>
```

Redémarre :
```bash
sudo systemctl restart wazuh-manager
```

Maintenant, chaque alerte de niveau ≥ 7 sera envoyée au portail NexaMind. 🎉

---

# 📍 ÉTAPE 6 (BONUS) — Suricata (IDS réseau)

Si tu as le temps, Suricata détecte les attaques au niveau réseau.

```bash
# Sur srv-wazuh-1 (ou une VM dédiée)
sudo apt install -y suricata
sudo suricata-update
sudo systemctl enable --now suricata
```

Puis dire à Wazuh de lire les logs Suricata :
```bash
sudo nano /var/ossec/etc/ossec.conf
```
```xml
<localfile>
  <log_format>json</log_format>
  <location>/var/log/suricata/eve.json</location>
</localfile>
```

---

# ✅ CHECKLIST DE LA MISSION SOC

- [ ] VM srv-wazuh-1 créée avec ressources suffisantes (4+ Go RAM)
- [ ] Wazuh installé, dashboard accessible
- [ ] Mot de passe admin Wazuh dans Passbolt
- [ ] Agent Wazuh sur srv-web-1 → Active
- [ ] Agent Wazuh sur srv-ad-1 → Active
- [ ] nginx installé devant le portail (logs access.log)
- [ ] Règle brute-force créée
- [ ] Intégration vers le portail configurée
- [ ] (Bonus) Suricata installé
- [ ] Testé : une attaque génère une alerte visible

---

# 🎤 Ton rôle en soutenance (le moment fort !)

C'est TOI qui fais la démo live de détection (vers 13-20 min) :
1. Montre le dashboard Wazuh (les agents connectés)
2. **Lance l'attaque** depuis Kali (voir `04-Guide-Attaque-Demo`)
3. **En direct**, montre l'alerte qui apparaît dans Wazuh
4. Montre qu'elle remonte aussi dans le portail NexaMind

**C'est le climax de la démo.** Prépare une vidéo de secours au cas où le live plante.

---

# 🆘 Dépannage

| Problème | Solution |
|---|---|
| Wazuh trop lent / VM rame | Augmenter la RAM, ou désactiver des modules |
| Agent pas "Active" | Vérifier l'IP du manager dans ossec.conf + firewall pfSense (port 1514/1515) |
| Pas d'alerte générée | Vérifier que les logs arrivent (Discover dans le dashboard) |
| Install Wazuh échoue | Vérifier RAM (min 4 Go) et espace disque |
| Intégration portail KO | Vérifier que requests est installé : `pip install requests` |

---

*Le SOC est le cœur technique du projet. Prends le temps de bien le configurer. 🛡️*
