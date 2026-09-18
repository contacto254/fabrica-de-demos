#!/usr/bin/env bash
# Publica un demo: lo sube a Railway, le da el subdominio y crea el DNS en Cloudflare.
#
# Uso:  CF_TOKEN=xxx bash scripts/publicar.sh <slug> <carpeta-del-demo>
# Ej:   CF_TOKEN=xxx bash scripts/publicar.sh petsmiles ./demos/petsmiles
#
# El slug define la direccion final: <slug>demo.customerp.dev
set -uo pipefail

. "$(dirname "$0")/entorno.sh"

SLUG="${1:?Falta el slug. Ej: bash scripts/publicar.sh petsmiles ./demos/petsmiles}"
DIR="${2:?Falta la carpeta del demo}"
: "${CF_TOKEN:?Falta CF_TOKEN. Mira el README, seccion 'Antes de empezar'.}"

PROYECTO="customerp-demos"
ZONA="customerp.dev"
HOST="${SLUG}demo.${ZONA}"
API="https://api.cloudflare.com/client/v4"

[ -f "$DIR/public/index.html" ] || { echo "No encuentro $DIR/public/index.html"; exit 1; }
[ -f "$DIR/server.js" ]         || { echo "No encuentro $DIR/server.js"; exit 1; }

echo "== Demo $SLUG -> https://$HOST =="

# ---------- 0. Credenciales ----------
# Las dos se prueban juntas y se informan las dos. Cuando una falla, el resto del
# script no llega a tocar la otra, y saber cual de las dos hay que rehacer es la
# diferencia entre arreglarlo en un minuto o a ciegas.
echo
echo "0/5  Credenciales"
MAL=0

RW_QUIEN=$(railway whoami 2>&1)
if echo "$RW_QUIEN" | grep -qi "invalid\|unauthor\|not logged"; then
  RW_PROY=$(railway status 2>&1)
  if echo "$RW_PROY" | grep -qi "invalid\|unauthor"; then
    echo "     Railway ..... NO SIRVE"
    echo "       $(echo "$RW_QUIEN" | head -1)"
    echo "       El token no pasa ni como de proyecto ni como de cuenta. Suele ser que"
    echo "       esta vencido, revocado, cortado al copiarlo, o que es de otra cosa"
    echo "       (el Account ID de Railway, o el token de Cloudflare)."
    echo "       Se rehace en https://railway.com/account/tokens"
    MAL=1
  else
    echo "     Railway ..... OK (token de proyecto)"
  fi
else
  echo "     Railway ..... OK ($(echo "$RW_QUIEN" | head -1))"
fi

CF_ZONA=$(curl -s "$API/zones?name=$ZONA" -H "Authorization: Bearer $CF_TOKEN")
if echo "$CF_ZONA" | grep -q '"success":true' && echo "$CF_ZONA" | grep -q '"id":"'; then
  echo "     Cloudflare .. OK (zona $ZONA)"
else
  echo "     Cloudflare .. NO SIRVE"
  echo "       $(echo "$CF_ZONA" | head -c 200)"
  echo "       Hace falta un token con permiso Edit zone DNS sobre $ZONA."
  echo "       Se rehace en https://dash.cloudflare.com/profile/api-tokens"
  MAL=1
fi

[ "$MAL" = "1" ] && { echo; echo "     Sin credenciales validas no puedo publicar."; exit 1; }

# ---------- 1. Railway ----------
cd "$DIR" || exit 1

echo
echo "1/5  Servicio en Railway"
if railway status --json 2>/dev/null | grep -q "\"name\":\"$SLUG\""; then
  echo "     ya existe"
else
  SALIDA_ADD=$(railway add --service "$SLUG" 2>&1)
  if [ $? -eq 0 ]; then
    echo "     creado"
  else
    echo "     No pude crear el servicio:"
    echo "$SALIDA_ADD" | sed 's/^/       /'
    exit 1
  fi
fi
# Con un token de proyecto (RAILWAY_TOKEN) el proyecto ya viene fijado por el token, y
# 'railway link' no tiene con que sesion resolver el nombre: solo se linkea si no hay token.
if [ -z "${RAILWAY_TOKEN:-}" ]; then
  SALIDA_LINK=$(railway link --project "$PROYECTO" --environment production --service "$SLUG" 2>&1)
  if [ $? -ne 0 ]; then
    echo "     No pude linkear el proyecto $PROYECTO:"
    echo "$SALIDA_LINK" | sed 's/^/       /'
    exit 1
  fi
fi

echo
echo "2/5  Subiendo (tarda 1-2 minutos)"
# La salida entera, no las ultimas tres lineas: cuando esto falla el motivo esta
# arriba del todo y sin el no hay forma de saber que paso desde el registro.
SALIDA_UP=$(railway up --service "$SLUG" --ci 2>&1)
if echo "$SALIDA_UP" | grep -q "Deploy complete"; then
  echo "     desplegado"
else
  echo "     El deploy fallo. Esto dijo Railway:"
  echo "$SALIDA_UP" | tail -25 | sed 's/^/       /'
  echo
  echo "     Contexto:"
  railway status 2>&1 | head -12 | sed 's/^/       /'
  echo "       servicios del proyecto:"
  railway service list 2>&1 | head -12 | sed 's/^/         /'
  exit 1
fi

echo
echo "3/5  Dominio propio en Railway"
SALIDA=$(railway domain "$HOST" --service "$SLUG" 2>&1)
CNAME_TARGET=$(echo "$SALIDA" | grep -o '[a-z0-9]\{8\}\.up\.railway\.app' | head -1)
VERIFY_TXT=$(echo "$SALIDA"  | grep -o 'railway-verify=[a-f0-9]\{64\}' | head -1)

if [ -z "$CNAME_TARGET" ]; then
  # El dominio ya estaba dado de alta: pedimos su estado para sacar los datos.
  ID=$(railway domain list --service "$SLUG" 2>/dev/null | grep "$HOST" | awk '{print $3}')
  SALIDA=$(railway domain status "$ID" 2>&1)
  CNAME_TARGET=$(echo "$SALIDA" | grep -o '[a-z0-9]\{8\}\.up\.railway\.app' | head -1)
  VERIFY_TXT=$(echo "$SALIDA"  | grep -o 'railway-verify=[a-f0-9]\{64\}' | head -1)
fi
[ -z "$CNAME_TARGET" ] && { echo "     No pude leer el destino del CNAME:"; echo "$SALIDA"; exit 1; }
echo "     CNAME -> $CNAME_TARGET"

# ---------- 2. Cloudflare ----------
cd - >/dev/null || exit 1

echo
echo "4/5  DNS en Cloudflare"
ZONE=$(curl -s "$API/zones?name=$ZONA" -H "Authorization: Bearer $CF_TOKEN" \
       | grep -o '"id":"[a-f0-9]\{32\}"' | head -1 | cut -d'"' -f4)
[ -z "$ZONE" ] && { echo "     No pude leer la zona $ZONA. Revisa el token."; exit 1; }

upsert() { # tipo nombre contenido
  local TYPE="$1" NAME="$2" CONTENT="$3" ID BODY RES
  ID=$(curl -s "$API/zones/$ZONE/dns_records?type=$TYPE&name=$NAME" \
       -H "Authorization: Bearer $CF_TOKEN" \
       | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{const j=JSON.parse(s);console.log(j.result&&j.result[0]?j.result[0].id:"")}catch(e){console.log("")}})')
  # proxied en false a proposito: con el proxy encendido Railway no puede emitir el certificado.
  BODY=$(node -e "console.log(JSON.stringify({type:process.argv[1],name:process.argv[2],content:process.argv[3],ttl:1,proxied:false}))" "$TYPE" "$NAME" "$CONTENT")
  if [ -n "$ID" ]; then
    RES=$(curl -s -X PUT "$API/zones/$ZONE/dns_records/$ID" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" --data "$BODY")
  else
    RES=$(curl -s -X POST "$API/zones/$ZONE/dns_records" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json" --data "$BODY")
  fi
  echo "$RES" | grep -q '"success":true' && echo "     $TYPE $NAME OK" || { echo "     $TYPE $NAME FALLO"; echo "$RES" | head -c 300; echo; }
}

upsert CNAME "$HOST" "$CNAME_TARGET"
[ -n "$VERIFY_TXT" ] && upsert TXT "_railway-verify.$HOST" "$VERIFY_TXT"

# ---------- 3. Esperar el certificado ----------
echo
echo "5/5  Esperando el certificado (hasta 3 minutos)"
for i in $(seq 1 18); do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "https://$HOST/healthz" 2>/dev/null)
  if [ "$CODE" = "200" ]; then
    echo "     listo"
    echo
    echo "   https://$HOST"
    echo
    exit 0
  fi
  printf '     .'
  sleep 10
done

echo
echo "     Todavia no responde. El DNS y el certificado pueden tardar unos minutos mas."
echo "     Volve a probar con: bash scripts/verificar.sh $SLUG"
echo
echo "   https://$HOST"
