# ⚔️ GUIDE ATTAQUE & DÉMO — Le scénario de la soutenance (de A à Z)

> **Pour toute l'équipe** : c'est LE moment fort de la soutenance.
> On simule une attaque sur le portail, on la détecte avec le SOC, on l'analyse avec l'IA.
> Ce guide explique comment monter et répéter ce scénario.

---

# 🎯 Le scénario en une image

```
   [Kali Linux]                                    [SOC Wazuh]
   srv-kali-1                                       srv-wazuh-1
        │                                                ▲
        │  1. nmap (reconnaissance)                      │
        │  2. nikto (scan vulnérabilités)                │  5. Alerte générée
        │  3. hydra (brute-force login)  ───────────────►│  6. Affichée dans dashboard
        ▼                                                │
   [Portail NexaMind]──────── logs nginx ────────────────┘
   srv-web-1                                              │
   192.168.20.50                                          ▼
                                              7. [IA Claude analyse l'alerte]
                                              8. [Alerte remonte dans le portail]
```

---

# 📍 ÉTAPE 1 — Créer la machine d'attaque (srv-kali-1)

## Option A — Kali Linux complet

### 1.1 Télécharger l'ISO Kali

Sur Proxmox → `local` → **ISO Images** → **Download from URL** :
```
https://cdimage.kali.org/kali-2024.4/kali-linux-2024.4-installer-amd64.iso
```
*(vérifie la dernière version sur https://www.kali.org/get-kali/)*

### 1.2 Créer la VM

**Create VM** :

| Champ | Valeur |
|---|---|
| VM ID | `202` |
| Name | `srv-kali-1` |
| ISO | kali-linux-...iso |
| CPU | `x86-64-v2-AES`, 2 cores |
| RAM | `2048` |
| Disque | `30` Go |
| Bridge | `vmbr2` |
| BIOS | SeaBIOS |

### 1.3 Installer Kali

Installation graphique classique (comme Debian). Outils déjà inclus : nmap, hydra, nikto, metasploit...

## Option B — Plus léger (Debian + outils)

Si Kali est trop lourd, clone le template Debian et installe juste les outils :
```bash
# Cloner le template (VM ID 202, nom srv-kali-1)
# Puis sur la VM :
sudo apt install -y hydra nmap nikto
```

---

# 📍 ÉTAPE 2 — Préparer l'attaque

Sur srv-kali-1 (ou la Debian avec les outils) :

```bash
# Créer une petite liste de mots de passe pour la démo
cat > passwords.txt << 'EOF'
password
admin
123456
admin123
letmein
qwerty
root
toor
nexamind
EOF
```

---

# 📍 ÉTAPE 3 — Les 3 phases de l'attaque

## Phase 1 — Reconnaissance (nmap)

```bash
# Scanner le serveur web pour voir les ports ouverts
nmap -sV 192.168.20.50
```

Résultat attendu : ports 22 (SSH), 80 (nginx), 8000 (portail).

## Phase 2 — Scan de vulnérabilités (nikto)

```bash
# Analyser le serveur web
nikto -h http://192.168.20.50
```

Nikto teste des centaines de vulnérabilités web connues.

## Phase 3 — Brute-force (hydra) ⭐ LE CLOU DU SPECTACLE

```bash
# Attaque par dictionnaire sur le formulaire de login du portail
hydra -l admin -P passwords.txt 192.168.20.50 -s 80 \
  http-post-form "/login:username=^USER^&password=^PASS^:Identifiants invalides"
```

⏳ Hydra lance des dizaines de tentatives en quelques secondes.
Chaque tentative échouée = un log que Wazuh détecte.

---

# 📍 ÉTAPE 4 — La détection (côté SOC)

Pendant ou juste après l'attaque :

1. Va sur le **dashboard Wazuh** (https://192.168.20.51/)
2. **Threat Hunting** ou **Security Events**
3. Tu vois apparaître des alertes :
   - `NexaMind: Brute-force détecté sur le portail web` 🚨
   - Niveau 10 (critique)
   - IP source : celle de Kali

4. Va sur le **portail NexaMind** → page **Alertes**
5. L'alerte y est remontée automatiquement ✅

---

# 📍 ÉTAPE 5 — L'analyse IA (bonus différenciant)

Avec le script `analyze_alert.py` (voir guide portail), montre comment
Claude analyse l'alerte en français :

```
1. Type d'attaque : Brute-force sur authentification web
2. Criticité : Élevée
3. Action recommandée : Bloquer l'IP source via pfSense,
   activer une limitation du taux de connexion, vérifier les logs
   pour d'autres tentatives.
```

---

# 🎬 DÉROULÉ DE LA DÉMO EN SOUTENANCE (35 min)

| Temps | Qui | Quoi |
|---|---|---|
| 0-3 min | Chef projet | Intro, contexte NexaMind, équipe, défi (rôles inversés) |
| 3-8 min | Abdoul | Architecture : Proxmox, pfSense, schéma réseau |
| 8-13 min | Abdoul | AD + Passbolt + connexion client Windows |
| 13-20 min | Personne SOC | **DÉMO LIVE : attaque → détection Wazuh** ⭐ |
| 20-25 min | Victor | Portail NexaMind + l'alerte qui remonte |
| 25-30 min | Personne IA | Analyse Claude de l'alerte + perspectives |
| 30-35 min | Tous | Questions / réponses |

---

# 🎥 PLAN B — Vidéo de secours OBLIGATOIRE

⚠️ **Les démos live plantent parfois.** Enregistrez une vidéo de l'attaque qui marche :

1. Une fois que le scénario fonctionne, lancez un enregistrement d'écran (OBS, ou même téléphone)
2. Filmez tout le déroulé : attaque → alerte Wazuh → alerte portail → analyse IA
3. Gardez cette vidéo prête à projeter si le live échoue

**Mieux vaut une vidéo qui marche qu'un live qui plante devant le jury.**

---

# ✅ CHECKLIST DU SCÉNARIO

- [ ] VM srv-kali-1 créée (ou Debian + outils)
- [ ] Liste de mots de passe préparée
- [ ] nmap fonctionne sur le serveur web
- [ ] nikto fonctionne
- [ ] hydra lance le brute-force
- [ ] Wazuh détecte l'attaque (alerte visible)
- [ ] L'alerte remonte dans le portail
- [ ] L'analyse Claude fonctionne
- [ ] Scénario répété au moins 3 fois
- [ ] Vidéo de secours enregistrée

---

# ⚠️ Note éthique et légale

Cette attaque se fait **UNIQUEMENT sur VOTRE propre infrastructure de test**,
dans un réseau isolé. C'est un exercice pédagogique légitime de Red Team / Blue Team.

**Ne jamais** lancer ces outils contre des systèmes q266ui ne vous appartiennent pas —
c'est illégal (article 323-1 du Code pénal en France).

---

# 🆘 Dépannage

| Problème | Solution |
|---|---|
| hydra ne trouve pas le bon "fail string" | Vérifier le message d'erreur exact du portail ("Identifiants invalides") |
| Pas d'alerte dans Wazuh | Vérifier que l'agent lit bien les logs nginx |
| nmap ne voit rien | Vérifier que Kali est sur vmbr2 (même réseau) + VPN |
| L'attaque marche mais pas de log | Vérifier que nginx est bien devant le portail |

---

*C'est le moment qui fait gagner ou perdre des points. Répétez-le jusqu'à ce qu'il soit fluide. 🎯*
