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
# RAILWAY_TOKEN es de un proyecto puntual: alcanza para desplegar y crear
# servicios dentro de customerp-demos, y el proyecto ya viene fijado por el token.
# RAILWAY_API_TOKEN es de cuenta, sirve para cualquier proyecto, y por eso ademas
# hay que linkear el proyecto a mano.
#
# Railway rechaza un token de cuenta guardado con el nombre del de proyecto, y el
# mensaje ("Invalid RAILWAY_TOKEN") no dice que el problema es el nombre. Como la
# pagina donde se crean los dos es la misma, el error es facil de cometer y caro
# de encontrar: si el token no pasa como de proyecto, lo probamos como de cuenta.
if [ -n "${RAILWAY_TOKEN:-}" ] && [ -z "${RAILWAY_API_TOKEN:-}" ]; then
  if ! railway status --json >/dev/null 2>&1; then
    if RAILWAY_API_TOKEN="$RAILWAY_TOKEN" RAILWAY_TOKEN="" railway whoami >/dev/null 2>&1; then
      echo "  El token de Railway es de cuenta, no de proyecto: lo uso como RAILWAY_API_TOKEN."
      export RAILWAY_API_TOKEN="$RAILWAY_TOKEN"
      unset RAILWAY_TOKEN
    fi
  fi
fi

if [ -z "${RAILWAY_API_TOKEN:-}" ] && [ -z "${RAILWAY_TOKEN:-}" ]; then
  if ! railway whoami >/dev/null 2>&1; then
    echo "  Aviso: Railway sin credenciales. Falta RAILWAY_TOKEN o RAILWAY_API_TOKEN."
  fi
fi
