# 👤 GUIDE MARWANE — Passbolt + Suricata + Machine d'attaque

> Ta mission a 3 volets : le coffre-fort (Passbolt), l'IDS réseau (Suricata
> sur srv-soc-1), et la machine qui lancera les attaques de démo (Kali).
> VM concernées : srv-passbolt-1 (103), srv-soc-1 (107), + nouvelle VM Kali.

---

## 🎯 Vue d'ensemble de tes 3 missions

1. **Passbolt** = ranger tous les mots de passe de l'équipe au même endroit (sécurisé)
2. **Suricata** = un 2e système de détection qui surveille le RÉSEAU (complète Wazuh)
3. **Kali** = la machine "attaquante" pour la démo de soutenance

---

# 🔐 MISSION 1 — Passbolt (srv-passbolt-1, VM 103)

Passbolt est déjà installé. Ton job : le remplir et inviter l'équipe.

## Étape 1 — Inviter l'équipe
Sur Passbolt (https://192.168.20.XX, en admin) :
1. Users → **Add User**
2. Inviter Victor, Jacques, Abdoul (avec leurs emails)
3. Chacun reçoit un mail pour configurer son compte + sa clé

## Étape 2 — Organiser les coffres
Créer des dossiers :
- `Infra/` (Proxmox, pfSense)
- `VPN/` (les profils OpenVPN)
- `Services/` (AD, Wazuh, Passbolt, Portail)
- `Templates/` (mots de passe des templates)

## Étape 3 — Migrer TOUS les mots de passe
Pour chaque accès du projet, créer une entrée Passbolt :
- Proxmox root
- VPN (chaque user)
- Wazuh admin
- Portail admin
- AD administrator
- etc.

⚠️ Une fois migré : **supprimer les mots de passe de Discord !**

---

# 🛡️ MISSION 2 — Suricata sur srv-soc-1 (VM 107)

Suricata est un **IDS** (système de détection d'intrusion) qui analyse le **trafic réseau**.
Il complète Wazuh (qui analyse les logs). Ensemble = SOC complet.

```
Wazuh   = analyse les LOGS (qui s'est connecté, échecs...)
Suricata = analyse le RÉSEAU (paquets, scans, exploits...)
```

## Installation
Un script tout prêt → `06-Scripts-Configuration/config-suricata.sh`

En résumé, sur srv-soc-1 :
```bash
su -
apt update && apt install -y suricata
suricata-update          # télécharge les règles de détection
systemctl enable --now suricata
```

## Vérifier
```bash
systemctl status suricata
tail -f /var/log/suricata/eve.json    # voir les détections en direct
```

## (Bonus) Connecter Suricata à Wazuh
Suricata peut envoyer ses détections à Wazuh pour tout centraliser.
Voir le script de config. C'est un plus pour la démo.

---

# ⚔️ MISSION 3 — Machine d'attaque Kali

C'est la machine qui jouera "l'attaquant" pendant la démo.

## Option A — Kali complet
1. Télécharger l'ISO : https://www.kali.org/get-kali/
2. Proxmox → upload ISO → créer VM (ID 202, nom srv-kali-1)
3. Config : 2 cores, 2 Go RAM, 30 Go disque, bridge vmbr2
4. Installer Kali (tous les outils inclus : hydra, nmap, nikto...)

## Option B — Plus léger (Debian + outils)
Cloner le template Debian et installer juste les outils :
```bash
apt install -y hydra nmap nikto
```

→ Procédure de clone : `06-Scripts-Configuration/PROCEDURE-cloner-vm.md`

## Le script d'attaque
Un script tout prêt → `06-Scripts-Configuration/attaque-test.sh`
Il lance un brute-force sur le portail pour tester la détection Wazuh.

---

## ✅ CHECKLIST DE TES MISSIONS

### Passbolt
- [ ] Équipe invitée
- [ ] Dossiers organisés
- [ ] Tous les mots de passe migrés
- [ ] Mots de passe supprimés de Discord

### Suricata
- [ ] Suricata installé sur srv-soc-1
- [ ] Règles téléchargées (suricata-update)
- [ ] Service actif
- [ ] (Bonus) Connecté à Wazuh

### Kali
- [ ] Machine d'attaque créée
- [ ] Outils dispo (hydra, nmap)
- [ ] Script d'attaque testé

---

## 🎤 Ton rôle en soutenance

1. **Passbolt** : montre comment l'équipe gère ses secrets proprement
2. **Suricata** : montre la détection réseau (complément de Wazuh)
3. **L'attaque** : c'est TOI qui lances l'attaque depuis Kali pendant la démo live !

Tu es l'attaquant ET le gardien des secrets. Double rôle stylé. 😎

---

## 🆘 Dépannage

| Problème | Solution |
|---|---|
| Passbolt inaccessible | Vérifier VPN + VM 103 démarrée |
| Suricata ne capture rien | Vérifier l'interface réseau écoutée (eth0) |
| Kali rame | Réduire à l'option Debian + outils |
| hydra ne trouve pas la cible | Vérifier que Kali est sur vmbr2 + VPN |

---

*Trois missions, trois compétences : gestion des secrets, détection réseau, et red team. 🔐🛡️⚔️*
