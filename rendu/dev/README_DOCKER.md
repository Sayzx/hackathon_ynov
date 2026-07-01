# 💰 Chat Phi-3.5-Financial - Docker Edition

Interface web moderne pour communiquer avec Phi-3.5-Financial via Ollama. **Configuration complète en 1 commande.**

---

## ⚡ Démarrage ultra-rapide

### Sur Linux/Mac:
```bash
cd rendu/dev
bash start.sh
```

### Sur Windows:
```bash
cd rendu\dev
start.bat
```

L'interface est disponible sur: **http://localhost:5000**

---

## 🐳 Manuel Docker

### Démarrage
```bash
# Créer le fichier .env (optionnel, .env.example est utilisé par défaut)
cp .env.example .env

# Lancer les conteneurs
docker-compose up -d

# Attendre ~10 secondes que le service démarre
```

### Arrêt
```bash
docker-compose down
```

### Voir les logs
```bash
docker-compose logs -f api
```

### Redémarrer
```bash
docker-compose restart
```

---

## ⚙️ Configuration

### Changer l'URL d'Ollama

**Avant de démarrer**, créez un fichier `.env`:

```bash
cp .env.example .env
```

Modifiez `.env`:
```
OLLAMA_URL=http://10.0.0.5:11434
DEFAULT_MODEL=phi3.5
API_PORT=5000
```

Puis démarrez:
```bash
docker-compose up -d
```

### Obtenir l'URL d'Ollama auprès de l'équipe INFRA

L'équipe INFRA fournira une URL comme:
- `http://localhost:11434` (local)
- `http://192.168.1.100:11434` (réseau interne)
- `http://ollama.company.com:11434` (DNS)
- `https://ollama.api.company.com` (production)

Mettez-la dans `.env`:
```
OLLAMA_URL=<URL_FOURNIE_PAR_INFRA>
```

---

## 📋 Architecture

```
┌──────────────────────────────┐
│   Navigateur                 │
│   http://localhost:5000      │
└──────────────┬───────────────┘
               │
         ┌─────▼──────┐
         │  Conteneur │
         │   Flask    │
         │  (Port 5000)
         │            │
         │ - Frontend │
         │ - Proxy    │
         │ - CORS     │
         │ - Streaming│
         └─────┬──────┘
               │
    ┌──────────▼──────────────┐
    │   Ollama (Externe)      │
    │   (Équipe INFRA)        │
    │   :11434                │
    └─────────────────────────┘
```

---

## ✅ Vérification

### Vérifier que tout fonctionne

```bash
# 1. Vérifier l'état des conteneurs
docker-compose ps

# 2. Vérifier la connexion à Ollama
docker-compose exec api curl http://localhost:5000/health

# 3. Ouvrir dans le navigateur
# http://localhost:5000
```

### Tester l'API directement

```bash
# Lister les modèles disponibles
curl -X GET http://localhost:5000/api/models

# Tester la génération (sans streaming)
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"phi3.5","prompt":"Bonjour","stream":false}'
```

---

## 🐛 Dépannage

### L'interface affiche "Serveur indisponible"

```bash
# 1. Vérifier que le conteneur tourne
docker-compose ps

# 2. Voir les logs
docker-compose logs api

# 3. Vérifier la connexion à Ollama depuis le conteneur
docker-compose exec api curl http://localhost:11434/api/tags

# Si ça ne marche pas, l'URL d'Ollama dans .env est mauvaise
# Corrigez-la et redémarrez:
docker-compose restart
```

### Port 5000 déjà utilisé

```bash
# Modifier .env
API_PORT=8080

# Puis redémarrer
docker-compose down
docker-compose up -d

# Accéder sur http://localhost:8080
```

### Connexion refusée à Ollama

```bash
# Vérifier qu'Ollama tourne
curl http://localhost:11434/api/tags

# Si ça ne marche pas:
# 1. L'équipe INFRA doit avoir lancé Ollama
# 2. L'URL dans .env est incorrecte
# 3. Ollama n'est pas sur localhost, mettre l'IP correcte
```

### Logs du conteneur

```bash
# Voir les 50 dernières lignes
docker-compose logs --tail=50 api

# Suivre les logs en temps réel
docker-compose logs -f api

# Voir les logs d'une date/heure
docker-compose logs api --since 10m
```

---

## 📊 Fichiers

```
rendu/dev/
├── docker-compose.yml       # Orchestration des services
├── Dockerfile               # Configuration du conteneur
├── server.py               # API Flask
├── index.html              # Frontend Vue.js
├── requirements.txt        # Dépendances Python
├── .env.example            # Configuration par défaut
├── .dockerignore           # Fichiers à ignorer
├── start.sh                # Script de démarrage (Linux/Mac)
├── start.bat               # Script de démarrage (Windows)
├── README_DOCKER.md        # Ce fichier
└── DOCKER_README.md        # Documentation détaillée
```

---

## 🔧 Options avancées

### Activer le debug

```bash
# Créer .env
FLASK_ENV=development
FLASK_DEBUG=1

# Redémarrer
docker-compose restart
```

### Personnaliser le modèle par défaut

```bash
# Dans .env
DEFAULT_MODEL=mistral
```

### Changer le port du frontend

```bash
# Dans .env
API_PORT=8080
```

### Utiliser un volume personnalisé

```yaml
# Dans docker-compose.yml
volumes:
  - ./index.html:/app/index.html:ro
  - ./custom_config.json:/app/config.json:ro
```

---

## 📈 Performance

### Optimisations appliquées

- ✅ Image Python slim (taille réduite)
- ✅ Multi-stage build possible
- ✅ Health checks configurés
- ✅ Restart policy
- ✅ Volume read-only pour l'interface
- ✅ Streaming en temps réel

### Pour la production

```bash
# Utiliser Docker Buildkit
DOCKER_BUILDKIT=1 docker-compose build

# Vérifier la taille
docker images phi-api

# Optimiser davantage
docker-compose -f docker-compose.yml up -d --scale api=2
```

---

## 🚀 Prochaines étapes

- [ ] Intégrer avec Triton Inference Server
- [ ] Ajouter la persistance de l'historique
- [ ] Support du multi-utilisateur
- [ ] Métriques Prometheus
- [ ] Logging centralisé (ELK)
- [ ] Load balancing (Nginx)

---

## 📞 Support

### L'interface ne démarre pas
```bash
docker-compose logs api
```

### Ollama n'est pas accessible
Contacter l'équipe INFRA pour:
- L'URL correcte d'Ollama
- Le port à utiliser
- Les droits d'accès réseau

### Questions sur Docker
```bash
docker-compose --help
docker --help
```

---

## 📝 Notes

- Aucune donnée n'est stockée en dehors du conteneur
- Les conversions sont perdues au redémarrage (persistance future possible)
- Ollama est géré indépendamment par l'équipe INFRA
- CORS sont gérés automatiquement par Flask

**Enjoy! 🎉**
