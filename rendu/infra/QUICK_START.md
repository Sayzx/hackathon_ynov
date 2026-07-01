# ⚡ Quick Start (5-10 minutes)

## 1️⃣ Prérequis

- Docker + Docker Compose ([installer](https://docs.docker.com/get-docker/))
- 15 GB d'espace disque
- 8 GB RAM

## 2️⃣ Lancer

### Linux / macOS
```bash
cd rendu/infra
./deploy-docker.sh install
```

### Windows
```powershell
cd rendu\infra
.\deploy.ps1 -Action install
```

## 3️⃣ Vérifier

```bash
./health-check.sh
# Ou
curl http://localhost:11434/api/tags
```

## 4️⃣ Tester

```bash
./test-api.sh
```

## 5️⃣ Utiliser (Pour DEV WEB)

```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "phi-financial",
    "prompt": "What is investment?",
    "stream": false
  }'
```

## 📖 Plus d'info

Voir: [README.md](./README.md)
