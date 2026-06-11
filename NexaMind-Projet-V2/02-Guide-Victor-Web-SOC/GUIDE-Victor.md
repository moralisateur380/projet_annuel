# 👤 GUIDE VICTOR — Portail Web + SOC Wazuh

> Ta partie est **quasi terminée** : le portail et Wazuh fonctionnent.
> Ce guide documente ce qui est fait (pour le rapport) + les finitions.

---

## ✅ Ce qui est DÉJÀ fait

### Portail web (srv-web-1, 192.168.20.20)
- Portail FastAPI + Jinja2 + SQLite + bcrypt
- nginx en reverse proxy (port 80 → uvicorn 8000)
- Service systemd `nexamind` (démarrage auto)
- Pages : login, dashboard, alertes, audits, devis
- API `/api/alerte` pour recevoir les alertes Wazuh
- Comptes démo : admin/admin123, client1/client123

### SOC Wazuh (srv-wazuh-1, 192.168.20.22)
- Wazuh 4.9.2 en Docker (manager + indexer + dashboard)
- Disque agrandi (partition dédiée Docker)
- Agent Wazuh installé sur srv-web-1
- 3 règles de détection : tentative login, brute-force, scan
- Intégration alertes → portail configurée
- Attaque de test détectée ✅

---

## 🔧 Tes finitions restantes

### 1. Brancher l'IA Claude sur le portail

Le portail est codé pour utiliser Claude (devis + analyse d'alertes), il manque juste la clé API.

**Étapes** :
1. Créer un compte sur https://console.anthropic.com/
2. Ajouter du crédit (quelques euros suffisent pour la démo)
3. Créer une clé API (commence par `sk-ant-...`)
4. Dans `main.py`, fonction `generer_devis()`, décommenter le bloc API Claude
5. Mettre la clé via variable d'environnement (PAS en dur dans le code !) :

```bash
# Éditer le service pour ajouter la clé
sudo nano /etc/systemd/system/nexamind.service
# Ajouter sous [Service] :
#   Environment="ANTHROPIC_API_KEY=sk-ant-..."
sudo systemctl daemon-reload
sudo systemctl restart nexamind
```

> 🔐 La clé API ne doit JAMAIS être commitée sur Git. Mettre dans Passbolt.

### 2. Étendre Wazuh aux autres VM

Pour un vrai SOC, Wazuh doit surveiller toute l'infra, pas juste le web.

→ Voir `06-Scripts-Configuration/installer-agent-wazuh.sh`
→ À installer sur : srv-ad-1 (104), client-win-1 (106)

Une fois fait, Wazuh détectera aussi les attaques sur l'Active Directory.

---

## 🎤 Ton rôle en soutenance

Tu présentes 2 morceaux clés (vers 13-25 min) :

### Le SOC Wazuh (le moment fort)
1. Montre le dashboard Wazuh + les agents connectés
2. **Lance l'attaque** (ou coordonne avec Marwane sur Kali)
3. **En direct**, montre l'alerte qui apparaît dans Wazuh
4. Explique les règles de détection

### Le portail NexaMind
1. Montre le portail (login, dashboard, navigation)
2. La page Alertes où les détections remontent
3. Le générateur de devis IA (si la clé est branchée)

**Phrase de transition** : *"Notre SOC ne se contente pas de détecter, il remonte
l'information dans notre portail client et l'IA Claude l'analyse en langage clair."*

---

## 📋 Procédures techniques (rappel)

### Relancer le portail
```bash
sudo systemctl restart nexamind
sudo systemctl status nexamind
```

### Relancer Wazuh
```bash
cd ~/wazuh-docker/single-node
docker compose up -d
docker ps
```

### Voir les alertes Wazuh
Dashboard → Threat Hunting → rechercher :
```
rule.id:100090 OR rule.id:100100 OR rule.id:100101
```

### Lancer une attaque de test
```bash
# Depuis une autre VM (pas srv-web-1)
./attaque-test.sh
```

---

## 🆘 Dépannage

| Problème | Solution |
|---|---|
| Portail "Internal Server Error" | Vérifier que le venv existe + DB créée (`ls *.db`) |
| Wazuh ne démarre pas | Vérifier l'espace disque (`df -h`) |
| Agent pas connecté | Vérifier ports 1514/1515 + firewall pfSense |
| Pas d'alerte détectée | Vérifier que l'agent lit les logs nginx |

---

*Ta partie est solide. Finis l'IA Claude et aide les autres avec les agents Wazuh. 💪*
