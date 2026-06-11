@echo off
REM ============================================
REM Lancement rapide du portail NexaMind (Windows)
REM Double-clique sur ce fichier pour démarrer
REM ============================================

echo ====================================
echo   NexaMind Portal - Demarrage
echo ====================================
echo.

REM Créer l'environnement virtuel s'il n'existe pas
if not exist "venv\" (
    echo Creation de l'environnement Python...
    python -m venv venv
)

REM Activer le venv
call venv\Scripts\activate

REM Installer les dépendances
echo Installation des dependances...
pip install -r requirements.txt --quiet

REM Lancer le serveur
echo.
echo ====================================
echo   Portail lance !
echo   Ouvre : http://127.0.0.1:8000
echo   Login : admin / admin123
echo   (Ctrl+C pour arreter)
echo ====================================
echo.
uvicorn main:app --reload --host 0.0.0.0 --port 8000
