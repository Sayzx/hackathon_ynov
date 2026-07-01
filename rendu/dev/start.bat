@echo off
REM Script de démarrage rapide pour Windows

setlocal enabledelayedexpansion

echo 🚀 Demarrage de Phi-3.5-Financial Chat...
echo.

REM Vérifier que Docker et Docker Compose sont installés
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker n'est pas installe
    exit /b 1
)

docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose n'est pas installe
    exit /b 1
)

echo ✓ Docker et Docker Compose trouves
echo.

REM Créer le fichier .env s'il n'existe pas
if not exist .env (
    echo 📝 Creation du fichier .env depuis .env.example
    copy .env.example .env
    echo ✓ Fichier .env cree
    echo.
)

REM Démarrer les conteneurs
echo 🐳 Demarrage des conteneurs...
docker-compose up -d

echo.
echo ⏳ Attente que les services demarrent...
timeout /t 3 /nobreak

REM Vérifier l'état des services
echo.
echo 📊 Etat des services:
docker-compose ps

REM Attendre que l'API soit prête
echo.
echo ⏳ Attente que le service API soit pret...

setlocal enabledelayedexpansion
for /l %%i in (1,1,30) do (
    curl -s http://localhost:5000/health >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✓ API est prete
        goto :api_ready
    )
    echo.>nul
    timeout /t 1 /nobreak >nul
)

echo ❌ Timeout: l'API n'a pas demarré
docker-compose logs api
exit /b 1

:api_ready
echo.
echo ✅ Demarrage reussi!
echo.
echo 🌐 Interface disponible sur:
echo    http://localhost:5000
echo.
echo 📋 Commandes utiles:
echo    - Voir les logs: docker-compose logs -f api
echo    - Arreter: docker-compose down
echo    - Redemarrer: docker-compose restart
echo.
echo 🎉 Pret a discuter avec Phi-3.5-Financial!
echo.

pause
