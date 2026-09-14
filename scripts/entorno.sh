#!/usr/bin/env bash
# Deja el PATH listo tanto en Windows (Git Bash) como en Linux (Claude Code en la nube).
# Se incluye desde los otros scripts con:  . "$(dirname "$0")/entorno.sh"

if [ -d "/c/Program Files/nodejs" ]; then
  # Windows: el PATH de Git Bash no trae node, git, gh ni los binarios de npm.
  export PATH="/c/Program Files/nodejs:/c/Program Files/Git/bin:/c/Program Files/GitHub CLI:$HOME/AppData/Roaming/npm:$PATH"
else
  # Linux / macOS: los binarios globales de npm.
  export PATH="$PATH:$HOME/.npm-global/bin:/usr/local/bin:$HOME/.railway/bin"
fi

# El CLI de Railway no viene preinstalado en la nube.
if ! command -v railway >/dev/null 2>&1; then
  if [ "${INSTALAR_RAILWAY:-1}" = "1" ]; then
    echo "  Instalando el CLI de Railway..."
    npm install -g @railway/cli >/dev/null 2>&1 || npm install -g @railway/cli
  fi
fi

# Autenticacion sin navegador: el CLI toma el token de la variable de entorno.
# RAILWAY_TOKEN es de un proyecto puntual: es el que usa GitHub Actions, y alcanza
# para desplegar y crear servicios dentro de customerp-demos.
# RAILWAY_API_TOKEN es de cuenta, y sirve ademas para crear proyectos nuevos.
if [ -z "${RAILWAY_API_TOKEN:-}" ] && [ -z "${RAILWAY_TOKEN:-}" ]; then
  if ! railway whoami >/dev/null 2>&1; then
    echo "  Aviso: Railway sin credenciales. Falta RAILWAY_TOKEN o RAILWAY_API_TOKEN."
  fi
fi
