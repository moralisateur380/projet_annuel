# 🔧 PROCÉDURE — Cloner une VM depuis un template

> Pour créer une nouvelle VM rapidement à partir des templates.

## Templates disponibles

| Template | VM ID | Usage |
|---|---|---|
| srv-debian-template | 101 | Services Linux (web, SOC, Kali léger...) |
| srv-win10-template | 102 | Postes Windows |

## Étape 1 — Cloner dans Proxmox

1. Clic droit sur le template → **Clone**
2. Remplir :
   - **VM ID** : un numéro libre
   - **Name** : nom métier (srv-xxx-1)
   - **Mode** : `Full Clone`
   - **Storage** : `local`
3. **Clone** (~1 min)

## Étape 2 — Ajuster les ressources (onglet Hardware)

| Service | RAM | CPU | Disque |
|---|---|---|---|
| Web léger | 2 Go | 2 | 20 Go |
| Wazuh/SOC | 6 Go | 2 | 50+ Go |
| Kali | 2 Go | 2 | 30 Go |

## Étape 3 — Première config (Debian)

```bash
su -
# Régénérer l'identité unique (OBLIGATOIRE après clone)
systemd-machine-id-setup
dpkg-reconfigure openssh-server
# Renommer
hostnamectl set-hostname srv-NOUVEAU-NOM
exec bash
# Voir l'IP
ip a
# Mettre à jour
apt update && apt upgrade -y
```

## ⚠️ Pourquoi régénérer l'identité ?

Sans ça, tous les clones ont le même machine-id et les mêmes clés SSH
→ conflits réseau. La commande `systemd-machine-id-setup` règle ça.

## ⚠️ Agrandir le disque si besoin

Si le disque est trop petit (cas Wazuh) :
1. Éteindre la VM
2. Proxmox → Hardware → Hard Disk → Disk Action → Resize → +40
3. Redémarrer
4. Si partition bloquée par le swap : utiliser le script `agrandir-docker.sh`
