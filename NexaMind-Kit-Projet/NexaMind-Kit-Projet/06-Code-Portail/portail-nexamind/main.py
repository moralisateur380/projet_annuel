"""
NexaMind Portal - Application principale FastAPI
Portail client sécurisé pour les services d'audit de sécurité NexaMind SAS

Lancement local :
    uvicorn main:app --reload --host 0.0.0.0 --port 8000
"""

from fastapi import FastAPI, Request, Form, Depends, HTTPException, status
from fastapi.responses import HTMLResponse, RedirectResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from starlette.middleware.sessions import SessionMiddleware
import bcrypt
import sqlite3
import json
import os
from datetime import datetime
from pathlib import Path

# ============================================================
# Configuration
# ============================================================
app = FastAPI(title="NexaMind Portal", version="1.0")

# Session (pour garder l'utilisateur connecté)
# En production, mettre une vraie clé secrète aléatoire dans une variable d'env
app.add_middleware(SessionMiddleware, secret_key="nexamind-change-this-secret-key-in-prod")

templates = Jinja2Templates(directory="templates")
app.mount("/static", StaticFiles(directory="static"), name="static")

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), hashed.encode("utf-8"))

DB_PATH = "nexamind.db"

# ============================================================
# Base de données SQLite
# ============================================================
def init_db():
    """Crée les tables et insère des données de démo au premier lancement."""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    # Table utilisateurs
    c.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'client',
            company TEXT
        )
    """)

    # Table audits
    c.execute("""
        CREATE TABLE IF NOT EXISTS audits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client TEXT NOT NULL,
            titre TEXT NOT NULL,
            statut TEXT NOT NULL,
            date_debut TEXT,
            progression INTEGER DEFAULT 0
        )
    """)

    # Table devis
    c.execute("""
        CREATE TABLE IF NOT EXISTS devis (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client TEXT NOT NULL,
            description TEXT,
            montant REAL,
            statut TEXT DEFAULT 'en attente',
            date_creation TEXT
        )
    """)

    # Table alertes (simule les remontées du SOC Wazuh)
    c.execute("""
        CREATE TABLE IF NOT EXISTS alertes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            niveau TEXT NOT NULL,
            source TEXT,
            description TEXT,
            timestamp TEXT,
            analyse_ia TEXT
        )
    """)

    # Insertion de données de démo si la table users est vide
    c.execute("SELECT COUNT(*) FROM users")
    if c.fetchone()[0] == 0:
        # Comptes de démo
        users = [
            ("admin", hash_password("admin123"), "admin", "NexaMind SAS"),
            ("client1", hash_password("client123"), "client", "ACME Corp"),
        ]
        c.executemany("INSERT INTO users (username, password_hash, role, company) VALUES (?, ?, ?, ?)", users)

        # Audits de démo
        audits = [
            ("ACME Corp", "Audit infrastructure réseau", "En cours", "2026-05-15", 65),
            ("ACME Corp", "Test d'intrusion applicatif", "Planifié", "2026-06-10", 0),
            ("ACME Corp", "Audit conformité RGPD", "Terminé", "2026-04-01", 100),
        ]
        c.executemany("INSERT INTO audits (client, titre, statut, date_debut, progression) VALUES (?, ?, ?, ?, ?)", audits)

        # Devis de démo
        devis = [
            ("ACME Corp", "Audit complet SI + SOC managé (3 mois)", 12500.0, "en attente", "2026-05-20"),
            ("ACME Corp", "Test d'intrusion annuel", 4800.0, "accepté", "2026-04-15"),
        ]
        c.executemany("INSERT INTO devis (client, description, montant, statut, date_creation) VALUES (?, ?, ?, ?, ?)", devis)

        # Alertes de démo (simule le SOC)
        alertes = [
            ("critique", "192.168.20.52", "Brute-force détecté sur le portail (47 tentatives en 30s)", "2026-06-01 19:30", None),
            ("moyen", "192.168.20.10", "Scan de ports détecté (nmap)", "2026-06-01 18:15", None),
            ("faible", "192.168.20.15", "Connexion hors horaires habituels", "2026-06-01 02:45", None),
        ]
        c.executemany("INSERT INTO alertes (niveau, source, description, timestamp, analyse_ia) VALUES (?, ?, ?, ?, ?)", alertes)

    conn.commit()
    conn.close()


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


# ============================================================
# Helpers d'authentification
# ============================================================
def get_current_user(request: Request):
    """Récupère l'utilisateur connecté depuis la session."""
    return request.session.get("user")


def require_login(request: Request):
    user = get_current_user(request)
    if not user:
        raise HTTPException(status_code=status.HTTP_303_SEE_OTHER, headers={"Location": "/"})
    return user


# ============================================================
# Routes
# ============================================================
@app.on_event("startup")
def startup():
    init_db()


@app.get("/", response_class=HTMLResponse)
async def login_page(request: Request, error: str = None):
    # Si déjà connecté, rediriger vers le dashboard
    if get_current_user(request):
        return RedirectResponse(url="/dashboard", status_code=303)
    return templates.TemplateResponse(request, "login.html", {"error": error})


@app.post("/login")
async def login(request: Request, username: str = Form(...), password: str = Form(...)):
    conn = get_db()
    user = conn.execute("SELECT * FROM users WHERE username = ?", (username,)).fetchone()
    conn.close()

    if user and verify_password(password, user["password_hash"]):
        request.session["user"] = {
            "username": user["username"],
            "role": user["role"],
            "company": user["company"],
        }
        return RedirectResponse(url="/dashboard", status_code=303)

    # Échec : on redirige avec un message d'erreur
    # (c'est ce log d'échec que Wazuh détectera lors du brute-force)
    return RedirectResponse(url="/?error=Identifiants+invalides", status_code=303)


@app.get("/logout")
async def logout(request: Request):
    request.session.clear()
    return RedirectResponse(url="/", status_code=303)


@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request):
    user = get_current_user(request)
    if not user:
        return RedirectResponse(url="/", status_code=303)

    conn = get_db()
    # Stats pour le dashboard
    nb_audits = conn.execute("SELECT COUNT(*) as n FROM audits").fetchone()["n"]
    nb_devis = conn.execute("SELECT COUNT(*) as n FROM devis WHERE statut='en attente'").fetchone()["n"]
    nb_alertes = conn.execute("SELECT COUNT(*) as n FROM alertes WHERE niveau='critique'").fetchone()["n"]
    audits = conn.execute("SELECT * FROM audits ORDER BY id DESC LIMIT 5").fetchall()
    alertes = conn.execute("SELECT * FROM alertes ORDER BY id DESC LIMIT 3").fetchall()
    conn.close()

    return templates.TemplateResponse(request, "dashboard.html", {"user": user,
        "nb_audits": nb_audits,
        "nb_devis": nb_devis,
        "nb_alertes": nb_alertes,
        "audits": audits,
        "alertes": alertes,})


@app.get("/audits", response_class=HTMLResponse)
async def audits_page(request: Request):
    user = get_current_user(request)
    if not user:
        return RedirectResponse(url="/", status_code=303)

    conn = get_db()
    audits = conn.execute("SELECT * FROM audits ORDER BY id DESC").fetchall()
    conn.close()
    return templates.TemplateResponse(request, "audits.html", {"user": user, "audits": audits})


@app.get("/devis", response_class=HTMLResponse)
async def devis_page(request: Request):
    user = get_current_user(request)
    if not user:
        return RedirectResponse(url="/", status_code=303)

    conn = get_db()
    devis = conn.execute("SELECT * FROM devis ORDER BY id DESC").fetchall()
    conn.close()
    return templates.TemplateResponse(request, "devis.html", {"user": user, "devis": devis})


@app.get("/alertes", response_class=HTMLResponse)
async def alertes_page(request: Request):
    user = get_current_user(request)
    if not user:
        return RedirectResponse(url="/", status_code=303)

    conn = get_db()
    alertes = conn.execute("SELECT * FROM alertes ORDER BY id DESC").fetchall()
    conn.close()
    return templates.TemplateResponse(request, "alertes.html", {"user": user, "alertes": alertes})


# ============================================================
# API : endpoint pour recevoir une alerte du SOC (Wazuh)
# ============================================================
@app.post("/api/alerte")
async def recevoir_alerte(request: Request):
    """
    Endpoint pour que Wazuh pousse une alerte vers le portail.
    Exemple d'appel depuis Wazuh (integration custom) :
    POST /api/alerte  {"niveau": "critique", "source": "1.2.3.4", "description": "..."}
    """
    data = await request.json()
    conn = get_db()
    conn.execute(
        "INSERT INTO alertes (niveau, source, description, timestamp, analyse_ia) VALUES (?, ?, ?, ?, ?)",
        (
            data.get("niveau", "moyen"),
            data.get("source", "inconnu"),
            data.get("description", ""),
            datetime.now().strftime("%Y-%m-%d %H:%M"),
            None,
        ),
    )
    conn.commit()
    conn.close()
    return JSONResponse({"status": "ok", "message": "Alerte enregistrée"})


# ============================================================
# API : génération de devis avec Claude (à compléter avec ta clé)
# ============================================================
@app.post("/api/generer-devis")
async def generer_devis(request: Request):
    """
    Génère un devis automatique via l'API Claude.
    Pour activer : décommente le bloc et ajoute ta clé API Anthropic.
    """
    data = await request.json()
    besoin = data.get("besoin", "")

    # ---- VERSION SANS API (mock pour démarrer) ----
    devis_mock = {
        "description": f"Prestation sur mesure : {besoin}",
        "montant_estime": 8500,
        "details": "Audit + remédiation + rapport (estimation automatique)",
    }
    return JSONResponse(devis_mock)

    # ---- VERSION AVEC API CLAUDE (à activer) ----
    # import anthropic
    # client = anthropic.Anthropic(api_key="TA_CLE_API")
    # message = client.messages.create(
    #     model="claude-sonnet-4-20250514",
    #     max_tokens=600,
    #     messages=[{
    #         "role": "user",
    #         "content": f"""Tu es commercial chez NexaMind, entreprise de cybersécurité.
    # Un client exprime ce besoin : "{besoin}"
    # Génère un devis structuré en JSON avec : description, montant_estime (en euros),
    # et details (les prestations incluses). Réponds UNIQUEMENT en JSON valide."""
    #     }]
    # )
    # import json as _json
    # texte = message.content[0].text
    # return JSONResponse(_json.loads(texte))
