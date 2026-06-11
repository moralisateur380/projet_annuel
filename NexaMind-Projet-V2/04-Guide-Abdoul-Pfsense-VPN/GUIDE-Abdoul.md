# 👤 GUIDE ABDOUL — pfSense + VPN + Réseau

> Ta mission : le réseau et la sécurité périmétrique.
> En grande partie déjà fait (pfSense + VPN marchent). Reste à affiner et documenter.
> VM concernée : srv-pfsense-ro (100).

---

## 🎯 Vue d'ensemble

pfSense est le **gardien** de l'infrastructure : il sépare Internet du réseau interne,
gère le VPN d'accès, et filtre le trafic.

```
Internet ──> pfSense (firewall + VPN) ──> LAN 192.168.20.0/24
                  │
                  └── VPN OpenVPN (10.10.10.0/24) pour l'accès admin
```

---

## ✅ Ce qui est déjà fait

- pfSense installé et fonctionnel (VM 100)
- 3 interfaces : WAN, intermédiaire, LAN
- VPN OpenVPN configuré (accès admin distant)
- Routes LAN poussées aux clients VPN (corrigé : champ "IPv4 Local Networks")

---

## 🔧 Ce qu'il reste à faire

### 1. Documenter la configuration

Pour le rapport, documenter :
- Les règles de firewall (WAN, LAN, OpenVPN)
- La config du VPN (serveur OpenVPN, certificats)
- Le plan de routage

### 2. Affiner les règles de firewall

Vérifier/créer les règles pour que :
- Les VM puissent communiquer entre elles sur le LAN
- Le SOC Wazuh (192.168.20.22) reçoive les logs des agents (ports 1514/1515)
- Seul le VPN permet l'accès admin (Proxmox, pfSense web)

### 3. Vérifier les communications inter-VM

Pour que le projet marche, ces flux doivent passer :

| De | Vers | Port | Pourquoi |
|---|---|---|---|
| Agents Wazuh | srv-wazuh-1 (192.168.20.22) | 1514, 1515 | Envoi des logs |
| srv-wazuh-1 | srv-web-1 (192.168.20.20) | 8000 | Remontée alertes au portail |
| Kali | srv-web-1 | 80 | Attaque de démo |
| Postes | srv-ad-1 (192.168.20.10) | 389, 88, 53 | Authentification AD |

→ Vérifier dans **Firewall → Rules → LAN** que ces flux sont autorisés.

---

## 📍 Accès à pfSense

```
https://192.168.20.1/    (via VPN)
```
Identifiants dans Passbolt → pfSense.

---

## 📍 Vérifier la config OpenVPN

Le point qui avait posé problème :
1. **VPN → OpenVPN → Servers → Edit**
2. Section *Tunnel Settings*
3. Champ **"IPv4 Local Network/s"** doit contenir `192.168.20.0/24`
4. **Firewall → Rules → OpenVPN** : une règle "Pass" autorisant le trafic du tunnel vers le LAN

---

## 📍 Distribuer les profils VPN

Chaque membre a besoin de son profil `.ovpn` :
1. **VPN → OpenVPN → Client Export**
2. Générer un profil par utilisateur (victor, jacques, abdoul, marwane)
3. Distribuer via Passbolt (jamais en clair)

---

## ✅ CHECKLIST DE TA MISSION

- [ ] pfSense documenté (règles, VPN, routage)
- [ ] Règles firewall vérifiées pour les flux du projet
- [ ] Communication Wazuh ↔ agents OK (1514/1515)
- [ ] Communication Wazuh ↔ portail OK (8000)
- [ ] Profils VPN générés pour les 4 membres
- [ ] Profils distribués via Passbolt

---

## 🎤 Ton rôle en soutenance (vers 3-8 min)

1. Présente l'architecture réseau (montre le schéma)
2. Explique pfSense : firewall, séparation WAN/LAN
3. Explique le VPN : pourquoi, comment on accède à l'infra
4. Montre les règles de filtrage

Tu poses les **fondations** que tout le reste utilise.

---

## 🆘 Dépannage

| Problème | Solution |
|---|---|
| VPN connecté mais pas d'accès LAN | Champ "IPv4 Local Networks" manquant |
| VM ne communiquent pas | Vérifier les règles Firewall → LAN |
| Agent Wazuh ne joint pas le manager | Ouvrir ports 1514/1515 sur le LAN |
| pfSense inaccessible | Console KVM via Proxmox → option reset |

---

*Le réseau est la fondation. Sans toi, rien ne communique. 🌐*
