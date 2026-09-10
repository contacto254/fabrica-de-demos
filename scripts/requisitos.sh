#!/usr/bin/env bash
# Verifica que esta maquina tenga todo lo necesario para crear y publicar un demo.
# Uso: bash scripts/requisitos.sh
set -uo pipefail

export PATH="/c/Program Files/nodejs:/c/Program Files/Git/bin:/c/Program Files/GitHub CLI:$HOME/AppData/Roaming/npm:$PATH"

FALTA=0
ok()    { printf '  \033[32mOK\033[0m    %s\n' "$1"; }
falta() { printf '  \033[31mFALTA\033[0m %s\n' "$1"; printf '        %s\n' "$2"; FALTA=1; }

echo "Requisitos para publicar un demo"
echo

command -v node >/dev/null \
  && ok "node $(node -v)" \
  || falta "node" "Instalalo desde nodejs.org (hace falta 22 o mas nuevo)."

command -v railway >/dev/null \
  && ok "railway CLI $(railway --version 2>/dev/null | head -1)" \
  || falta "railway CLI" "npm install -g @railway/cli"

if command -v railway >/dev/null; then
  QUIEN=$(railway whoami 2>&1 | head -1)
  case "$QUIEN" in
    *"Logged in"*) ok "$QUIEN" ;;
    *) falta "sesion de Railway" "railway login" ;;
  esac
fi

if [ -n "${CF_TOKEN:-}" ]; then
  R=$(curl -s "https://api.cloudflare.com/client/v4/zones?name=customerp.dev" \
        -H "Authorization: Bearer $CF_TOKEN")
  if echo "$R" | grep -q '"success":true'; then
    ok "token de Cloudflare con acceso a customerp.dev"
  else
    falta "token de Cloudflare" "El token no sirve para esta zona. Mira el README, seccion 'Antes de empezar'."
  fi
else
  falta "CF_TOKEN" "Falta la variable de entorno. Mira el README, seccion 'Antes de empezar'."
fi

command -v git >/dev/null && ok "git $(git --version | awk '{print $3}')" || falta "git" "Instalalo desde git-scm.com"
command -v gh   >/dev/null && ok "gh CLI" || printf '  \033[33mOPCIONAL\033[0m gh CLI (solo si vas a versionar el demo en GitHub)\n'

echo
if [ "$FALTA" -eq 0 ]; then
  echo "Todo listo. Segui con el README."
else
  echo "Resolve lo que falta y volve a correr esto."
  exit 1
fi
