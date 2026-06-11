# 🔐 PROCÉDURE — Accès VPN OpenVPN

> Comment se connecter au réseau interne du projet via le VPN.
> Indispensable pour accéder à Proxmox et toutes les VM.

---

## Pourquoi un VPN ?

Le serveur n'expose pas directement Proxmox/pfSense sur Internet (sécurité).
Pour accéder au réseau interne (`192.168.20.0/24`), il faut passer par le tunnel VPN.

---

## Étape 1 — Récupérer ton profil .ovpn

Chaque membre a son propre fichier `.ovpn` + identifiants, fournis par Abdoul.
**Récupère-les dans Passbolt** (ou demande à Abdoul).

⚠️ Ne partage jamais ton profil VPN — il est personnel.

---

## Étape 2 — Installer le client OpenVPN

| OS | Client | Lien |
|---|---|---|
| Windows | OpenVPN Connect | https://openvpn.net/client/ |
| macOS | Tunnelblick | https://tunnelblick.net/ |
| Linux | openvpn (apt) | `sudo apt install openvpn` |

---

## Étape 3 — Importer le profil

**OpenVPN Connect (Windows)** :
1. Ouvre OpenVPN Connect
2. **Import Profile** → **File**
3. Sélectionne ton fichier `.ovpn`
4. Entre ton username + password

**Linux** :
```bash
sudo openvpn --config ton-profil.ovpn
```

---

## Étape 4 — Se connecter

Active le profil (bascule sur ON). Tu dois voir **CONNECTED** + une pastille verte.

---

## Étape 5 — Vérifier que ça marche

Dans un terminal :
```bash
# Tu dois pouvoir ping la passerelle du tunnel
ping 10.10.10.1

# Et atteindre le réseau interne
ping 192.168.20.254
```

Si les deux répondent → VPN OK ✅

---

## 🆘 Problèmes fréquents

| Problème | Solution |
|---|---|
| "CONNECTED" mais rien ne ping | Les routes LAN ne sont pas poussées — voir Abdoul (champ "IPv4 Local Networks" dans pfSense) |
| AUTH_FAILED | Mauvais identifiants — vérifier dans Passbolt |
| TLS handshake failed | Port UDP 1194 bloqué (réseau d'école) — tester sur 4G |
| Connexion timeout | Vérifier l'IP serveur dans le .ovpn |

---

## 📝 Rappel des IPs importantes (une fois connecté au VPN)

| Service | IP |
|---|---|
| Proxmox | https://192.168.20.254:8006/ |
| pfSense admin | https://192.168.20.1/ |
| Active Directory | 192.168.20.10 |
| Tunnel VPN (pfSense) | 10.10.10.1 |

> Note : `192.168.10.0/24` (réseau intermédiaire/WAN) n'est PAS accessible via VPN, c'est normal.
