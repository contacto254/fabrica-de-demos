---
name: nuevo-demo
description: Crea un demo de ERP a medida para una empresa y lo publica en <slug>demo.customerp.dev. Usalo cuando alguien pase la web de una empresa y quiera un demo navegable para mostrarle a ese cliente, o diga "nuevo demo", "armá un demo para X", "hacé el demo de esta empresa".
---

# Nuevo demo

Convertís la web de una empresa en un ERP de mentira pero navegable, y lo dejás publicado
en `<slug>demo.customerp.dev` para que el vendedor se lo muestre a esa empresa.

Lo que devolvés al final es **un link que funciona**. Nada de "ahora andá y hacé tal cosa":
el trabajo lo hacés vos entero, incluido el despliegue y el DNS.

## Qué te tienen que dar

Alcanza con la URL de la web de la empresa. Si además te dan una descripción de a qué se
dedican o qué les duele hoy, mejor.

Si no te dieron la web, pedila. Es lo único que no podés inventar.

## Antes de arrancar

Corré `bash scripts/requisitos.sh`. Si falta algo, resolvelo o decilo con claridad. No
empieces a construir un demo que después no vas a poder publicar.

Elegí el `slug`: una palabra, minúsculas, sin acentos ni espacios, derivada del nombre de la
empresa. `Campo Mercado` → `campomercado`. La dirección final es `<slug>demo.customerp.dev`.

## Paso 1 — Investigar la empresa

Leé la web con WebFetch. No te quedes con la portada: mirá también las páginas de productos
o servicios, "nosotros", precios y contacto. Buscá también su Instagram o LinkedIn si están.

Sacá de ahí, textual siempre que puedas:

- Nombre exacto, tagline, cómo hablan de sí mismos.
- Paleta de colores y tipografía. Si no publican los hex, deducilos de lo que ves.
- Catálogo o servicios con nombres y precios reales.
- Equipo: nombres y cargos.
- Contacto: dirección, teléfono, mail, redes.
- Cifras: años en el mercado, cantidad de clientes, cobertura, certificaciones.
- Testimonios y reseñas, con nombre y texto.

Todo esto va adentro del demo. **El efecto que buscás es que el cliente abra el link y vea
su propia empresa adentro del sistema**: sus productos, sus precios, sus clientes, su gente.
Ese es el 80% de la venta.

Si algo no está en la web, inventalo con criterio: tiene que ser verosímil para ese rubro y
ese país, y coherente con todo lo demás.

## Paso 2 — Decidir qué módulos lleva

No hay un ERP genérico. Mirá a qué se dedican y armá los módulos que esa empresa usaría
todos los días. Guía por tipo de negocio:

| Si la empresa... | Los módulos que no pueden faltar |
|---|---|
| vende productos físicos | catálogo, stock por depósito, compras e importación, costo landed, facturación, cobros, entregas |
| vende servicios o proyectos | presupuestos, proyectos con etapas, horas, hitos de cobro, facturación recurrente |
| intermedia entre partes | publicaciones, ofertas y contraofertas, comisiones, garantía o custodia del dinero |
| atiende clientes finales | bandeja unificada (WhatsApp, web, redes), ficha de cliente, recompra, suscripciones |
| trabaja con el agro | hacienda o cultivos, campos, trazabilidad, faena o cosecha, precios de referencia |
| tiene equipo en la calle | ruta del día, estado de visitas, metas por vendedor, ranking |

Poné siempre, sea cual sea el rubro: un panel de inicio con lo que pasa hoy, una vista de
clientes o contactos, algo de plata (facturación y cobranza), reportes con gráficos, y
configuración. Y siempre la búsqueda con Ctrl+K.

Adaptá el vocabulario al rubro. Un escritorio rural no dice "clientes", dice "productores".
Una distribuidora no dice "proyectos", dice "pedidos". Esto se nota muchísimo.

## Paso 3 — Construir

Copiá `plantilla/` a `demos/<slug>/` y escribí `demos/<slug>/public/index.html`. Reemplazá
`DEMO_SLUG` en `server.js` y `package.json` por el slug.

Leé antes estas dos referencias, que son la diferencia entre un mockup y algo que se vende:

- `referencias/diseno.md` — el sistema visual, los iconos, los estados.
- `referencias/contenido.md` — qué datos poner adentro y cómo hacerlos coherentes.

Reglas duras del archivo:

- **Un solo archivo HTML.** Sin bundler, sin framework, sin CDN de JavaScript. Lo único
  externo que se permite es una fuente de Google Fonts.
- **Sin emojis.** Iconos SVG de línea propios, en un sprite de `<symbol>` al principio del
  `<body>`, usados con `<use>`.
- **Sin `prompt()`, `confirm()` ni `alert()`.** Modales propios, con el estilo de la app.
- **En español rioplatense**, con voseo, y con los acentos bien puestos. UTF-8.
- **Todo tiene que responder al clic.** Si algo no hace nada, no lo pongas. Un botón que no
  responde le dice al cliente "esto es humo", y es lo único que se va a llevar.

Tamaño esperado: entre 2.000 y 4.000 líneas. Si te queda mucho más corto, le faltan
módulos o le faltan datos.

## Paso 4 — Probarlo de verdad

Antes de publicar:

1. Sintaxis: extraé el contenido del `<script>` a un archivo aparte en el directorio
   temporal y corré `node --check`.
2. Emojis. **No uses `grep -P` con rangos unicode: en Windows devuelve 0 siempre**, aunque el
   archivo esté lleno de emojis. Usá esto, que tiene que imprimir `0`:

   ```bash
   node -e 'const s=require("fs").readFileSync(process.argv[1],"utf8");const m=s.match(/\p{Extended_Pictographic}/gu)||[];console.log(m.length,[...new Set(m)].join(" "))' demos/<slug>/public/index.html
   ```

   Y que tampoco queden caracteres haciendo de icono:

   ```bash
   node -e 'const s=require("fs").readFileSync(process.argv[1],"utf8");for(const c of ["✓","✔","×","✕","•","▲","▼","→","←","★"]){const n=s.split(c).length-1;if(n)console.log(c,n)}' demos/<slug>/public/index.html
   ```

   El guión largo como "sin dato" en una tabla puede quedarse: eso es tipografía, no un icono.
3. Nativos: `grep -nE '\b(prompt|confirm|alert)\(' demos/<slug>/public/index.html` tampoco.
4. Acentos: `grep -c 'Ã' demos/<slug>/public/index.html` tiene que dar 0.
5. Levantalo local (`PORT=3999 node server.js`) y pedí la portada con curl: tiene que venir
   el `<title>` correcto.

Recorré mentalmente el camino que va a hacer el cliente: entra, mira el panel, hace clic en
el menú de arriba abajo, abre una ficha, prueba el buscador, arrastra una tarjeta. En cada
punto preguntate si algo puede romperse o quedar vacío.

## Paso 5 — Publicar

```
CF_TOKEN=<token> bash scripts/publicar.sh <slug> demos/<slug>
```

El script sube el servicio a Railway, le da el subdominio, crea el CNAME y el TXT de
verificación en Cloudflare, y espera a que el certificado quede emitido. Termina
imprimiendo el link.

Si el certificado tarda, corré `bash scripts/verificar.sh <slug>` unos minutos después. No
entregues el link sin haber visto que responde.

## Paso 6 — Entregar

Commiteá y pusheá el demo. Después devolvé, en pocas líneas:

- El link.
- Qué módulos tiene, en una lista corta.
- Los tres o cuatro momentos de la demo que conviene mostrar primero (por ejemplo: "entrá
  por la bandeja, importá el pedido web y mostrá cómo sale la factura y se arma la entrega").
- Qué datos son reales de su web y cuáles inventaste, para que el vendedor no quede pagando.
