#!/bin/bash

# Script de démarrage rapide pour la solution Phi-3.5 Financial Chat

set -e

echo "🚀 Démarrage de Phi-3.5-Financial Chat..."
echo ""

# Couleurs pour l'output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Vérifier que Docker et Docker Compose sont installés
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker n'est pas installé${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose n'est pas installé${NC}"
    exit 1
fi

echo -e "${BLUE}✓ Docker et Docker Compose trouvés${NC}"
echo ""

# Créer le fichier .env s'il n'existe pas
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 Création du fichier .env depuis .env.example${NC}"
    cp .env.example .env
    echo -e "${GREEN}✓ Fichier .env créé${NC}"
    echo ""
fi

# Vérifier la connexion à Ollama
OLLAMA_URL=$(grep OLLAMA_URL .env | cut -d '=' -f2)
echo -e "${BLUE}📡 Vérification de la connexion à Ollama...${NC}"
echo "   URL: $OLLAMA_URL"

if curl -s -f "$OLLAMA_URL/api/tags" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama est accessible${NC}"
else
    echo -e "${YELLOW}⚠️  Ollama n'est pas accessible sur $OLLAMA_URL${NC}"
    echo "   Assurez-vous que:"
    echo "   - Ollama tourne sur la machine"
    echo "   - L'URL dans .env est correcte"
    echo "   - Le port 11434 est ouvert (ou celui que vous avez configuré)"
    echo ""
    read -p "Voulez-vous continuer? (o/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}🐳 Démarrage des conteneurs...${NC}"
docker-compose up -d

echo ""
echo -e "${BLUE}⏳ Attente que les services démarrent...${NC}"
sleep 3

# Vérifier l'état des services
echo -e "${BLUE}📊 État des services:${NC}"
docker-compose ps

echo ""
echo -e "${YELLOW}⏳ Attente que le service API soit prêt...${NC}"

# Attendre que l'API soit prête
max_attempts=30
attempt=0
until [ $attempt -ge $max_attempts ]; do
    if curl -s -f http://localhost:5000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API est prête${NC}"
        break
    fi
    echo -n "."
    sleep 1
    attempt=$((attempt + 1))
done

if [ $attempt -ge $max_attempts ]; then
    echo -e "${RED}❌ Timeout: l'API n'a pas démarré${NC}"
    echo "Vérifiez les logs:"
    docker-compose logs api
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Démarrage réussi!${NC}"
echo ""
echo -e "${BLUE}🌐 Interface disponible sur:${NC}"
echo -e "   ${YELLOW}http://localhost:5000${NC}"
echo ""
echo -e "${BLUE}📋 Commandes utiles:${NC}"
echo "   - Voir les logs: ${YELLOW}docker-compose logs -f api${NC}"
echo "   - Arrêter: ${YELLOW}docker-compose down${NC}"
echo "   - Redémarrer: ${YELLOW}docker-compose restart${NC}"
echo ""
echo -e "${GREEN}🎉 Prêt à discuter avec Phi-3.5-Financial!${NC}"
echo ""
