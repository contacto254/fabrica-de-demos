# Fábrica de demos

Le pasás a Claude Code la web de una empresa. Te devuelve un link como
`empresademo.customerp.dev`: un ERP navegable, con los productos, los precios y la gente de
esa empresa adentro, listo para mostrárselo en una reunión.

Tarda entre veinte y cuarenta minutos. No hay que programar nada.

---

## Antes de empezar (una sola vez)

### 1. Instalar lo que hace falta

- [Node.js](https://nodejs.org) 22 o más nuevo.
- [Claude Code](https://claude.com/claude-code): `npm install -g @anthropic-ai/claude-code`
- Railway: `npm install -g @railway/cli` y después `railway login`.

### 2. El token de Cloudflare

Es lo único que hay que buscar a mano. Sirve para que el demo quede publicado en un
subdominio de `customerp.dev`.

1. Entrá a [dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens).
2. **Create Token** → plantilla **Edit zone DNS** → **Use template**.
3. En **Zone Resources**: `Include` → `Specific zone` → `customerp.dev`.
4. **Continue to summary** → **Create Token**.
5. Aparece un cuadro con el token. **Bajá el scroll dentro del cuadro**: arriba está el
   *Account ID*, que no sirve; el token está más abajo, debajo del título **Your API Token**.
   Son unos 40 caracteres con letras, números y guiones. Copialo, se muestra una sola vez.

Guardalo en la variable de entorno `CF_TOKEN`. En PowerShell, para dejarlo puesto siempre:

```powershell
setx CF_TOKEN "el-token-que-copiaste"
```

Cerrá y volvé a abrir la terminal para que tome.

### 3. Comprobar

```bash
git clone https://github.com/contacto254/fabrica-de-demos.git
cd fabrica-de-demos
bash scripts/requisitos.sh
```

Tienen que dar OK las cinco líneas.

---

> **¿El vendedor va a trabajar desde Chrome, sin instalar nada?**
> Entonces esta sección no aplica: la configuración es otra y está en
> [ENTORNO-WEB.md](ENTORNO-WEB.md).

## Hacer un demo

Abrí Claude Code en esta carpeta:

```bash
cd fabrica-de-demos
claude
```

Y escribí:

```
/nuevo-demo https://www.laempresa.com

Distribuidora de repuestos para maquinaria agrícola. Venden a talleres y
productores de todo el país. Hoy manejan todo con planillas y WhatsApp y
se les pierden los pedidos.
```

La descripción es opcional, pero cuanto más cuentes del negocio, más apunta el demo a lo que
a esa empresa le duele.

Claude va a leer la web, decidir qué módulos corresponden al rubro, construir el demo,
probarlo, publicarlo y devolverte el link. Podés seguirlo mientras trabaja.

Al final te entrega:

- El link, ya funcionando.
- La lista de módulos.
- Los tres o cuatro momentos que conviene mostrar primero en la reunión.
- Qué datos son reales de su web y cuáles se inventaron, para no quedar pagando si preguntan.

---

## Ajustar un demo ya hecho

En la misma conversación, o abriendo Claude Code de nuevo en la carpeta:

```
En el demo de laempresa, agregale un módulo de service técnico con
órdenes de trabajo y repuestos usados, y volvé a publicarlo.
```

Los cambios se publican en el mismo link.

---

## Si algo sale mal

**El link no abre.**
`bash scripts/verificar.sh <slug>` te dice en qué paso está. Lo más común es que el
certificado todavía se esté emitiendo: tarda unos minutos después de crear el DNS.

**"FALTA token de Cloudflare".**
La variable `CF_TOKEN` no está puesta, o quedó guardado el *Account ID* en vez del token.
El Account ID tiene 32 caracteres y es todo números y letras de la a a la f. El token tiene
unos 40 y lleva guiones. Volvé al punto 2.

**"FALTA sesión de Railway".**
`railway login`.

**El deploy falla.**
`railway logs --service <slug> --build` muestra el motivo.

---

## Qué hay acá adentro

```
ENTORNO-WEB.md                 para usarlo desde el navegador, sin instalar nada
.claude/skills/nuevo-demo/     la receta que sigue Claude Code
  SKILL.md                     el paso a paso
  referencias/diseno.md        cómo tiene que verse
  referencias/contenido.md     qué datos poner adentro
plantilla/                     el esqueleto de cada demo
scripts/
  requisitos.sh                chequea que esté todo instalado
  entorno.sh                   deja el PATH y el CLI listos en Windows y en Linux
  setup-nube.sh                arranque del entorno de Claude Code en el navegador
  publicar.sh                  sube a Railway y crea el DNS
  verificar.sh                 confirma que el link responde
demos/                         los demos que vayas creando
```

## Cómo funciona por debajo

Cada demo es un solo archivo HTML: sin bundler, sin framework, sin base de datos. Los datos
viven en memoria, así que el cliente puede tocar todo sin romper nada, y con recargar la
página vuelve al estado inicial.

Se sirve con un estático de veinte líneas sin dependencias, un servicio de Railway por demo
dentro del proyecto `customerp-demos`. El DNS es un CNAME en Cloudflare apuntando a Railway,
sin proxy: con el proxy encendido Railway no puede emitir el certificado.

---

## Demos hechos

| Empresa | Rubro | Link |
|---|---|---|
| Campo Mercado | Escritorio rural | https://campomercadodemo.customerp.dev |
| Pet Smiles | Salud dental para mascotas | https://petsmilesdemo.customerp.dev |
| In Vitro | Producción de embriones bovinos FIV | https://invitrodemo.customerp.dev |
