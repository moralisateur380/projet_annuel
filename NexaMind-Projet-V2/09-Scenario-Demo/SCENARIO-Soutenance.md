# 🎬 SCÉNARIO DE DÉMO — Soutenance NexaMind

> Le déroulé de la démo de soutenance (35 min).
> Le moment clé : montrer une attaque détectée en temps réel.

---

## 🎯 L'histoire qu'on raconte

> "NexaMind est une entreprise de cybersécurité. On a construit son infrastructure
> complète, son SOC, et son portail client. Voici comment on détecte une attaque
> en temps réel."

---

## ⏱️ Déroulé minuté (35 min)

| Temps | Qui | Quoi |
|---|---|---|
| 0-3 min | Tous | Intro : NexaMind, l'équipe, le défi des rôles inversés |
| 3-8 min | Abdoul | Architecture réseau : Proxmox, pfSense, VPN (schéma) |
| 8-13 min | Jacques | Active Directory + poste Windows connecté |
| 13-22 min | Victor + Marwane | **DÉMO LIVE : attaque → détection** ⭐ |
| 22-27 min | Victor | Portail NexaMind + alertes remontées |
| 27-31 min | Victor/Marwane | IA Claude + Suricata + perspectives |
| 31-35 min | Tous | Questions / réponses |

---

## ⭐ LE MOMENT CLÉ — La démo d'attaque (13-22 min)

C'est le cœur de la soutenance. Voici le déroulé précis :

### Acte 1 — Montrer le système sain (1 min)
- Victor montre le dashboard Wazuh (les agents connectés, tout est vert)
- Victor montre le portail NexaMind qui tourne

### Acte 2 — Lancer l'attaque (2 min)
- Marwane (sur Kali) lance le brute-force :
  ```bash
  ./attaque-test.sh
  ```
- On voit les tentatives défiler à l'écran

### Acte 3 — La détection (3 min)
- Victor bascule sur le dashboard Wazuh
- **En direct**, l'alerte "Brute-force détecté" apparaît 🚨
- On montre le détail : IP source, nombre de tentatives, niveau critique

### Acte 4 — La remontée (2 min)
- Victor montre le portail NexaMind → page Alertes
- L'alerte est remontée automatiquement
- (Si IA branchée) Claude analyse l'alerte en français

### Acte 5 — Suricata (1 min)
- Marwane montre que Suricata a aussi détecté le scan réseau

---

## 🎥 VIDÉO DE SECOURS — OBLIGATOIRE

⚠️ **Les démos live plantent parfois.** Enregistrez une vidéo de tout le scénario qui marche :
1. Lancez le scénario complet une fois qu'il fonctionne
2. Filmez l'écran (OBS Studio, ou même téléphone)
3. Capturez : attaque → alerte Wazuh → alerte portail → analyse IA
4. Gardez la vidéo prête à projeter

**Mieux vaut une vidéo qui marche qu'un live qui plante devant le jury.**

---

## 🎤 Phrases clés à dire

**Intro** :
> "On a inversé les rôles dans l'équipe pour monter en compétence,
> exactement comme un junior qui arrive en entreprise."

**Pendant la détection** :
> "Là, notre SOC vient de détecter une attaque par force brute en temps réel,
> sans intervention humaine."

**Sur l'IA** :
> "Notre portail ne se contente pas d'afficher l'alerte : l'IA Claude
> l'analyse et recommande une action, comme un analyste SOC junior."

**Conclusion** :
> "On a construit une infrastructure de cybersécurité complète et fonctionnelle,
> de la détection réseau jusqu'à l'analyse par IA."

---

## ✅ CHECKLIST AVANT LA SOUTENANCE

### Technique
- [ ] Toutes les VM démarrent
- [ ] Le portail répond
- [ ] Wazuh dashboard accessible
- [ ] L'attaque génère bien une alerte
- [ ] L'alerte remonte dans le portail
- [ ] (Bonus) IA Claude branchée
- [ ] (Bonus) Suricata détecte les scans

### Présentation
- [ ] Vidéo de secours enregistrée
- [ ] Scénario répété au moins 3 fois
- [ ] Chacun connaît sa partie
- [ ] Slides/support prêts
- [ ] Rapport rendu (12 pages)

---

## 🆘 Plan B si ça plante en live

1. **Reste calme** : "On a anticipé, voici notre enregistrement"
2. Lance la **vidéo de secours**
3. Continue à commenter par-dessus la vidéo

Le jury apprécie l'anticipation. Avoir une vidéo de secours = professionnalisme.

---

*C'est le moment qui fait la note. Répétez jusqu'à ce que ce soit fluide. 🎯*
