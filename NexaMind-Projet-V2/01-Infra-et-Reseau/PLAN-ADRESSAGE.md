# 🌐 INFRASTRUCTURE & PLAN D'ADRESSAGE

> Architecture réseau complète du projet NexaMind.
> Toutes les VM, leurs IPs, leurs rôles.

---

## Le serveur physique

| Élément | Valeur |
|---|---|
| Hébergeur | OVH Kimsufi |
| Nom serveur | ns3138292.ip-51-77-52.eu |
| IP publique | 51.77.52.56 |
| Région | eu-central-waw (Varsovie) |
| Hyperviseur | Proxmox VE 9.1.9 |
| Node | srv-prox-01 |
| Disque | 2 × 2 To (~1.9 To utile sur le storage local) |
| RAM | 32 Go |
| CPU | Xeon E3-1270v6 (4c/8t) |

---

## Les réseaux (bridges Proxmox)

| Bridge | Réseau | Rôle |
|---|---|---|
| `vmbr0` | WAN | Connexion Internet (pfSense WAN) |
| `vmbr1` | 192.168.10.0/24 | Réseau intermédiaire (entre Proxmox et pfSense) |
| `vmbr2` | 192.168.20.0/24 | **LAN principal** (toutes les VM de service) |
| (tunnel) | 10.10.10.0/24 | Réseau VPN OpenVPN |

> ⚠️ **Règle importante** : toutes les VM de service vont sur `vmbr2` (LAN).

---

## 📋 PLAN D'ADRESSAGE COMPLET

| VM ID | Nom | IP | Rôle | Responsable |
|---|---|---|---|---|
| 100 | srv-pfsense-ro | 192.168.20.1 | Firewall + VPN (passerelle) | Abdoul |
| 103 | srv-passbolt-1 | 192.168.20.___ | Coffre mots de passe | Marwane |
| 104 | srv-ad-1 | 192.168.20.10 | Active Directory | Jacques |
| 105 | win10-tempon | 192.168.20.___ | Windows test | équipe |
| 106 | client-win-1 | 192.168.20.___ | Poste client Windows | Jacques |
| 107 | srv-soc-1 | 192.168.20.___ | Suricata (IDS réseau) | Marwane |
| 200 | srv-web-1 | 192.168.20.20 | Portail NexaMind | Victor |
| 201 | srv-wazuh-1 | 192.168.20.22 | SOC Wazuh | Victor |
| - | Proxmox | 192.168.20.254 | Hyperviseur (admin) | - |

> 📝 **Les `___` sont à compléter à la main** avec les vraies IPs (regarder dans pfSense → DHCP leases, ou faire `ip a` sur chaque VM).

---

## Plan de nommage

Convention : `srv-<role>-<numero>` pour les serveurs, `client-<os>-<numero>` pour les postes.

| Préfixe | Signification | Exemple |
|---|---|---|
| `srv-` | Serveur | srv-web-1, srv-ad-1 |
| `client-` | Poste client | client-win-1 |
| `ct-` | Conteneur LXC | ct-test |
| `-template` | Modèle à cloner | srv-debian-template |

---

## Domaine Active Directory

| Élément | Valeur |
|---|---|
| Domaine | cybernest.local |
| Contrôleur | srv-ad-1 (192.168.20.10) |
| Type | Samba AD DC |

---

## Comptes et accès (emplacements, PAS les mots de passe)

> 🔐 Les mots de passe sont dans **Passbolt**, jamais dans ce dépôt.

| Service | URL/Hôte | User | Mot de passe dans |
|---|---|---|---|
| Proxmox | https://192.168.20.254:8006 | root@pam | Passbolt → Infra |
| Portail | http://192.168.20.20 | admin | Passbolt → Web |
| Wazuh | https://192.168.20.22 | admin | Passbolt → SOC |
| VPN | profils .ovpn | (par user) | Passbolt → VPN |
| AD | 192.168.20.10 | administrator | Passbolt → AD |

---

## Templates (pour cloner de nouvelles VM)

| Template | VM ID | OS | Usage |
|---|---|---|---|
| srv-debian-template | 101 | Debian 13 | Services Linux |
| srv-win10-template | 102 | Windows 10 Pro 22H2 | Postes Windows |

> Pour cloner : voir `06-Scripts-Configuration/PROCEDURE-cloner-vm.md`

---

## Schéma réseau

Voir le dossier `08-Schemas/` :
- `01-architecture-reseau.png` — vue d'ensemble
- `02-flux-attaque.png` — le scénario de détection
