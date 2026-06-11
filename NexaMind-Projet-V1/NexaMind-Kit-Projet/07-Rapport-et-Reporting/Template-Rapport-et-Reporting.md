# 📑 RAPPORT TECHNIQUE & REPORTINGS

> Templates pour le rapport final (12 pages max) et les reportings hebdomadaires.

---

# 📄 PARTIE A — Structure du rapport technique (12 pages max)

Le prof veut un rapport **purement technique** : code, architecture, justifications.
Pas de blabla. Voici la structure recommandée :

## Page 1 — Page de garde
- Titre : "NexaMind — Plateforme de cybersécurité managée"
- Noms des 4 membres + rôles
- Date, école, classe
- Logo NexaMind

## Page 2 — Sommaire + Introduction (½ page)
- Contexte : entreprise fictive NexaMind SAS
- Le défi des rôles inversés
- Vue d'ensemble de ce qui a été construit

## Pages 3-4 — Architecture & Infrastructure
- Schéma réseau global (mettre `05-Schemas/01-architecture-reseau.svg`)
- Justification : pourquoi Proxmox ? pourquoi pfSense ?
- Le réseau : 3 bridges (WAN/Intermédiaire/LAN), VLANs
- Le VPN OpenVPN pour l'accès distant

## Pages 5-6 — Sécurité : AD + Passbolt + SOC
- Active Directory Samba : structuration, GPO
- Passbolt : gestion des secrets
- Wazuh : architecture du SIEM, agents, règles de détection
- Justification : pourquoi Wazuh et pas Splunk ?

## Pages 7-8 — Le portail NexaMind
- Stack technique : FastAPI + Jinja2 + SQLite + bcrypt
- Justification : pourquoi FastAPI ? pourquoi SQLite ?
- Les fonctionnalités (dashboard, alertes, devis)
- L'intégration API Claude (innovation)
- Captures d'écran du portail

## Pages 9-10 — Le scénario d'attaque & détection
- Schéma du flux (mettre `05-Schemas/02-flux-attaque.svg`)
- Les outils Red Team (nmap, nikto, hydra)
- La chaîne de détection (logs → Wazuh → alerte → portail → IA)
- Captures de l'alerte détectée

## Page 11 — Difficultés & retours d'expérience
- Les problèmes rencontrés et résolus :
  - Templates VM (CPU host incompatible, sysprep Windows)
  - Routage VPN (IPv4 Local Networks)
  - Drivers VirtIO
- Ce qu'on a appris

## Page 12 — Conclusion & perspectives
- Bilan : ce qui marche
- Perspectives : ce qu'on ajouterait (Suricata avancé, TheHive, etc.)
- Mot de fin

---

## Conseils de rédaction

- ✅ **Du concret** : du code, des commandes, des configs (le prof adore)
- ✅ **Justifier chaque choix techno** ("nous avons choisi X car...")
- ✅ **Des captures d'écran** pour illustrer
- ❌ Pas de remplissage, pas de généralités sur "la cybersécurité c'est important"
- ❌ Pas de copier-coller de doc officielle

---

# 📝 PARTIE B — Template de reporting hebdomadaire

> À rendre **chaque dimanche avant 23h59**. Sanction au 2e retard.
> Au moins 1 page. Copie ce template chaque semaine.

```markdown
# Reporting Semaine XX — [Prénom Nom]

## Mission
[Ta mission de fond, ex: Portail NexaMind]

## Travail effectué cette semaine
- ✅ [Tâche 1 accomplie]
- ✅ [Tâche 2 accomplie]
- 🟡 [Tâche en cours]

## Taux de complétion de ma partie
[X]% — [courte explication]

## Difficultés rencontrées
- [Difficulté 1] → [comment résolue ou bloquée]

## Retour d'expérience
[Ce que tu as appris cette semaine]

## Prévisions semaine prochaine
- [ ] [Tâche prévue 1]
- [ ] [Tâche prévue 2]

## Captures / preuves
[Screenshots de ce qui marche]
```

---

# 📋 PARTIE C — Exemple de reporting rempli (Victor, Semaine 21)

```markdown
# Reporting Semaine 21 — Victor TASSART

## Mission
Création des templates VM + démarrage du portail NexaMind.

## Travail effectué cette semaine
- ✅ Résolu un problème de routage VPN OpenVPN (routes LAN non poussées)
- ✅ Créé la VM Template Debian (101) : install + nettoyage + conversion template
- ✅ Créé la VM Template Windows 10 (102) : drivers VirtIO + sysprep + template
- ✅ Documenté dans le repo Git (Infra/ + ACCES/)

## Taux de complétion de ma partie
30% — Les templates sont finis, le portail est démarré (code prêt, déploiement à venir).

## Difficultés rencontrées
- CPU type "host" incompatible avec le Kimsufi → passé à x86-64-v2-AES
- Sysprep Windows échoue (bug Appx 22H2) → contournement documenté
- Disque Windows invisible à l'install → drivers VirtIO chargés manuellement

## Retour d'expérience
Appris à créer des templates Proxmox réutilisables, et compris l'importance
du nettoyage d'identité (machine-id, SSH keys) avant le clonage.

## Prévisions semaine prochaine
- [ ] Déployer le portail sur une VM srv-web-1
- [ ] Mettre le portail en service systemd
- [ ] Commencer l'intégration API Claude

## Captures
[dashboard Proxmox avec les 2 templates]
```

---

*Un bon reporting = montrer une progression régulière. Le prof suit ça de près. 📈*
