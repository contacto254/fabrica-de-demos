# Configurar Claude Code en el navegador

Para que alguien pueda hacer demos desde Chrome, sin instalar nada, entrando a
[claude.ai/code](https://claude.ai/code).

Esto lo configura una vez el administrador. Después el vendedor sólo entra, elige el
repositorio y escribe `/nuevo-demo` con la web de la empresa.

## Cómo es el entorno de la nube

Cada sesión corre en una máquina virtual de Anthropic con Ubuntu, 4 procesadores y 16 GB de
memoria. Trae node, npm, git, la herramienta de línea de comandos de GitHub y curl. La
máquina se crea limpia cada vez; lo único que sobrevive es lo que haya dejado el script de
arranque, que queda cacheado.

Dos cosas no vienen resueltas y hay que configurarlas:

1. **El cliente de Railway no está instalado.** Lo pone el script de arranque.
2. **La salida a internet está filtrada.** Por defecto sólo deja pasar los repositorios de
   paquetes y GitHub. Ni Cloudflare ni Railway están permitidos, así que hay que autorizarlos
   a mano.

## Los cuatro pasos

### 1. La cuenta de GitHub

El vendedor entra con la cuenta `contacto254`, la misma de siempre, así que los repositorios
privados los ve sin más trámite. La primera vez que abra claude.ai/code le va a pedir conectar
GitHub: se conecta con esa cuenta y listo.

Si en algún momento conviene que tenga la suya propia, se lo agrega como colaborador:

```bash
gh repo add-collaborator contacto254/fabrica-de-demos <usuario> --permission push
gh repo add-collaborator contacto254/customerp-demos  <usuario> --permission push
```

### 2. Crear el entorno en la nube

En [claude.ai/code](https://claude.ai/code), en el selector de entorno, **Add cloud
environment**. Ahí adentro:

**Setup script.** Pegar el contenido de `scripts/setup-nube.sh`. Instala el cliente de
Railway. Corre una sola vez y queda cacheado.

**Network access.** Cambiar de `Trusted` a `Custom` y agregar estos dominios:

```
api.cloudflare.com
backboard.railway.com
railway.app
*.railway.app
*.up.railway.app
customerp.dev
*.customerp.dev
```

Sin esto, el script de publicación falla al crear el DNS y al hablar con Railway. Con
`Trusted` a secas no alcanza. También sirve poner `Full`, pero abre la salida a todo internet
y no hace falta.

Los dominios de las empresas que se van a investigar con WebFetch no necesitan estar acá:
esa herramienta no pasa por el filtro de la máquina.

**Environment variables.** Dos, en formato `.env`:

```
CF_TOKEN=<el token de Cloudflare>
RAILWAY_API_TOKEN=<el token de Railway>
```

Cuidado: cualquiera que use ese entorno puede leerlas. Si el plan es Pro o Max, conviene
usar **API credentials** en vez de variables: ahí el token lo inyecta un intermediario de
Anthropic después de que la petición sale de la máquina, y ni Claude ni los comandos llegan a
verlo. Se configura en la misma pantalla, indicando el sitio permitido y la cabecera
`Authorization: Bearer <token>`.

### 3. Los dos tokens

**Cloudflare.** En
[dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens):
Create Token, plantilla **Edit zone DNS**, en Zone Resources elegir `customerp.dev`. En la
pantalla final, el token está debajo del título **Your API Token**, no en la caja de arriba
que dice Account ID.

**Railway.** En [railway.com/account/tokens](https://railway.com/account/tokens): crear uno
de cuenta, sin atarlo a un proyecto, para que pueda crear servicios nuevos. Ese va en
`RAILWAY_API_TOKEN`.

### 4. Probar

El vendedor entra a claude.ai/code, elige el repositorio `fabrica-de-demos` y el entorno
recién creado, y escribe:

```
bash scripts/requisitos.sh
```

Tienen que dar bien las cinco líneas. Si Railway aparece sin sesión, falta el token o el
dominio no quedó permitido.

## Cómo lo usa el vendedor

```
/nuevo-demo https://www.laempresa.com

Distribuidora de repuestos para maquinaria agrícola. Venden a talleres y
productores. Hoy manejan todo con planillas y WhatsApp.
```

Y espera. Al final recibe el link publicado, la lista de módulos y qué mostrar primero en la
reunión.

## Lo que conviene saber

- La sesión sigue corriendo aunque cierre el navegador, y puede volver después.
- Si la deja quieta mucho rato, la máquina se recicla y se pierde lo que no esté commiteado.
  Por eso la receta commitea y publica antes de terminar.
- Sólo puede subir cambios a la rama de su sesión.
- El consumo se cuenta contra el límite de la cuenta, igual que cualquier otro uso de Claude.
- Un demo tarda entre veinte y cuarenta minutos.
