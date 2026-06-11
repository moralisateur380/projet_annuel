# 👤 GUIDE JACQUES — Active Directory + Poste Windows

> Ta mission : faire vivre l'Active Directory (annuaire de l'entreprise)
> et joindre le poste Windows au domaine.
> VM concernées : srv-ad-1 (104) et client-win-1 (106).

---

## 🎯 Vue d'ensemble

L'AD existe déjà (Samba) mais il est **vide**. Ton job : le remplir pour qu'il
ressemble à une vraie entreprise, puis connecter le poste Windows dessus.

```
srv-ad-1 (192.168.20.10)          client-win-1
  Active Directory      <────────  Poste Windows
  domaine cybernest.local          (joint au domaine)
```

---

## 📍 ÉTAPE 1 — Se connecter au serveur AD

```bash
# Via VPN, en SSH
ssh nexa@192.168.20.10
su -
```

> Le mot de passe est dans Passbolt → AD.

---

## 📍 ÉTAPE 2 — Créer la structure de l'entreprise

Un script tout prêt fait ça pour toi → `06-Scripts-Configuration/config-active-directory.sh`

Mais voici ce qu'il fait, pour que tu comprennes :

### Les Unités d'Organisation (les "services")
```bash
samba-tool ou create "OU=Direction,DC=cybernest,DC=local"
samba-tool ou create "OU=IT,DC=cybernest,DC=local"
samba-tool ou create "OU=Clients,DC=cybernest,DC=local"
```

### Les utilisateurs (les "employés")
```bash
samba-tool user create j.dupont MotDePasse2026! --userou="OU=Direction"
samba-tool user create m.martin MotDePasse2026! --userou="OU=IT"
samba-tool user create p.bernard MotDePasse2026! --userou="OU=IT"
samba-tool user create client.acme MotDePasse2026! --userou="OU=Clients"
```

### Les groupes
```bash
samba-tool group create Administrateurs-IT
samba-tool group create Direction
samba-tool group addmembers Administrateurs-IT m.martin,p.bernard
```

### Vérifier
```bash
samba-tool user list
samba-tool group list
```

---

## 📍 ÉTAPE 3 — Activer l'audit des connexions

⚠️ **Important** : ça permet à Wazuh (le SOC de Victor) de détecter les attaques sur l'AD.

```bash
nano /etc/samba/smb.conf
```

Dans la section `[global]`, ajouter :
```ini
log level = 3 auth_audit:3
```

Redémarrer :
```bash
systemctl restart samba-ad-dc
```

---

## 📍 ÉTAPE 4 — Joindre le poste Windows au domaine

Sur **client-win-1** (VM 106), via la console Proxmox :

### 4.1 — Configurer le DNS
1. Paramètres réseau Windows → Carte réseau → Propriétés
2. IPv4 → DNS préféré : **192.168.20.10** (l'IP de l'AD)

### 4.2 — Joindre le domaine
1. Clic droit Démarrer → Système
2. **Renommer ce PC (avancé)**
3. Onglet "Nom de l'ordinateur" → **Modifier**
4. Cocher **Domaine** → taper `cybernest.local`
5. Identifiants : `administrator` + mot de passe AD
6. Message "Bienvenue dans le domaine" ✅
7. Redémarrer

### 4.3 — Tester
Après redémarrage, se connecter avec un compte du domaine :
- Utilisateur : `cybernest\j.dupont`
- Mot de passe : celui défini à l'étape 2

---

## 📍 ÉTAPE 5 — (Bonus) Créer des GPO de sécurité

Les GPO appliquent des règles à tous les postes du domaine.

```bash
# Sur srv-ad-1
samba-tool gpo create "Securite-Postes"
samba-tool gpo list
```

Pour éditer le contenu (verrouillage écran, complexité mdp), le plus simple
est d'installer **RSAT** sur le poste Windows et d'utiliser la console graphique
"Gestion des stratégies de groupe".

---

## ✅ CHECKLIST DE TA MISSION

- [ ] Connexion au serveur AD OK
- [ ] OU créées (Direction, IT, Clients)
- [ ] 4+ utilisateurs créés
- [ ] Groupes créés et peuplés
- [ ] Audit des connexions activé (pour Wazuh)
- [ ] DNS du poste Windows pointant vers l'AD
- [ ] Poste Windows joint au domaine
- [ ] Test de connexion avec un compte du domaine
- [ ] (Bonus) GPO de sécurité créées

---

## 🎤 Ton rôle en soutenance (vers 8-13 min)

1. Montre l'AD : les OU, les utilisateurs, les groupes
2. Montre le poste Windows connecté avec un compte du domaine
3. Explique le lien avec le SOC : "les connexions sont auditées et Wazuh les surveille"

---

## 🆘 Dépannage

| Problème | Solution |
|---|---|
| `samba-tool` introuvable | Vérifier que Samba AD est installé sur la VM |
| Windows refuse de rejoindre | Vérifier le DNS (doit pointer vers 192.168.20.10) |
| Erreur Kerberos | Vérifier l'heure des machines (doit être synchro) |
| Connexion domaine échoue | Vérifier que l'utilisateur existe (`samba-tool user list`) |

---

*L'AD est le cœur de l'identité de l'entreprise. Bien le structurer = grosse valeur ajoutée. 🔐*
