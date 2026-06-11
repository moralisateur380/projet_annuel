# 📜 SCRIPTS DE CONFIGURATION — Mode d'emploi

> Tous les scripts pour configurer les machines. **Lis bien sur QUELLE machine
> lancer chaque script** — c'est la cause n°1 d'erreurs !

---

## 🗺️ Quel script, sur quelle machine, par qui

| Script | Sur quelle VM | Qui | Ce qu'il fait |
|---|---|---|---|
| `install-wazuh-docker.sh` | srv-wazuh-1 (201) | Victor | Installe Wazuh en Docker |
| `agrandir-docker.sh` | srv-wazuh-1 (201) | Victor | Agrandit l'espace disque Docker |
| `detection-1-serveur-web.sh` | srv-web-1 (200) | Victor | Agent surveille les logs nginx |
| `detection-2-manager-wazuh.sh` | srv-wazuh-1 (201) | Victor | Crée les règles de détection |
| `installer-agent-wazuh.sh` | srv-ad-1, client-win... | Victor/Jacques | Connecte une VM au SOC |
| `config-active-directory.sh` | srv-ad-1 (104) | Jacques | Crée users/groupes AD |
| `config-suricata.sh` | srv-soc-1 (107) | Marwane | Installe l'IDS réseau |
| `attaque-test.sh` | Kali ou autre (PAS web) | Marwane | Lance une attaque de test |

---

## ⚠️ RÈGLE D'OR : vérifier où tu es AVANT de lancer

Avant chaque script, tape :
```bash
hostname
```
Et vérifie que tu es sur la BONNE machine. Le prompt `root@srv-XXX` te le dit aussi.

**Ne jamais lancer un script d'install sur le template** (srv-debian-template) !

---

## 📋 Comment lancer un script

```bash
# 1. Créer le fichier
nano nom-du-script.sh
# (coller le contenu, Ctrl+O, Entrée, Ctrl+X)

# 2. Le rendre exécutable
chmod +x nom-du-script.sh

# 3. Passer root si pas déjà fait
su -

# 4. Lancer
./nom-du-script.sh
```

---

## 🔄 Ordre de déploiement complet (de zéro)

Si vous repartez de zéro, voici l'ordre logique :

### Phase 1 — Infrastructure (Abdoul)
1. pfSense configuré (déjà fait)
2. VPN configuré (déjà fait)

### Phase 2 — Services de base
3. `config-active-directory.sh` sur srv-ad-1 (Jacques)
4. Passbolt rempli (Marwane, manuel)

### Phase 3 — SOC (Victor) — DÉJÀ FAIT
5. `install-wazuh-docker.sh` sur srv-wazuh-1
6. `agrandir-docker.sh` si manque d'espace
7. `detection-1-serveur-web.sh` sur srv-web-1
8. `detection-2-manager-wazuh.sh` sur srv-wazuh-1

### Phase 4 — Étendre la surveillance
9. `installer-agent-wazuh.sh` sur srv-ad-1 (et autres)
10. `config-suricata.sh` sur srv-soc-1 (Marwane)

### Phase 5 — Attaque et démo
11. Créer Kali (Marwane)
12. `attaque-test.sh` pour tester la détection

---

## 🆘 Si un script échoue

1. **Lis le message d'erreur** (souvent explicite)
2. **Vérifie que tu es sur la bonne machine** (`hostname`)
3. **Vérifie que tu es en root** (`whoami` → root)
4. Les scripts s'arrêtent proprement en cas de problème et disent quoi faire

---

*Chaque script a été conçu pour être sûr et afficher ce qu'il fait. Suis l'ordre. 🚀*
