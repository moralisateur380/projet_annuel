# 👤 GUIDE AD + PASSBOLT — Active Directory & Coffre-fort (de A à Z)

> **Mission** : Active Directory (Samba) + Passbolt + structuration des comptes.
> Une partie est déjà faite (AD et Passbolt déployés). Ce guide complète et structure.

---

# 🎯 Vue d'ensemble

L'AD est l'**annuaire central** : il gère les utilisateurs, groupes, politiques.
Passbolt est le **coffre-fort de mots de passe** de l'équipe.

État actuel :
- ✅ `srv-ad-1` (VM 104) — Samba AD `cybernest.local` déployé
- ✅ `srv-passbolt-1` (VM 103) — Passbolt déployé

Ce qu'il reste à faire :
1. Structurer l'AD (OU, groupes, utilisateurs de démo)
2. Créer des GPO de sécurité
3. Joindre le client Windows au domaine
4. Activer l'audit des connexions (pour que Wazuh détecte les attaques AD)
5. Migrer tous les credentials dans Passbolt

---

# 📍 ÉTAPE 1 — Structurer l'Active Directory

## 1.1 — Se connecter au serveur AD

```bash
# SSH vers srv-ad-1 (via VPN)
ssh nexa@192.168.20.10
su -
```

## 1.2 — Créer des Unités d'Organisation (OU)

```bash
# Créer les OU principales
samba-tool ou create "OU=Direction,DC=cybernest,DC=local"
samba-tool ou create "OU=IT,DC=cybernest,DC=local"
samba-tool ou create "OU=Clients,DC=cybernest,DC=local"
```

## 1.3 — Créer des utilisateurs de démo

```bash
# Utilisateurs dans différentes OU
samba-tool user create j.dupont MotDePasse2026! --userou="OU=Direction"
samba-tool user create m.martin MotDePasse2026! --userou="OU=IT"
samba-tool user create p.bernard MotDePasse2026! --userou="OU=IT"
samba-tool user create client.acme MotDePasse2026! --userou="OU=Clients"
samba-tool user create a.durand MotDePasse2026! --userou="OU=Direction"
```

## 1.4 — Créer des groupes

```bash
samba-tool group create Administrateurs-IT
samba-tool group create Direction
samba-tool group create Clients-Externes

# Ajouter des membres
samba-tool group addmembers Administrateurs-IT m.martin,p.bernard
samba-tool group addmembers Direction j.dupont,a.durand
samba-tool group addmembers Clients-Externes client.acme
```

## 1.5 — Vérification

```bash
samba-tool user list
samba-tool group list
samba-tool ou list
```

---

# 📍 ÉTAPE 2 — Activer l'audit des connexions

⚠️ **Crucial** pour que Wazuh détecte les attaques sur l'AD.

```bash
# Éditer la config Samba
nano /etc/samba/smb.conf
```

Ajoute dans la section `[global]` :
```ini
log level = 3 auth_audit:3
```

Redémarre Samba :
```bash
systemctl restart samba-ad-dc
```

Maintenant les tentatives de connexion (réussies ET échouées) sont loggées,
et l'agent Wazuh (installé par la personne SOC) pourra les détecter.

---

# 📍 ÉTAPE 3 — Joindre le client Windows au domaine

Sur **client-win-1** (VM 106) :

1. Ouvre la console de la VM dans Proxmox
2. Configure le DNS du Windows pour pointer vers l'AD :
   - Paramètres réseau → DNS → `192.168.20.10` (IP de srv-ad-1)
3. Clic droit Démarrer → Système → **Renommer ce PC (avancé)**
4. Onglet **Nom de l'ordinateur** → **Modifier**
5. **Membre d'un domaine** → `cybernest.local`
6. Identifiants admin AD : `administrator` / (mot de passe AD)
7. Message "Bienvenue dans le domaine cybernest.local" ✅
8. Redémarrer

---

# 📍 ÉTAPE 4 — Créer des GPO de sécurité

Les GPO (Group Policy Objects) appliquent des règles aux postes du domaine.

```bash
# Sur srv-ad-1, créer une GPO
samba-tool gpo create "Securite-Postes"

# Lister les GPO
samba-tool gpo list
```

Pour éditer le contenu des GPO (verrouillage écran, complexité mdp...),
le plus simple est d'utiliser **RSAT** (outils d'admin) depuis le client Windows :
1. Installer RSAT sur client-win-1
2. Ouvrir "Gestion des stratégies de groupe"
3. Éditer la GPO : verrouillage session après 5 min, complexité mdp, etc.

---

# 📍 ÉTAPE 5 — Passbolt : migrer les credentials

## 5.1 — Inviter toute l'équipe

Sur Passbolt (déjà déployé), en admin :
1. Users → **Add User**
2. Invite chaque membre (Victor, Jacques, Marwane) avec leur email
3. Chacun reçoit un mail pour configurer son compte

## 5.2 — Organiser les coffres

Crée des dossiers par catégorie :
- `Infra/` (Proxmox, pfSense)
- `VPN/` (les profils OpenVPN)
- `Templates/` (mdp des templates)
- `Services/` (AD, Wazuh, Passbolt)

## 5.3 — Migrer tous les mots de passe

Pour chaque credential du projet :
1. **New password**
2. Renseigner nom, URL, username, password
3. **Partager** avec le bon groupe

⚠️ Une fois tout migré, supprimez les mots de passe en clair de Discord !

---

# ✅ CHECKLIST DE LA MISSION

- [ ] OU créées (Direction, IT, Clients)
- [ ] 5+ utilisateurs de démo créés
- [ ] Groupes créés et peuplés
- [ ] Audit des connexions activé (pour Wazuh)
- [ ] Client Windows joint au domaine
- [ ] GPO de sécurité créées
- [ ] Toute l'équipe sur Passbolt
- [ ] Credentials migrés dans Passbolt
- [ ] Mots de passe supprimés de Discord

---

# 🎤 Ton rôle en soutenance (vers 8-13 min)

1. Montre l'AD : les OU, les utilisateurs, les groupes
2. Montre une connexion d'un user depuis le client Windows
3. Montre Passbolt et explique pourquoi c'est important (pas de mdp en clair)
4. Fais le lien avec le SOC : "les connexions AD sont auditées et surveillées par Wazuh"

---

# 🆘 Dépannage

| Problème | Solution |
|---|---|
| `samba-tool` command not found | Vérifier que Samba AD est bien installé |
| Client Windows ne rejoint pas le domaine | Vérifier le DNS du client (doit pointer vers l'AD) |
| Connexion AD échoue | Vérifier l'heure (Kerberos sensible au décalage horaire) |
| Passbolt inaccessible | Vérifier VPN + que la VM 103 tourne |

---

*L'AD et Passbolt sont les fondations de la sécurité. Bien les structurer = bonne note. 🔐*
