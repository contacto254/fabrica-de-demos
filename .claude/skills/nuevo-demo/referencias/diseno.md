# Diseño del demo

El cliente juzga el sistema en los primeros cinco segundos, antes de leer nada. Si parece
barato, ya perdiste; el resto de la reunión es cuesta arriba.

## Identidad

Sacá la paleta de la web de la empresa. Si su marca es verde, el demo es verde. Que el
cliente sienta que es *su* sistema, no una plantilla con su logo pegado encima.

Definí todo en variables CSS al principio y no uses colores sueltos en el resto del archivo:

```css
:root{
  --bg:#F6FAF9; --panel:#FFF; --ink:#12332F; --ink-2:#4A6663; --ink-3:#8AA19D;
  --line:#DCE8E5; --brand:#1B9C86; --brand-deep:#136E5F; --brand-soft:#E3F4F0;
  --warn:#F5B841; --warn-soft:#FFF3D6; --bad:#E0655E; --bad-soft:#FCE6E4;
  --r:10px; --r-lg:16px;
}
```

Tres neutros de texto alcanzan: el principal, uno secundario para datos, uno tenue para
etiquetas. Los colores fuertes se reservan para estados, nunca para decorar.

Una fuente sola, de Google Fonts, con pesos 400/600/700/800. Manrope, Nunito, Inter y
Figtree funcionan bien. Elegí la que se parezca a la de su web.

Dibujá un logotipo en SVG inline inspirado en el de ellos. Nunca enlaces el archivo de su
web: si se cae el link, el demo aparece roto justo cuando lo están mirando.

## Iconos

Un sprite al principio del `<body>`:

```html
<svg style="display:none">
  <symbol id="i-inicio" viewBox="0 0 24 24"><path d="M3 11 12 4l9 7"/><path d="M5 10v10h14V10"/></symbol>
</svg>
```

Y en el markup:

```html
<svg class="ic"><use href="#i-inicio"/></svg>
```

```css
.ic{width:1.15em;height:1.15em;flex:none;vertical-align:-.15em;
    stroke:currentColor;fill:none;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round}
```

Todos del mismo grosor y el mismo viewBox. Un icono relleno entre iconos de línea se ve mal
aunque no sepas por qué.

Nada de emojis, nunca. Tampoco caracteres haciendo de icono: ni `✓`, ni `→`, ni `▲`, ni `×`
para cerrar. Todo eso se dibuja.

## Composición

- Barra lateral fija de 220-240px con la navegación agrupada por área.
- Barra superior con el título de la vista, la búsqueda y las acciones de la vista.
- El contenido en tarjetas sobre un fondo apenas gris, nunca blanco sobre blanco.
- Grilla de 4 indicadores arriba, y abajo bloques de dos o tres columnas.

Aire: 14-16px entre tarjetas, 16-18px adentro. Apretado se lee como planilla vieja.

Bordes de 1px muy claros, radios de 10px en controles y 16px en tarjetas. Sombras casi
imperceptibles y sólo en lo que flota (modales, menús, popovers).

## Números

Los números en tablas van a la derecha y con cifras tabulares:

```css
td.num,th.num{text-align:right;font-variant-numeric:tabular-nums}
```

Formatealos con `Intl.NumberFormat` y separador de miles local. Un total mal alineado o sin
puntos delata el mockup al instante.

## Estados

Cada estado del negocio tiene su color y siempre el mismo:

- normal / al día: neutro
- bueno / cobrado / entregado: la marca
- atención / vence pronto: ámbar
- problema / vencido / sin stock: rojo

Los estados van en píldoras, no en texto suelto:

```css
.tag{display:inline-block;padding:2px 9px;border-radius:999px;font-size:12px;font-weight:700}
```

## Interacción

Todo lo que se puede clickear tiene que avisarlo: `cursor:pointer`, cambio de fondo al pasar
por encima, y foco visible con `:focus-visible` (no lo saques nunca, es lo único que tiene
quien navega con teclado).

Transiciones de 120-200ms, y respetalas:

```css
@media (prefers-reduced-motion:reduce){*{transition:none!important;animation:none!important}}
```

Después de cada acción, un aviso corto abajo que confirme qué pasó. Es lo que le dice al
cliente "el sistema hizo algo de verdad".

## Vacío

Una tabla vacía con la palabra "vacío" en gris es la muerte de la demo. Un estado vacío
lleva icono, una línea que explique por qué está vacío, y el botón para llenarlo.

Pero antes que eso: hacé que casi nunca aparezca. Cargá datos suficientes para que ninguna
vista importante se vea desierta, incluso cuando el cliente juegue con los filtros.

## Pantalla chica

El vendedor va a abrir esto en el celular en algún momento. No escondas la navegación por
debajo de cierto ancho: pasala a una barra inferior o a un menú que se despliegue. Las
tablas anchas, adentro de un contenedor con `overflow-x:auto`, nunca haciendo que se mueva
la página entera.

## Accesibilidad

- Los botones que sólo tienen icono llevan `aria-label`.
- Contraste real en los textos tenues (4.5:1 sobre el fondo donde se apoyan).
- Los modales se cierran con Escape y devuelven el foco a donde estaba.
- Los iconos decorativos van con `aria-hidden="true"`.
