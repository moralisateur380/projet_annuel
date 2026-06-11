# 🚀 KIT PROJET NEXAMIND — COMMENCE ICI

> **Bienvenue !** Ce kit contient TOUT ce qu'il faut pour mener le projet NexaMind de A à Z.
> Chaque membre de l'équipe a sa partie. Lis ce document en premier, puis va voir TON guide.

---

## 📂 Comment ce kit est organisé

| Dossier | Pour qui | Contenu |
|---|---|---|
| **00-START-ICI** | 👥 Toute l'équipe | Ce document + le plan global + la répartition |
| **01-Guide-Victor-Portail** | 👤 Victor | Construire le portail web NexaMind |
| **02-Guide-SOC-Wazuh** | 👤 Personne SOC | Installer Wazuh + Suricata + détection |
| **03-Guide-AD-Passbolt** | 👤 Abdoul | Active Directory + Passbolt (déjà fait) |
| **04-Guide-Attaque-Demo** | 👥 Toute l'équipe | Le scénario d'attaque pour la soutenance |
| **05-Schemas** | 👥 Toute l'équipe | Tous les schémas réseau/architecture |
| **06-Code-Portail** | 👤 Victor | Le code complet du portail (prêt à lancer) |
| **07-Rapport-et-Reporting** | 👥 Toute l'équipe | Template rapport 12 pages + reporting hebdo |
| **08-Procedures-Communes** | 👥 Toute l'équipe | Cloner une VM, accès VPN, Git, Passbolt... |

---

## 🎯 Le projet en 30 secondes

Vous simulez **NexaMind SAS**, une entreprise de cybersécurité fictive qui vend des audits de sécurité.
Vous devez construire :
1. **L'infrastructure** (Proxmox + pfSense + AD + Passbolt) — *en grande partie fait*
2. **Le SOC** (Wazuh + Suricata) — *à faire*
3. **Le portail client** (site web) — *à faire*
4. **Une démo d'attaque** (attaque → détection → alerte) — *à faire*

**Soutenance** : juillet 2026, 35 min, le projet doit être **EN PROD**.

---

## 👥 Répartition des missions

| Membre | Mission principale | Dossier guide |
|---|---|---|
| **Abdoul** | Infra (Proxmox, pfSense) + AD Samba + Passbolt | `03-Guide-AD-Passbolt` |
| **Victor** | Portail client NexaMind | `01-Guide-Victor-Portail` + `06-Code-Portail` |
| **Personne C** | SOC : Wazuh + Suricata + détection | `02-Guide-SOC-Wazuh` |
| **Personne D** | API Claude + support démo attaque | `04-Guide-Attaque-Demo` |

> ⚠️ **À ajuster selon votre vraie répartition.** Discutez-en en réunion et mettez les bons noms.

---

## 📅 Planning global (5 semaines avant soutenance)

```
SEMAINE 23 (2-8 juin)    │ Chacun démarre sa brique en local
SEMAINE 24 (9-15 juin)   │ Déploiement sur le serveur + intégration
SEMAINE 25 (16-22 juin)  │ Scénario d'attaque + tests bout-en-bout
SEMAINE 26 (23-29 juin)  │ Rapport + finitions + API Claude
SEMAINE 27 (30 juin-6 j) │ Répétitions soutenance + vidéo de secours
```

⚠️ **REPORTING tous les dimanches 23h59** — sanction au 2e retard !

---

## 🗺️ L'état actuel de l'infra (au 1er juin 2026)

| VM ID | Nom | Rôle | État |
|---|---|---|---|
| 100 | srv-pfsense-ro | Firewall + VPN | ✅ OK |
| 101 | srv-debian-template | Template Debian | ✅ Template |
| 102 | srv-win10-template | Template Windows | ✅ Template |
| 103 | srv-passbolt-1 | Coffre mots de passe | ✅ OK |
| 104 | srv-ad-1 | Active Directory | ✅ OK |
| 105 | win10-tempon | Windows test | 🟡 À clarifier |
| 106 | client-win-1 | Poste client | ✅ OK |
| **200** | **srv-web-1** | **Portail web** | 🔴 **À créer** |
| **201** | **srv-wazuh-1** | **SOC Wazuh** | 🔴 **À créer** |
| **202** | **srv-kali-1** | **Attaque** | 🔴 **À créer** |

---

## ✅ Par où commencer (checklist du jour 1)

Pour CHAQUE membre :

1. [ ] Lire ce document (00-START-ICI)
2. [ ] Lire SON guide perso (01, 02, 03 ou 04)
3. [ ] Vérifier son accès VPN (voir `08-Procedures-Communes/Acces-VPN.md`)
4. [ ] Vérifier son accès Proxmox
5. [ ] Vérifier son compte Passbolt
6. [ ] Lire les procédures communes (cloner une VM, Git...)
7. [ ] Commencer sa première tâche

---

## 🔗 Liens essentiels

| Ressource | URL |
|---|---|
| Proxmox | https://192.168.20.254:8006/ (via VPN) |
| Repo Git | (votre URL GitHub) |
| Passbolt | https://srv-passbolt-1/ (via VPN) |
| Discord équipe | (votre serveur) |
| Console Anthropic (API Claude) | https://console.anthropic.com/ |

---

*Ce kit a été préparé pour structurer le projet. Bonne construction ! 🛠️*
