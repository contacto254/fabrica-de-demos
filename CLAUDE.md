# Contexto

Este repo es una fábrica de demos de ERP a medida, para vender. Alguien pasa la web de una
empresa y el resultado es un link publicado en `<slug>demo.customerp.dev` con un ERP falso
pero navegable, con los datos reales de esa empresa adentro.

Cuando te pidan un demo nuevo, usá la skill `nuevo-demo`. Ahí está el procedimiento completo.

## Lo que no hay que perder de vista

**El entregable es un link que funciona.** No termines diciendo "ahora corré tal comando" o
"faltaría configurar el DNS". El despliegue y el DNS son parte del trabajo. Si algo te
bloquea de verdad, decilo derecho y explicá qué falta.

**El cliente tiene que reconocerse.** Sus productos con sus precios, su equipo con sus
nombres, sus reseñas convertidas en clientes del sistema. Eso es lo que vende, más que
cualquier módulo.

**Cuanto más ve, más se imagina.** Ante la duda, más módulos y más datos. Un demo flaco se
recorre en dos minutos y no deja nada.

**Todo tiene que responder al clic.** Un botón que no hace nada le dice al cliente que esto
es humo, y es lo único que se va a llevar de la reunión.

## Reglas del HTML

- Un solo archivo, sin bundler, sin framework, sin CDN de JavaScript. Sólo se permite una
  fuente de Google Fonts.
- Iconos SVG propios en un sprite de `<symbol>`. Cero emojis, cero caracteres haciendo de
  icono.
- Nada de `prompt()`, `confirm()` ni `alert()`: modales propios.
- Español rioplatense con voseo, UTF-8, acentos correctos.
- Los datos viven en memoria y se reinician al recargar. Es a propósito.

## Infraestructura

Un servicio de Railway por demo, todos dentro del proyecto `customerp-demos`. El DNS de
`customerp.dev` está en Cloudflare. Los CNAME van **sin proxy**: con el proxy de Cloudflare
encendido Railway no puede validar la propiedad ni emitir el certificado.

`scripts/publicar.sh` hace las dos cosas y espera el certificado. Necesita `CF_TOKEN` en el
entorno.

## Antes de entregar

1. `node --check` sobre el script extraído del HTML.
2. Sin emojis, sin `prompt`/`confirm`/`alert`, sin `Ã` (acentos rotos).
3. Levantarlo local y pedir la portada con curl.
4. `bash scripts/verificar.sh <slug>` hasta que el link responda de verdad.

Commiteá y pusheá vos, sin preguntar.
