# 📋 INDEX DU KIT NEXAMIND

> Tout le contenu du kit, organisé. Commence par `00-DEMARRAGE/LIRE-EN-PREMIER.md`.

---

## 📁 Structure complète

```
NexaMind-Projet-Complet/
│
├── 00-DEMARRAGE/
│   ├── LIRE-EN-PREMIER.md              ← COMMENCE ICI
│   └── Comment-pousser-sur-Github.md   (pour Victor)
│
├── 01-Infra-et-Reseau/
│   └── PLAN-ADRESSAGE.md               ← toutes les VM + IPs
│
├── 02-Guide-Victor-Web-SOC/
│   └── GUIDE-Victor.md                 (portail + Wazuh)
│
├── 03-Guide-Jacques-AD-Windows/
│   └── GUIDE-Jacques.md                (Active Directory + Windows)
│
├── 04-Guide-Abdoul-Pfsense-VPN/
│   └── GUIDE-Abdoul.md                 (firewall + VPN)
│
├── 05-Guide-Marwane-Passbolt-Attaque/
│   └── GUIDE-Marwane.md                (Passbolt + Suricata + Kali)
│
├── 06-Scripts-Configuration/
│   ├── LISEZ-MOI-scripts.md            ← quel script où
│   ├── PROCEDURE-cloner-vm.md
│   ├── install-wazuh-docker.sh         (Victor, fait)
│   ├── agrandir-docker.sh              (Victor, fait)
│   ├── detection-1-serveur-web.sh      (Victor, fait)
│   ├── detection-2-manager-wazuh.sh    (Victor, fait)
│   ├── installer-agent-wazuh.sh        (étendre la surveillance)
│   ├── config-active-directory.sh      (Jacques)
│   ├── config-suricata.sh              (Marwane)
│   └── attaque-test.sh                 (Marwane, pour la démo)
│
├── 07-Code-Portail/
│   └── portail-nexamind/               ← le code complet (testé)
│       ├── main.py
│       ├── templates/
│       ├── LANCER-WINDOWS.bat
│       └── LANCER-LINUX.sh
│
├── 08-Schemas/
│   ├── 01-architecture-reseau.png/svg  ← vue d'ensemble
│   └── 02-flux-attaque.png/svg         ← détection
│
├── 09-Scenario-Demo/
│   └── SCENARIO-Soutenance.md          ← déroulé 35 min
│
└── 10-Rapport-Reporting/
    └── Template-Rapport-Reporting.md   ← rapport 12 pages + reporting
```

---

## 🎯 Parcours selon ton rôle

### Victor (toi)
1. `00-DEMARRAGE/LIRE-EN-PREMIER.md`
2. `02-Guide-Victor-Web-SOC/` (ta partie, déjà faite)
3. `00-DEMARRAGE/Comment-pousser-sur-Github.md` (pousser le kit)

### Jacques
1. `00-DEMARRAGE/LIRE-EN-PREMIER.md`
2. `03-Guide-Jacques-AD-Windows/`
3. Script : `06-Scripts-Configuration/config-active-directory.sh`

### Abdoul
1. `00-DEMARRAGE/LIRE-EN-PREMIER.md`
2. `04-Guide-Abdoul-Pfsense-VPN/`

### Marwane
1. `00-DEMARRAGE/LIRE-EN-PREMIER.md`
2. `05-Guide-Marwane-Passbolt-Attaque/`
3. Scripts : `config-suricata.sh`, `attaque-test.sh`

### Tous, avant la soutenance
- `09-Scenario-Demo/SCENARIO-Soutenance.md`
- `10-Rapport-Reporting/`

---

## ✅ État du projet (résumé)

| Brique | Responsable | État |
|---|---|---|
| Portail web | Victor | ✅ Fait |
| SOC Wazuh | Victor | ✅ Fait |
| Active Directory | Jacques | 🟡 À faire |
| Poste Windows | Jacques | 🟡 À faire |
| pfSense + VPN | Abdoul | ✅ Fait, à documenter |
| Passbolt | Marwane | 🟡 À remplir |
| Suricata | Marwane | 🟡 À faire |
| Machine Kali | Marwane | 🟡 À créer |
| IA Claude | Victor | 🟡 Clé API à brancher |

---

*Bon courage à toute l'équipe ! Chacun sa brique. 🛡️*
