# 🚀 PROJET NEXAMIND — DÉMARRAGE (LIRE EN PREMIER)

> Entreprise fictive de cybersécurité **NexaMind SAS** (Lille).
> Projet annuel ESGI 4e année · Soutenance juillet 2026 (35 min, projet EN PROD).
> Équipe : **Victor, Jacques, Abdoul, Marwane**.

---

## 👥 L'équipe et les missions

| Membre | Mission | Dossier guide |
|---|---|---|
| **Victor** | Portail web + SOC Wazuh | `02-Guide-Victor-Web-SOC` |
| **Jacques** | Active Directory + poste Windows | `03-Guide-Jacques-AD-Windows` |
| **Abdoul** | pfSense + VPN + réseau | `04-Guide-Abdoul-Pfsense-VPN` |
| **Marwane** | Passbolt + Suricata + machine d'attaque | `05-Guide-Marwane-Passbolt-Attaque` |

---

## 🗺️ État actuel du projet (au 11 juin 2026)

| VM ID | Nom | Rôle | Responsable | État |
|---|---|---|---|---|
| 100 | srv-pfsense-ro | Firewall + VPN | Abdoul | ✅ Fonctionne |
| 103 | srv-passbolt-1 | Coffre mots de passe | Marwane | ✅ Existe, à remplir |
| 104 | srv-ad-1 | Active Directory | Jacques | 🟡 Existe, à configurer |
| 105 | win10-tempon | Windows de test | équipe | 🟡 À clarifier/utiliser |
| 106 | client-win-1 | Poste client Windows | Jacques | 🟡 À joindre au domaine |
| 107 | srv-soc-1 | Suricata (IDS réseau) | Marwane | 🟡 À configurer |
| 200 | srv-web-1 | Portail NexaMind | Victor | ✅ **Fonctionne** |
| 201 | srv-wazuh-1 | SOC Wazuh | Victor | ✅ **Fonctionne** |
| 110 | ct-test | Conteneur de test | équipe | 🧪 Test |
| 101 | srv-debian-template | Template Debian | Victor | ✅ Template |
| 102 | srv-win10-template | Template Windows | Victor | ✅ Template |

**Légende** : ✅ fait · 🟡 à faire/finir · 🧪 test

---

## ⚡ Ce qui marche DÉJÀ (la partie Victor)

- ✅ Le **portail web NexaMind** tourne sur srv-web-1 (FastAPI + nginx)
- ✅ **Wazuh (SOC)** tourne sur srv-wazuh-1 (Docker)
- ✅ L'**agent Wazuh** surveille srv-web-1
- ✅ Les **règles de détection** brute-force sont actives
- ✅ Une **attaque de test** a été détectée par Wazuh (prouvé !)

**La chaîne attaque → détection fonctionne déjà.** Le reste, c'est compléter l'infra autour.

---

## 🎯 Ce qu'il reste à faire (vue d'ensemble)

### Jacques — Active Directory + Windows
- Remplir l'AD (utilisateurs, groupes, OU)
- Créer des GPO de sécurité
- Joindre le poste Windows au domaine
- Activer l'audit des connexions (pour Wazuh)

### Abdoul — Réseau (en grande partie fait)
- Documenter pfSense et le VPN
- Affiner les règles de firewall
- Vérifier les routes inter-VLAN

### Marwane — Passbolt + Suricata + Attaque
- Remplir Passbolt avec tous les mots de passe
- Configurer Suricata (IDS) sur srv-soc-1
- Créer la machine d'attaque (Kali)

### Victor — Finitions (presque fini)
- Brancher l'IA Claude sur le portail
- Étendre Wazuh aux autres VM (agents sur AD, Windows)

### Ensemble
- Répéter le scénario de démo
- Préparer le rapport + la vidéo de secours

---

## 📂 Comment utiliser ce kit

1. **Chacun lit ce document** (00-DEMARRAGE)
2. **Chacun va dans SON dossier guide** (02, 03, 04 ou 05)
3. Les **scripts de configuration** sont dans `06-Scripts-Configuration`
4. Les **schémas** (à mettre dans le rapport) sont dans `08-Schemas`
5. Le **scénario de démo** est dans `09-Scenario-Demo`
6. Le **rapport et reporting** dans `10-Rapport-Reporting`

---

## 🔗 Accès rapides

| Ressource | Adresse |
|---|---|
| Proxmox | https://192.168.20.254:8006 (via VPN) |
| Portail NexaMind | http://192.168.20.20 |
| Wazuh dashboard | https://192.168.20.22 |
| Passbolt | https://192.168.20.XX (à compléter) |
| Active Directory | 192.168.20.10 |

> ⚠️ Tout est accessible uniquement **via le VPN OpenVPN**. Voir `04-Guide-Abdoul-Pfsense-VPN`.

---

*Projet construit en équipe. Chacun sa brique, et ensemble ça fait une vraie entreprise cyber. 🛡️*
