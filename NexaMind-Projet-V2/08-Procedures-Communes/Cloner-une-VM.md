# 🔧 PROCÉDURE — Cloner une VM depuis un template

> Procédure commune pour créer une nouvelle VM à partir des templates existants.
> Valable pour tous les membres de l'équipe.

---

## Les templates disponibles

| Template | VM ID | Usage |
|---|---|---|
| `srv-debian-template` | 101 | Tous les services Linux (web, Wazuh, etc.) |
| `srv-win10-template` | 102 | Postes clients Windows |

---

## Étape 1 — Cloner

1. Connecte-toi à Proxmox (https://192.168.20.254:8006/, via VPN)
2. **Clic droit** sur le template (101 ou 102) → **Clone**
3. Remplis :

| Champ | Valeur |
|---|---|
| **VM ID** | un numéro libre (200, 201, 202...) |
| **Name** | nom métier (`srv-web-1`, `srv-wazuh-1`...) |
| **Mode** | `Full Clone` (copie indépendante) |
| **Storage** | `local` |

4. **Clone** → patiente ~1 min

> 💡 **Full Clone vs Linked Clone** : Full = copie complète indépendante (recommandé).
> Linked = dépend du template (plus léger mais fragile). Utilise toujours Full.

---

## Étape 2 — Ajuster les ressources (si besoin)

Avant de démarrer, onglet **Hardware** :
- **Memory** : ajuste selon le service (2 Go pour web, 4-6 Go pour Wazuh)
- **Processors** : 2 cores minimum
- **Hard Disk** → **Disk Action** → **Resize** pour agrandir si besoin

---

## Étape 3 — Première config (Debian)

Démarre la VM, ouvre la Console, connecte-toi (`nexa` / `NexaMind2026!`) :

```bash
su -

# IMPORTANT : régénérer l'identité unique (sinon conflits avec le template)
systemd-machine-id-setup
dpkg-reconfigure openssh-server

# Renommer la machine
hostnamectl set-hostname srv-NOUVEAU-NOM

# Sudo pour nexa
usermod -aG sudo nexa

# Voir l'IP (DHCP attribué par pfSense)
ip a

# Mettre à jour
apt update && apt upgrade -y
```

📝 **Note toujours l'IP** attribuée à la nouvelle VM.

---

## Étape 4 — Première config (Windows)

Démarre la VM, ouvre la Console :
1. Renomme le PC (Système → Renommer ce PC) → reboot
2. Configure le DNS vers l'AD si tu veux le joindre au domaine
3. Joins le domaine si besoin (voir guide AD)

---

## ⚠️ Pourquoi régénérer l'identité ?

Le template a un `machine-id` et des clés SSH uniques. Si tu clones sans régénérer,
**toutes les VM auront le même ID** → conflits DHCP, SSH, Kerberos.

La commande `systemd-machine-id-setup` + `dpkg-reconfigure openssh-server`
règle ça en générant de nouveaux identifiants pour le clone.

---

## 🆘 Problèmes fréquents

| Problème | Solution |
|---|---|
| VM ne démarre pas (erreur CPU) | Vérifier type CPU = `x86-64-v2-AES` |
| 2 VM ont la même IP | Régénérer machine-id sur l'une d'elles |
| Pas d'accès à la VM | Vérifier le VPN |
| Disque plein pendant le clone | Libérer de l'espace (voir Liberer-espace-disque.md) |
