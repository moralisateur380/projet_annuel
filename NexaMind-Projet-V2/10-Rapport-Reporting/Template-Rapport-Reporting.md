# 📑 RAPPORT TECHNIQUE & REPORTINGS

> Structure du rapport final (12 pages) + template de reporting hebdo.

---

# 📄 PARTIE A — Structure du rapport (12 pages max)

| Page | Contenu | Qui |
|---|---|---|
| 1 | Page de garde (titre, équipe, date) | Tous |
| 2 | Sommaire + Intro (contexte NexaMind, défi rôles inversés) | Tous |
| 3-4 | Architecture & réseau (schéma, Proxmox, pfSense, VPN) | Abdoul |
| 5 | Active Directory + postes Windows | Jacques |
| 6 | Sécurité : Passbolt + Suricata | Marwane |
| 7-8 | SOC Wazuh (architecture, agents, règles de détection) | Victor |
| 9 | Portail NexaMind (stack, fonctionnalités, IA Claude) | Victor |
| 10 | Scénario d'attaque & détection (schéma flux) | Tous |
| 11 | Difficultés rencontrées & solutions | Tous |
| 12 | Conclusion & perspectives | Tous |

## Conseils de rédaction
- ✅ Du concret : code, commandes, configs, captures d'écran
- ✅ Justifier chaque choix techno ("on a choisi X car...")
- ❌ Pas de blabla générique sur "la cybersécurité c'est important"

## Difficultés à raconter (page 11) — du vécu !
- Templates VM : CPU host incompatible Kimsufi → x86-64-v2-AES
- Wazuh : Debian 13 incompatible install native → solution Docker
- Disque plein : partition dédiée Docker créée
- Portail : venv manquant après dézippage → recréé
Ces galères résolues montrent une vraie démarche d'ingénieur.

---

# 📝 PARTIE B — Template reporting hebdo

> À rendre **chaque dimanche avant 23h59**. Au moins 1 page.

```markdown
# Reporting Semaine XX — [Prénom Nom]

## Mission
[Ta mission]

## Travail effectué cette semaine
- ✅ [Tâche 1]
- ✅ [Tâche 2]
- 🟡 [En cours]

## Taux de complétion
[X]% — [explication]

## Difficultés rencontrées
- [Difficulté] → [solution ou blocage]

## Prévisions semaine prochaine
- [ ] [Tâche prévue]

## Captures / preuves
[Screenshots]
```

---

# 📋 PARTIE C — Exemple rempli (Victor)

```markdown
# Reporting Semaine 24 — Victor

## Mission
SOC Wazuh + Portail web NexaMind.

## Travail effectué cette semaine
- ✅ Installé Wazuh en Docker sur srv-wazuh-1
- ✅ Résolu un problème de disque plein (partition dédiée Docker)
- ✅ Connecté l'agent Wazuh sur srv-web-1
- ✅ Créé 3 règles de détection (login, brute-force, scan)
- ✅ Testé une attaque : détectée par Wazuh ✅
- ✅ Réparé le portail (venv + base de données)

## Taux de complétion
85% — SOC et portail fonctionnent, reste l'IA Claude à brancher.

## Difficultés rencontrées
- Debian 13 incompatible avec l'install native Wazuh → passé par Docker
- Disque VM trop petit → créé une partition dédiée pour Docker
- Portail en erreur après dézippage du kit → recréé le venv

## Prévisions semaine prochaine
- [ ] Brancher l'IA Claude (clé API)
- [ ] Installer des agents Wazuh sur l'AD et le Windows
- [ ] Aider à répéter le scénario de démo

## Captures
[dashboard Wazuh avec l'alerte de brute-force détectée]
```

---

*Un bon reporting montre une progression régulière. Le prof suit ça de près. 📈*
