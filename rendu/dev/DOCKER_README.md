# 🐳 Chat Phi-3.5-Financial avec Docker

Configuration Docker pour l'interface web et le serveur backend. **Ollama est géré par l'équipe INFRA**.

---

## 🚀 Démarrage rapide

### Prérequis
- Docker et Docker Compose installés
- Ollama lancé par l'équipe INFRA (accessible sur `http://localhost:11434`)

### Lancer la solution complète

```bash
# 1. Se placer dans le répertoire
cd rendu/dev

# 2. Démarrer les conteneurs
docker-compose up -d

# 3. Vérifier que tout est lancé
docker-compose ps
```

Accédez à l'interface:
```
http://localhost:5000
```

---

## 📋 Services

### API (Flask)
- **Port**: 5000
- **URL**: http://localhost:5000
- **Rôle**: Proxy vers Ollama + Serveur frontend

### Frontend (Vue.js 3)
- Servie par le même conteneur que l'API
- Interface web réactive
- Gère le streaming en temps réel

### Ollama
- **Géré par**: Équipe INFRA
- **Port**: 11434 (sur le host)
- **URL de connexion interne**: `http://localhost:11434`

---

## 🔧 Configuration

### Changer l'URL d'Ollama

Modifiez le fichier `docker-compose.yml`:

```yaml
environment:
  - OLLAMA_URL=http://10.0.0.5:11434  # Remplacez par l'URL de votre Ollama
```

### Changer le modèle par défaut

```yaml
environment:
  - DEFAULT_MODEL=phi3.5  # Remplacez par votre modèle
```

### Personnaliser le port du frontend

```yaml
ports:
  - "8080:5000"  # Accès sur http://localhost:8080
```

---

## 📊 Commandes Docker utiles

```bash
# Voir les logs en temps réel
docker-compose logs -f api

# Arrêter les conteneurs
docker-compose down

# Reconstruire les images
docker-compose build --no-cache

# Vérifier la santé des services
docker-compose ps

# Exécuter une commande dans le conteneur
docker-compose exec api curl http://localhost:5000/health
```

---

## ✅ Vérification

### Via Docker
```bash
# Vérifier que le service répond
docker-compose exec api curl http://localhost:5000/health
```

### Via terminal/curl
```bash
# Tester l'API
curl -X POST http://localhost:5000/api/models

# Tester la génération
curl -X POST http://localhost:5000/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"phi3.5","prompt":"Bonjour","stream":false}'
```

### Via navigateur
```
http://localhost:5000
```

---

## 🐛 Dépannage

### "Connection refused" à Ollama

```bash
# Vérifier qu'Ollama tourne sur le host
curl http://localhost:11434/api/tags

# Si Ollama tourne ailleurs, mettre à jour docker-compose.yml:
OLLAMA_URL=http://<ip-ollama>:11434
```

### Conteneur ne démarre pas

```bash
# Voir les logs d'erreur
docker-compose logs api

# Vérifier la santé
docker-compose ps

# Reconstruire
docker-compose build --no-cache
```

### Port 5000 déjà utilisé

```bash
# Modifier docker-compose.yml:
ports:
  - "8080:5000"  # Accès sur port 8080
```

---

## 📁 Structure

```
rendu/dev/
├── Dockerfile           # Configuration du conteneur
├── docker-compose.yml   # Orchestration des services
├── server.py           # API Flask
├── index.html          # Frontend Vue.js
├── requirements.txt    # Dépendances Python
├── .dockerignore       # Fichiers à ignorer
└── DOCKER_README.md    # Ce fichier
```

---

## 🎯 Architecture

```
┌─────────────────────────────────────┐
│        Navigateur (Port 5000)       │
│     http://localhost:5000           │
└────────────────┬────────────────────┘
                 │
                 ↓
        ┌────────────────┐
        │   Conteneur    │
        │   API (Flask)  │
        │   :5000        │
        │                │
        │  - Proxy       │
        │  - CORS        │
        │  - Streaming   │
        └────────┬───────┘
                 │
                 ↓
    ┌────────────────────────────┐
    │  Ollama (Host/External)    │
    │  http://localhost:11434    │
    │  (Géré par équipe INFRA)   │
    └────────────────────────────┘
```

---

## 📝 Notes

- Les données ne quittent jamais votre infrastructure
- Ollama est géré séparément par l'équipe INFRA
- Le conteneur Flask gère les CORS et le streaming automatiquement
- Volume read-only pour le frontend = pas de modifications en runtime

---

## 🚀 Production

Pour un déploiement production:

```yaml
# Dans docker-compose.yml
api:
  environment:
    - FLASK_ENV=production
    - FLASK_DEBUG=0
```

Utilisez un reverse proxy (nginx) devant le conteneur pour gérer les certificats SSL et le load balancing.

