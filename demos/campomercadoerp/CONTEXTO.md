# Campo Mercado — contexto del demo

Esto es para quien agarre este archivo sin haber estado en la conversación donde se armó.
Leelo antes de tocar nada.

## Qué es

Un demo de ERP para **vender**, no un sistema en producción. Campo Mercado SAS es un
escritorio rural uruguayo: intermedia entre productores que venden hacienda y frigoríficos o
invernadores que la compran, y vive de la comisión. El demo se le muestra a **Santiago
Storace**, de la dirección de Campo Mercado.

Es la **segunda** versión. La primera se mostró en una reunión inicial; esta suma todo lo que
Storace pidió después: conciliación bancaria, asientos contables, facturación electrónica,
comisiones y metas por agente, y la conexión con la app de lotes.

Hoy usan **BF Zafra**, un sistema viejo de escritorio Windows. Sacaron fotos de dos pantallas
y de ahí salió el modelo de datos de este demo.

## La idea que ordena todo

> El ERP es, en el fondo, una máquina de liquidar kilos y calcular comisiones.

La unidad **no es la factura, es el negocio**. Un negocio junta vendedor, comprador, tropa,
guías, plazos y comisiones en un solo objeto. La facturación y la contabilidad son
consecuencias de ese objeto, nunca el punto de partida.

El corazón del sistema es un estado intermedio: **el negocio está cerrado pero el importe
todavía no**. Se define después, cuando llega el peso real de balanza y el rendimiento.

## Reglas duras del archivo

No son sugerencias; si las rompés, el demo deja de cumplir el estándar del repo.

- **Un solo archivo HTML.** Sin bundler, sin framework, sin CDN de JavaScript. Lo único
  externo permitido es una fuente de Google Fonts.
- **Sin emojis** y sin caracteres haciendo de icono (`✓`, `→`, `▲`, `×`). Todo se dibuja con
  SVG de línea, en un sprite de `<symbol>` al principio del `<body>`.
- **Sin `prompt()`, `confirm()` ni `alert()`.** Modales propios.
- **Español rioplatense con voseo**, acentos correctos, UTF-8.
- **Todo responde al clic.** Un botón que no hace nada mata la venta.
- Los datos viven en memoria y **se reinician al recargar**. Es a propósito: hay un botón
  "Reiniciar demo" para dejarlo limpio antes de cada reunión.

## Los cálculos

Esto es lo que no podés equivocar. Dos formas de liquidar según el tipo de negocio:

```
frigorífico (gordo, se cierra con la faena)
  kgNeto  = kgCarcasa                     ← segunda balanza
  rend    = kgCarcasa / kgBruto × 100
  importe = kgCarcasa × precio            ← precio en USD por kg de carcasa

reposición (invernada, se cierra al embarcar)
  kgNeto  = kgBruto × (1 − tara/100)      ← tara = desbaste
  importe = kgNeto × precio               ← precio en USD por kg en pie

promedio por cabeza = truncar(kgNeto / cabezas, 3)
```

El promedio **se trunca, no se redondea**: así lo hace BF Zafra y se respetó para que los
renglones den idénticos a la pantalla que usan hoy.

Sobre el importe se arma todo lo demás:

```
comVenta         = importe × %venta         ← la paga el productor
comCompra        = importe × %compra        ← la paga el comprador
IVA              = comisión × 22%           ← sólo sobre la comisión, no sobre la hacienda
IMEBA            = importe × 2,5%           ← retención al productor
gastos           = flete + guía + inspección sanitaria

líquidoProductor = importe − comVenta − ivaVenta − IMEBA − gastosV
totalComprador   = importe + comCompra + ivaCompra + gastosC
ingresoCM        = comVenta + comCompra
comisiónAgente   = ingresoCM × 12%
```

Las comisiones son **asimétricas y configurables por negocio**. Por defecto: frigorífico 1% de
venta y 0% de compra; reposición 1,5% y 1,5%.

Gastos que se generan solos: flete `kgBruto × 0,022`, guía de propiedad y tránsito `14`,
inspección sanitaria `kgBruto × 0,0015`. Todos a cargo del vendedor.

Vencimientos: la fecha base es la faena, o el embarque si no hay faena.
`vencCobro = base + plazo del comprador`, `vencPago = base + plazo del vendedor`.

## Estados del negocio

```
pactado → embarcado → [faenado] → liquidado → cerrado
```

`faenado` existe sólo en los negocios de frigorífico. En reposición el importe ya queda firme
en el embarque. No se puede liquidar mientras el importe sea estimado.

Al liquidar pasan tres cosas juntas: salen las dos liquidaciones, se emite la e-Factura contra
DGI y se escribe el asiento contable. Si después editás el negocio, el asiento se borra y se
reescribe: nunca puede decir algo distinto del negocio.

El asiento de liquidación balancea por construcción:

```
Deudores por consignación (comprador)     totalComprador
    a Acreedores por consignación (productor)   líquidoProductor
    a Comisiones por venta                      comVenta
    a Comisiones por compra                     comCompra
    a IVA ventas                                ivaVenta + ivaCompra
    a IMEBA a pagar (DGI)                       IMEBA
    a Proveedores (gastos del negocio)          gastosV + gastosC
```

## Los módulos

Quince vistas: panel, lotes de la app, negocios (lista y tablero arrastrable), remates,
liquidaciones, facturación electrónica, flujo de fondos, conciliación bancaria, contabilidad
(diario, mayor y balance), plan de cuentas, cuentas, agentes y metas, fideicomiso, informes y
configuración.

Todo se opera de verdad: alta, edición y baja de negocios, cuentas, lotes, agentes, asientos
manuales y cuentas contables. Más búsqueda con Ctrl+K, exportación a CSV, tour de cuatro pasos
y eventos que entran solos cada 38 segundos.

## Cómo está armado el código

- `SEED_CLIENTES`, `SEED_AGENTES`, `SEED_NEGOCIOS`, `SEED_LOTES`, `SEED_REMATES`,
  `SEED_PLAN`, `SEED_FIDEI` — los datos de arranque. Las fechas son desplazamientos en días
  contra `HOY`, no fechas fijas, para que el demo nunca se vea viejo.
- `calcLinea()` y `calcNegocio()` — el motor. Todo lo demás lee de acá; nada guarda totales.
- `construirEstado()` — arma `ST` desde las semillas y deriva liquidaciones, asientos,
  extracto bancario y vencimientos.
- `VISTAS.<nombre>` — una función por vista, devuelve `{titulo, sub, acciones, html, luego}`.
- `CFG` — configuración viva. Cambiarla recalcula el sistema entero.

## Qué es real y qué está inventado

**Real, de la foto del sistema actual:** el negocio 6351 completo — Alejandro Arrieta Perera
con su RUT y su guía, Ontilcor S.A. (Frigorífico Pando), tropa 2376, 60 novillos, 32.150 kg en
pie, 17.704 de carcasa, 55,067% de rendimiento, USD 5,70 el kilo, USD 100.912,80 de total, 1%
de comisión igual a 1.009,13, cotización 40,259, plazos de 45 y 30 días.

**Real, de lo que publican:** comisiones de 0,5% a frigorífico y 1,5% en reposición, el
fideicomiso de garantía, la certificación veterinaria, la oficina en Av. Dr. Luis Alberto de
Herrera 1248.

**Inventado:** todos los productores, los cinco agentes, el plan de cuentas, los lotes, los
remates y todos los movimientos. Los frigoríficos son empresas reales del rubro, pero las
operaciones atribuidas a ellas son de mentira.

## Lo que falta o hay que confirmar

- **El link no existe todavía.** El publicado va por GitHub Actions y falla porque faltan los
  secretos `CF_TOKEN` y `RAILWAY_TOKEN` en el repositorio. Nunca se cargaron.
- **Los colores son una apuesta.** No se pudo acceder a `campomercado.com` desde el entorno
  donde se armó, así que la paleta se dedujo del rubro. Si aparece el logo o los hex reales,
  hay que ajustarla.
- **Los prefijos de DICOSE probablemente no coincidan** con el departamento de cada cliente.
  Falta confirmar qué codificación de departamentos usa DICOSE antes de tocarlos.
- **El tratamiento impositivo está modelado, no validado.** Que el IVA vaya sólo sobre la
  comisión, que el IMEBA sea 2,5% sobre el importe y se retenga al productor, y qué gastos van
  a cada cargo: todo eso lo tiene que confirmar el contador de ellos.
- **La conexión con la app de lotes está simulada.** No se sabe todavía si esa app tiene API.
  No se puede presentar como resuelta.
- **En la foto hay campos DICOSE A, B, C y D.** Se usaron A y B como origen y destino; qué son
  C y D es una pregunta abierta para Storace.
- **No es un sistema.** No tiene usuarios, permisos, respaldo, multiempresa, ni conexión real
  con DGI ni con el banco.

## Antes de entregar cualquier cambio

```bash
# 1. sintaxis del script extraído del HTML
node --check <script.js>

# 2. sin emojis — tiene que imprimir 0
node -e 'const s=require("fs").readFileSync(process.argv[1],"utf8");const m=s.match(/\p{Extended_Pictographic}/gu)||[];console.log(m.length)' public/index.html

# 3. sin nativos, sin acentos rotos
grep -nE '\b(prompt|confirm|alert)\(' public/index.html
grep -c 'Ã' public/index.html

# 4. levantarlo y pedir la portada
PORT=3999 node server.js
curl -s http://127.0.0.1:3999/ | grep -o '<title>[^<]*</title>'
```

El archivo está en `demos/campomercadoerp/public/index.html`, rama
`claude/zealous-franklin-gr6kza` del repo `contacto254/fabrica-de-demos`.
Son unas 4.640 líneas, alrededor de 76.000 tokens.
