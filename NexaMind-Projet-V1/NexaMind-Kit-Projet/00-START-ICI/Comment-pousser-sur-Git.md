# 📤 Comment mettre ce kit sur Git (et travailler en équipe)

> Ce guide explique comment **pousser tout ce kit** sur votre dépôt GitHub,
> et comment chacun travaille sur sa partie sans se marcher dessus.

---

## 🎯 Étape 1 — Récupérer le dépôt sur ton PC

Si tu n'as pas encore le repo en local :

```bash
git clone https://github.com/VOTRE-EQUIPE/Projet-Pro_4esgi.git
cd Projet-Pro_4esgi
```

Si tu l'as déjà, mets-le à jour avant de travailler :

```bash
cd Projet-Pro_4esgi
git pull
```

> ⚠️ **Fais TOUJOURS `git pull` avant de commencer à bosser**, pour récupérer ce que les autres ont poussé.

---

## 🎯 Étape 2 — Intégrer le kit dans le repo

1. **Dézippe** le kit `NexaMind-Kit-Projet.zip`
2. **Copie le dossier** `NexaMind-Kit-Projet/` dans ton repo

Structure cible :
```
Projet-Pro_4esgi/
├── 4-projet-annuel/          (doc Obsidian existante)
├── samba-ad/                 (partie Abdoul existante)
├── NexaMind-Kit-Projet/      ← 🆕 LE KIT
│   ├── 00-START-ICI/
│   ├── 01-Guide-Victor-Portail/
│   ├── ...
└── portail-nexamind/         ← 🆕 LE CODE (depuis 06-Code-Portail)
```

> 💡 **Astuce** : sors le code du portail (`06-Code-Portail/portail-nexamind/`) à la racine
> du repo pour qu'il soit facile à lancer. Garde une copie de la doc dans le kit.

---

## 🎯 Étape 3 — Pousser sur Git

Dans VS Code, ouvre un terminal (`Terminal → Nouveau terminal`) :

```bash
# Voir ce qui a changé
git status

# Tout ajouter
git add .

# Créer le commit
git commit -m "Ajout du kit projet complet NexaMind + portail"

# Envoyer sur GitHub
git push
```

---

## 🔑 Si Git demande une authentification

GitHub n'accepte plus le mot de passe classique. Il faut un **Personal Access Token (PAT)** :

1. GitHub → clic sur ton avatar → **Settings**
2. Tout en bas → **Developer settings**
3. **Personal access tokens** → **Tokens (classic)**
4. **Generate new token (classic)**
5. Coche la case **`repo`** (accès complet aux dépôts)
6. **Generate token** → copie le token (il commence par `ghp_...`)
7. Quand Git demande le mot de passe, **colle ce token** (pas ton mot de passe GitHub)

> 💾 Garde ce token dans Passbolt, il ne s'affichera qu'une fois.

---

## 👥 Étape 4 — Travailler en équipe sans conflits

### Règle d'or : chacun sa zone

| Membre | Travaille dans | Évite de toucher |
|---|---|---|
| Victor | `portail-nexamind/`, `01-Guide-Victor-Portail/` | les VM des autres |
| Personne SOC | `02-Guide-SOC-Wazuh/` | le portail |
| Abdoul | `03-Guide-AD-Passbolt/`, `samba-ad/` | le portail |

Comme chacun touche des fichiers différents, **vous n'aurez quasi jamais de conflits Git**.

### Le cycle de travail quotidien

```bash
# 1. AVANT de commencer : récupérer les changements des autres
git pull

# 2. Travailler (modifier/créer des fichiers)

# 3. APRÈS avoir avancé : sauvegarder
git add .
git commit -m "Description de ce que tu as fait"
git push
```

### Si Git refuse ton push (quelqu'un a poussé avant toi)

```bash
git pull --rebase
# Résous les conflits s'il y en a (rare si chacun sa zone)
git push
```

---

## 🌿 (Optionnel) Travailler avec des branches

Pour les plus à l'aise, chacun peut avoir sa branche :

```bash
# Créer sa branche
git checkout -b victor-portail

# Travailler, commit, push sur sa branche
git push -u origin victor-portail

# Quand c'est prêt, faire une Pull Request sur GitHub pour merger dans main
```

> Pas obligatoire pour un projet à 4. Le travail direct sur `main` avec `git pull` régulier suffit.

---

## ⚠️ Choses à NE JAMAIS committer

Le fichier `.gitignore` du portail bloque déjà ça, mais vérifie :

- ❌ `venv/` (environnement Python, lourd)
- ❌ `nexamind.db` (base de données)
- ❌ Mots de passe en clair, fichiers `.env`, clés API
- ❌ `__pycache__/`

Si tu vois un de ces trucs dans `git status`, **NE LE COMMIT PAS** et préviens l'équipe.

---

## 🆘 Problèmes fréquents

| Problème | Solution |
|---|---|
| `git push` rejeté | `git pull --rebase` puis re-push |
| Authentification échoue | Utiliser un Personal Access Token |
| Conflit de fichier | Ouvrir le fichier, choisir quelle version garder, `git add` + `git commit` |
| "fatal: not a git repository" | Tu n'es pas dans le bon dossier, fais `cd` vers le repo |
| Mauvais fichier committé | `git rm --cached fichier` puis commit |

---

*Une fois le kit poussé, toute l'équipe peut le récupérer avec `git pull`. 🚀*
