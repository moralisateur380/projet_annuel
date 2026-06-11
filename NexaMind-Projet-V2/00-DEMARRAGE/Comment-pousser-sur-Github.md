# 📤 COMMENT METTRE CE KIT SUR GITHUB

> Pour Victor : pousser le kit sur le repo de l'équipe.
> Repo : https://github.com/moralisateur380/projet_annuel.git

---

## Étape 1 — Récupérer le repo en local

```bash
cd ~/Documents   # ou où tu veux
git clone https://github.com/moralisateur380/projet_annuel.git
cd projet_annuel
```

Si tu l'as déjà : `git pull` pour être à jour.

---

## Étape 2 — Ajouter le kit

1. Dézippe `NexaMind-Projet-Complet.zip`
2. Copie le dossier `NexaMind-Projet-Complet/` dans `projet_annuel/`

---

## Étape 3 — Pousser

```bash
git add .
git commit -m "Kit projet complet : guides par membre, scripts, schemas, code portail"
git push
```

---

## Si Git demande une authentification

GitHub veut un **token**, pas ton mot de passe :
1. GitHub → avatar → Settings → Developer settings
2. Personal access tokens → Tokens (classic) → Generate new token
3. Coche `repo` → Generate
4. Copie le token (`ghp_...`) et utilise-le comme mot de passe

> Garde ce token dans Passbolt.

---

## ⚠️ À NE PAS committer

Le `.gitignore` du portail bloque déjà :
- `venv/` (environnement Python)
- `nexamind.db` (base de données)
- Clés API, mots de passe

Si tu vois un de ces trucs dans `git status`, ne le commit pas.

---

## Prévenir l'équipe

> J'ai poussé le kit complet sur le Git ! Chacun a son guide :
> - Jacques → 03-Guide-Jacques-AD-Windows
> - Abdoul → 04-Guide-Abdoul-Pfsense-VPN
> - Marwane → 05-Guide-Marwane-Passbolt-Attaque
> Les scripts de config sont dans 06-Scripts-Configuration. Faites git pull !
