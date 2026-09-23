# Que un colega haga demos desde el navegador

Entrando a [claude.ai/code](https://claude.ai/code) desde Chrome, sin instalar nada.

## La idea

Claude Code en el navegador corre en una máquina virtual de Anthropic **con la salida a
internet filtrada**: llega a GitHub y a los repositorios de paquetes, pero no a Railway ni a
Cloudflare. Se puede abrir ese filtro a mano, pero entonces cada persona que use el sistema
necesita su entorno configurado y los tokens cargados, y eso se rompe en cuanto entra alguien
nuevo.

Así que el publicado no ocurre ahí. Ocurre en GitHub Actions:

```
el colega arma el demo  →  git push  →  GitHub publica  →  link
     (en el navegador)                    (sin filtro)
```

Los tokens viven como secretos del repositorio, no en el entorno de cada persona. El colega
nunca los ve ni los necesita.

## Configuración, una sola vez

### 1. Los dos secretos del repositorio

Es lo único que hay que hacer, y lo hace quien tenga acceso a las dos cuentas.

**Cloudflare.** En
[dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens):
Create Token → plantilla **Edit zone DNS** → en Zone Resources elegir `customerp.dev`. En la
pantalla final el token está debajo del título **Your API Token**; la caja de arriba dice
*Account ID* y no sirve.

Copialo con el botón de copiar que trae Cloudflare, no seleccionando con el mouse: si se
corta un carácter, la API contesta `9109 Invalid access token` y no hay forma de darse cuenta
mirándolo.

**Railway.** En [railway.com/account/tokens](https://railway.com/account/tokens). Hay dos
tipos y sirve cualquiera, pero cada uno va en su secreto:

| Tipo | Secreto | Cómo se crea |
| --- | --- | --- |
| De proyecto | `RAILWAY_TOKEN` | Eligiendo `customerp-demos` en el desplegable |
| De cuenta | `RAILWAY_API_TOKEN` | Sin elegir proyecto |

No son intercambiables: un token de cuenta cargado en `RAILWAY_TOKEN` devuelve
`Invalid RAILWAY_TOKEN`. El de cuenta es el más cómodo, porque además puede **crear** el
servicio del demo la primera vez.

Con los dos a mano:

```bash
gh secret set CF_TOKEN          --repo contacto254/fabrica-de-demos
gh secret set RAILWAY_API_TOKEN --repo contacto254/fabrica-de-demos
```

Cada comando pide el valor y no lo deja escrito en ningún lado. También se pueden cargar
desde la web, en **Settings → Secrets and variables → Actions**.

Para comprobar que quedaron:

```bash
gh secret list --repo contacto254/fabrica-de-demos
```

### 2. Nada más

No hace falta tocar la configuración del entorno en claude.ai. Ni permitir dominios, ni
cargar variables, ni script de arranque. El colega entra con la cuenta `contacto254`, elige
el repositorio `fabrica-de-demos` y ya puede trabajar.

## Cómo lo usa el colega

```
/nuevo-demo https://www.laempresa.com

Distribuidora de repuestos para maquinaria agrícola. Venden a talleres y
productores. Hoy manejan todo con planillas y WhatsApp.
```

Claude lee la web, arma el demo, lo prueba y lo empuja. El publicado arranca solo y él lo
sigue desde la misma conversación con `gh run watch`. En unos cuatro minutos tiene el link.

## Si algo sale mal

**El flujo falla diciendo que faltan secretos.** No están cargados, o quedaron con otro
nombre. Volvé al punto 1. El resumen del flujo trae los comandos exactos.

**No se sabe cuál de los tokens quedó mal.** El flujo lo dice solo: al empezar imprime qué
secretos ve y cuántos caracteres mide cada uno, sin mostrar nunca el contenido. Un largo
raro suele ser un copiado que se cortó.

**Railway o Cloudflare rechazan el token.** El registro del paso *Publicar* trae la
respuesta textual del servicio, no un "revisá el token" a secas. `Invalid RAILWAY_TOKEN`
es un token de cuenta puesto en el secreto de proyecto; `9109 Invalid access token` de
Cloudflare es un token vencido, revocado o cortado al copiar.

**El colega dice que no puede llegar a Railway.** Es lo esperado y no hay que arreglarlo: la
receta está escrita para que en ese caso empuje y deje publicar a GitHub.

**El link no responde al terminar.** El certificado tarda unos minutos más que el resto.
`bash scripts/verificar.sh <slug>` dice en qué paso está.

## Lo que conviene saber

- La sesión sigue corriendo aunque cierre el navegador.
- Si la deja quieta mucho rato, la máquina se recicla y se pierde lo que no esté empujado.
  Por eso la receta empuja antes de terminar.
- Sólo puede empujar a la rama de su sesión. El flujo publica igual desde cualquier rama.
- El consumo se cuenta contra el límite de la cuenta, como cualquier otro uso de Claude.
- Un demo tarda entre veinte y cuarenta minutos, más cuatro de publicado.

## Si preferís el otro camino

Se puede abrir el entorno en vez de usar Actions: en claude.ai/code, editando el entorno,
**Network access** en `Custom` con `api.cloudflare.com`, `backboard.railway.com`,
`railway.app`, `*.railway.app`, `*.up.railway.app`, `customerp.dev` y `*.customerp.dev`;
**Environment variables** con `CF_TOKEN` y `RAILWAY_API_TOKEN`; y en **Setup script** el
contenido de `scripts/setup-nube.sh`, que instala el cliente de Railway.

Funciona, y la receta lo detecta y publica directo. Pero hay que repetirlo por cada persona
y por cada entorno, las variables quedan legibles para cualquiera que use ese entorno, y hay
que acordarse de abrir sesión nueva para que tomen. Por eso el camino recomendado es el otro.
