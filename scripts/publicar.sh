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

# ---------- 1. Railway ----------
cd "$DIR" || exit 1

echo
echo "1/5  Servicio en Railway"
# Railway tiene dos tipos de token y se usan distinto:
#   RAILWAY_TOKEN      es de proyecto: ya viene apuntando a un proyecto.
#   RAILWAY_API_TOKEN  es de cuenta: hay que elegirle el proyecto con 'railway link'.
# Ojo con el 'set -o pipefail' de arriba: filtrar con una tuberia devuelve el
# codigo de railway y no el del grep, asi que la salida se guarda antes.
PRUEBA=$(railway status 2>&1 || true)
if [ -n "${RAILWAY_TOKEN:-}" ] && printf '%s' "$PRUEBA" | grep -qi 'invalid railway_token'; then
  if [ -n "${RAILWAY_API_TOKEN:-}" ]; then
    echo "     RAILWAY_TOKEN no sirve; sigo con RAILWAY_API_TOKEN (token de cuenta)"
    unset RAILWAY_TOKEN
  else
    echo "     RAILWAY_TOKEN no sirve y no hay RAILWAY_API_TOKEN para caer atras"
    exit 1
  fi
fi

# Con token de cuenta hay que elegir el proyecto ANTES de preguntar nada: que
# diga "no linked project" sin haber linkeado todavia es lo esperado, no un error.
if [ -z "${RAILWAY_TOKEN:-}" ]; then
  SALIDA_LINK=$(railway link --project "$PROYECTO" --environment production 2>&1 || true)
  if printf '%s' "$SALIDA_LINK" | grep -qiE 'unauthoriz|invalid|not found|no projects'; then
    echo "     No pude entrar al proyecto '$PROYECTO'. Railway dijo:"
    printf '%s\n' "$SALIDA_LINK" | sed 's/^/       /' | head -10
    echo
    echo "     El token de cuenta tiene que pertenecer a la cuenta duena de ese proyecto."
    exit 1
  fi
  echo "     proyecto $PROYECTO"
fi

# Recien ahora tiene sentido preguntar el estado.
ESTADO=$(railway status 2>&1 || true)
if printf '%s' "$ESTADO" | grep -qiE 'unauthoriz|not logged|invalid token|invalid railway'; then
  echo "     Railway no acepta el token:"
  printf '%s\n' "$ESTADO" | sed 's/^/       /' | head -8
  echo
  echo "     Tokens que llegaron a este script:"
  [ -n "${RAILWAY_TOKEN:-}" ]     && echo "       RAILWAY_TOKEN      si" || echo "       RAILWAY_TOKEN      no"
  [ -n "${RAILWAY_API_TOKEN:-}" ] && echo "       RAILWAY_API_TOKEN  si" || echo "       RAILWAY_API_TOKEN  no"
  exit 1
fi
printf '%s\n' "$ESTADO" | head -4 | sed 's/^/       /'

# El servicio puede existir de una corrida anterior.
if printf '%s' "$ESTADO" | grep -q "$SLUG"; then
  echo "     el servicio ya existe"
else
  SALIDA_ADD=$(railway add --service "$SLUG" 2>&1 || true)
  if printf '%s' "$SALIDA_ADD" | grep -qiE 'unauthoriz|invalid|forbidden'; then
    echo "     No pude crear el servicio. Railway dijo:"
    printf '%s\n' "$SALIDA_ADD" | sed 's/^/       /' | head -12
    exit 1
  fi
  echo "     servicio creado"
fi

# Con token de cuenta, apuntar tambien al servicio antes de subir.
if [ -z "${RAILWAY_TOKEN:-}" ]; then
  railway link --project "$PROYECTO" --environment production --service "$SLUG" >/dev/null 2>&1 || true
fi

echo
echo "2/5  Subiendo (tarda 1-2 minutos)"
# La salida se guarda entera: cuando esto falla, lo unico que sirve es lo que
# dijo Railway, y antes se perdia en el pipe.
SALIDA_UP=$(railway up --service "$SLUG" --ci 2>&1)
if echo "$SALIDA_UP" | grep -q "Deploy complete"; then
  echo "     desplegado"
else
  echo "     El deploy fallo. Esto dijo Railway:"
  echo "$SALIDA_UP" | sed 's/^/       /' | tail -30
  echo
  echo "     Para ver el detalle del build:  railway logs --service $SLUG --build"
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
