# 📋 INDEX DU KIT NEXAMIND

> Liste complète de tout ce que contient ce kit. Navigue facilement.

---

## 📁 00-START-ICI (commence par là)

| Fichier | Description |
|---|---|
| `LISEZ-MOI-EN-PREMIER.md` | 👉 **Le point de départ** — vue d'ensemble du projet et du kit |
| `GUIDE-COMPLET-vue-globale.md` | Guide complet A→Z de tout le projet (toutes les briques) |
| `Comment-pousser-sur-Git.md` | Comment mettre le kit sur Git + travailler en équipe |

## 📁 01-Guide-Victor-Portail (mission Victor)

| Fichier | Description |
|---|---|
| `GUIDE-Portail-de-A-a-Z.md` | Tout pour construire et déployer le portail web |

## 📁 02-Guide-SOC-Wazuh (mission SOC)

| Fichier | Description |
|---|---|
| `GUIDE-SOC-Wazuh-de-A-a-Z.md` | Tout pour installer Wazuh + détection d'attaques |

## 📁 03-Guide-AD-Passbolt (mission Abdoul)

| Fichier | Description |
|---|---|
| `GUIDE-AD-Passbolt-de-A-a-Z.md` | Active Directory + Passbolt + structuration |

## 📁 04-Guide-Attaque-Demo (toute l'équipe)

| Fichier | Description |
|---|---|
| `GUIDE-Scenario-Attaque.md` | Le scénario d'attaque pour la soutenance |

## 📁 05-Schemas (toute l'équipe)

| Fichier | Description |
|---|---|
| `01-architecture-reseau.svg` | Schéma complet de l'infrastructure |
| `02-flux-attaque.svg` | Schéma du flux attaque → détection |

> 💡 Ouvre les .svg dans un navigateur pour les voir. Utilise-les dans le rapport.

## 📁 06-Code-Portail (le code prêt à lancer)

| Fichier | Description |
|---|---|
| `portail-nexamind/` | Le code complet du portail |
| `portail-nexamind/LANCER-WINDOWS.bat` | Double-clic pour lancer (Windows) |
| `portail-nexamind/LANCER-LINUX.sh` | Lancer sur Linux/Mac |
| `portail-nexamind/main.py` | Le serveur FastAPI |
| `portail-nexamind/templates/` | Les pages HTML |
| `portail-nexamind/README.md` | Doc technique du portail |

## 📁 07-Rapport-et-Reporting (toute l'équipe)

| Fichier | Description |
|---|---|
| `Template-Rapport-et-Reporting.md` | Structure du rapport 12 pages + template reporting hebdo |

## 📁 08-Procedures-Communes (toute l'équipe)

| Fichier | Description |
|---|---|
| `Acces-VPN.md` | Se connecter au VPN |
| `Cloner-une-VM.md` | Créer une VM depuis un template |
| `Liberer-espace-disque.md` | Gérer l'espace disque Proxmox |

---

## 🎯 Parcours recommandé selon ton rôle

### Si tu es Victor (portail)
1. `00-START-ICI/LISEZ-MOI-EN-PREMIER.md`
2. `01-Guide-Victor-Portail/GUIDE-Portail-de-A-a-Z.md`
3. `06-Code-Portail/` (lance le portail)
4. `08-Procedures-Communes/` (VPN, cloner VM)

### Si tu fais le SOC
1. `00-START-ICI/LISEZ-MOI-EN-PREMIER.md`
2. `02-Guide-SOC-Wazuh/GUIDE-SOC-Wazuh-de-A-a-Z.md`
3. `04-Guide-Attaque-Demo/` (pour tester la détection)

### Si tu es Abdoul (AD/infra)
1. `00-START-ICI/LISEZ-MOI-EN-PREMIER.md`
2. `03-Guide-AD-Passbolt/GUIDE-AD-Passbolt-de-A-a-Z.md`

### Tout le monde, avant la soutenance
- `04-Guide-Attaque-Demo/GUIDE-Scenario-Attaque.md` (la démo)
- `07-Rapport-et-Reporting/` (le rapport)

---

*Bon courage à toute l'équipe ! 🚀*
