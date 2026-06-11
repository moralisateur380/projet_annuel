# 💾 PROCÉDURE — Libérer de l'espace disque sur Proxmox

> Avant de créer de nouvelles VM, vérifie et libère de l'espace si besoin.
> ⚠️ Toujours coordonner avec l'équipe avant de supprimer quoi que ce soit.

---

## Étape 1 — Vérifier l'espace disponible

### Via l'interface Proxmox
1. Clic sur `srv-prox-01` → onglet **Summary**
2. Regarde le widget **HD space** ou **Root Disk**

### Via SSH (plus précis)
```bash
ssh root@192.168.20.254   # via VPN
df -h
```

Cherche les lignes importantes :
```
Filesystem      Size  Used Avail Use%  Mounted on
/dev/...        XXG   XXG   XXG  XX%   /
```

---

## Le serveur a 2×2 To !

Rappel : le serveur OVH a **2×2 To de disque**. Si Proxmox n'utilise qu'une petite
partie, c'est probablement un problème de **partitionnement**, pas un manque réel.

Pour voir tous les disques :
```bash
lsblk
```

Si tu vois un gros espace non monté → on peut l'ajouter comme storage Proxmox
(demander à Abdoul, c'est une manip délicate).

---

## Solution 1 — Supprimer les ISOs inutiles (gratuit, ~13 Go)

⚠️ **Demande à l'équipe d'abord !**

Dans Proxmox → `local` → **ISO Images**, on peut supprimer :

| ISO | Garder ? |
|---|---|
| `debian-13.1.0-amd64-netinst.iso` | ✅ Garder |
| `virtio-win-0.1.266.iso` | ✅ Garder (pour futurs clones Windows) |
| `netgate-installer-...iso` | 🗑️ Supprimer (pfSense déjà installé) |
| `Win10_22H2_French...iso` | 🗑️ Supprimer (template déjà créé) |
| `Win11_22H2_French...iso` | 🗑️ Supprimer (non utilisé) |

→ Gain : ~13 Go

---

## Solution 2 — Supprimer une VM inutile

Si `win10-tempon` (VM 105) ne sert plus → ~60 Go récupérables.

⚠️ **Confirme avec celui qui l'a créée** avant de supprimer !

Pour supprimer : clic droit sur la VM → **Remove**.

---

## Solution 3 — Déployer en CT LXC plutôt qu'en VM

Pour les **futurs** services Linux (Wazuh, Suricata, nginx...), un **conteneur LXC**
prend 5-10x moins de place qu'une VM :

| | VM | CT LXC |
|---|---|---|
| Disque | 20-50 Go | 2-5 Go |
| RAM overhead | ~1 Go | ~100 Mo |

→ Économie énorme. Voir avec l'équipe pour choisir VM ou CT selon le service.

---

## Solution 4 — Compacter les disques (avancé)

Les disques qcow2 grossissent mais ne rétrécissent pas tout seuls.
Avec `discard` activé (c'est le cas sur nos templates) :

```bash
# Dans la VM
sudo fstrim -av
```

Pour compacter vraiment côté Proxmox (à faire avec backup + précaution) :
```bash
# Sur l'hôte Proxmox, VM éteinte
qemu-img convert -O qcow2 ancien.qcow2 nouveau.qcow2
```

---

## ⚠️ Ce qu'il NE faut PAS faire

- ❌ Payer pour un nouvel abonnement (sur Kimsufi = nouveau serveur = tout refaire)
- ❌ Supprimer une VM sans demander à l'équipe
- ❌ Toucher au partitionnement sans backup
- ❌ Supprimer les templates (101, 102) — ils servent à cloner

---

## 📊 Combien d'espace pour les nouvelles VM ?

| VM | Espace recommandé |
|---|---|
| srv-web-1 (portail) | 20 Go |
| srv-wazuh-1 (SOC) | 50 Go |
| srv-kali-1 (attaque) | 30 Go |

Total ~100 Go. Si le storage `local` n'a pas ça, applique les solutions ci-dessus
ou déploie Wazuh en CT LXC.
