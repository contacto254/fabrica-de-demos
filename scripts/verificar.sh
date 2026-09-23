#!/usr/bin/env bash
# Chequea que un demo este publicado y funcionando.
# Uso: bash scripts/verificar.sh <slug>
set -uo pipefail

. "$(dirname "$0")/entorno.sh"

SLUG="${1:?Falta el slug. Ej: bash scripts/verificar.sh petsmiles}"
HOST="${SLUG}demo.customerp.dev"

echo "Verificando https://$HOST"
echo

printf '  DNS ................ '
# Cada entorno trae una herramienta distinta: Git Bash tiene nslookup, la nube de
# Claude Code solo getent. Probamos las tres y usamos la que haya.
DEST=""
if command -v dig >/dev/null 2>&1; then
  DEST=$(dig +short CNAME "$HOST" @1.1.1.1 2>/dev/null | grep -o '[a-z0-9]\{8\}\.up\.railway\.app' | head -1)
elif command -v nslookup >/dev/null 2>&1; then
  DEST=$(nslookup -type=CNAME "$HOST" 1.1.1.1 2>/dev/null | grep -o '[a-z0-9]\{8\}\.up\.railway\.app' | head -1)
fi
if [ -n "$DEST" ]; then
  echo "OK -> $DEST"
elif command -v getent >/dev/null 2>&1 && IP=$(getent hosts "$HOST" 2>/dev/null | awk '{print $1}' | head -1) && [ -n "$IP" ]; then
  # getent sigue el CNAME hasta la IP final, asi que no vemos el destino, pero
  # que resuelva alcanza para saber que el DNS ya esta.
  echo "OK -> resuelve ($IP)"
else
  echo "todavia no resuelve"
fi

printf '  Certificado ........ '
if curl -s -o /dev/null --max-time 10 "https://$HOST/healthz" 2>/dev/null; then
  echo "OK"
else
  echo "todavia no (Railway lo emite unos minutos despues del DNS)"
fi

printf '  Servicio ........... '
SALUD=$(curl -s --max-time 10 "https://$HOST/healthz" 2>/dev/null)
if echo "$SALUD" | grep -q '"ok":true'; then echo "OK  $SALUD"; else echo "sin respuesta"; fi

printf '  Portada ............ '
TITULO=$(curl -s --max-time 15 "https://$HOST/" 2>/dev/null | grep -o '<title>[^<]*</title>' | head -1)
if [ -n "$TITULO" ]; then echo "OK  $TITULO"; else echo "sin respuesta"; fi

echo
echo "Estado del dominio en Railway:"
ID=$(railway domain list --service "$SLUG" 2>/dev/null | grep "$HOST" | awk '{print $3}')
if [ -n "$ID" ]; then
  railway domain status "$ID" 2>/dev/null | grep -E "Verified|Certificate status" | sed 's/^/  /'
else
  echo "  no encontre el dominio en el servicio $SLUG"
fi
echo
echo "  https://$HOST"
