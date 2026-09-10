#!/usr/bin/env bash
# Verifica que este entorno tenga todo lo necesario para crear y publicar un demo.
# Anda igual en Windows (Git Bash) y en la nube de Claude Code (Ubuntu).
# Uso: bash scripts/requisitos.sh
set -uo pipefail

. "$(dirname "$0")/entorno.sh"

FALTA=0
ok()    { printf '  \033[32mOK\033[0m    %s\n' "$1"; }
falta() { printf '  \033[31mFALTA\033[0m %s\n' "$1"; printf '        %s\n' "$2"; FALTA=1; }

if [ -d "/c/Program Files/nodejs" ]; then DONDE="Windows"; else DONDE="Linux (probablemente la nube)"; fi
echo "Requisitos para publicar un demo  ·  $DONDE"
echo

command -v node >/dev/null \
  && ok "node $(node -v)" \
  || falta "node" "Instalalo desde nodejs.org (hace falta 22 o mas nuevo)."

command -v railway >/dev/null \
  && ok "railway CLI $(railway --version 2>/dev/null | head -1)" \
  || falta "railway CLI" "npm install -g @railway/cli"

# La sesion vale por login interactivo (escritorio) o por token de cuenta (nube).
if command -v railway >/dev/null; then
  QUIEN=$(railway whoami 2>&1 | head -1)
  case "$QUIEN" in
    *"Logged in"*) ok "$QUIEN" ;;
    *)
      if [ -n "${RAILWAY_API_TOKEN:-}" ]; then
        if railway list >/dev/null 2>&1; then
          ok "Railway autenticado con RAILWAY_API_TOKEN"
        else
          falta "token de Railway" "RAILWAY_API_TOKEN esta puesto pero no funciona. Puede ser que falte permitir railway.app en la red del entorno. Mira ENTORNO-WEB.md."
        fi
      else
        falta "sesion de Railway" "En el escritorio: railway login. En la nube: poner RAILWAY_API_TOKEN en las variables del entorno (ver ENTORNO-WEB.md)."
      fi
      ;;
  esac
fi

if [ -n "${CF_TOKEN:-}" ]; then
  R=$(curl -s --max-time 20 "https://api.cloudflare.com/client/v4/zones?name=customerp.dev" \
        -H "Authorization: Bearer $CF_TOKEN" 2>&1)
  if echo "$R" | grep -q '"success":true'; then
    ok "token de Cloudflare con acceso a customerp.dev"
  elif [ -z "$R" ]; then
    falta "salida a api.cloudflare.com" "No hubo respuesta. En la nube hay que permitir el dominio en Network access. Mira ENTORNO-WEB.md."
  else
    falta "token de Cloudflare" "El token no sirve para esta zona. Ojo con haber copiado el Account ID en lugar del token. Mira ENTORNO-WEB.md."
  fi
else
  falta "CF_TOKEN" "Falta la variable de entorno. Mira el README, seccion 'Antes de empezar'."
fi

command -v git >/dev/null && ok "git $(git --version | awk '{print $3}')" || falta "git" "Instalalo desde git-scm.com"
command -v gh   >/dev/null && ok "gh CLI" || printf '  \033[33mOPCIONAL\033[0m gh CLI (solo si vas a versionar el demo en GitHub)\n'

echo
if [ "$FALTA" -eq 0 ]; then
  echo "Todo listo. Escribi /nuevo-demo con la web de la empresa."
else
  echo "Resolve lo que falta y volve a correr esto."
  exit 1
fi
