# Contenido del demo

El diseño impresiona tres segundos. Lo que cierra la venta es que el cliente reconozca su
propio negocio adentro y piense "esto ya entiende cómo trabajo".

## La regla

**Cuanto más ve, más se imagina.** Un demo con cuatro pantallas y seis filas se agota en dos
minutos y deja la sensación de que no hay nada atrás. Uno con doce vistas y datos por todos
lados se recorre veinte minutos y el cliente empieza a pedir cosas: ahí ya está comprando.

Ante la duda, poné más.

## Datos reales primero

Todo lo que esté en su web va adentro, textual:

- Los productos con sus nombres exactos y sus precios exactos.
- La gente del equipo con nombre y cargo.
- La dirección del local, el teléfono, las redes.
- Las reseñas con el nombre de quien las escribió, convertidas en clientes del sistema.
- Sus certificaciones, sus años en el mercado, su cobertura.

El momento en que el cliente ve su propio producto con su propio precio en una factura del
sistema es el momento en que la demo deja de ser una demo.

## Lo inventado, verosímil

Lo que falta se inventa, pero con reglas:

- **Coherencia cruzada.** Si una factura es del cliente 3, la entrega de esa factura es del
  cliente 3. Si un lote figura vendido, su negocio está cerrado y su comisión facturada. El
  cliente va a tirar del hilo justo de lo que no cierra.
- **Fechas alrededor de hoy.** Definí una constante `HOY` y derivá todo de ahí: algo que
  vence mañana, algo vencido hace tres días, algo entregado la semana pasada. Un sistema
  cuyo último movimiento fue hace ocho meses parece abandonado.
- **Números que cierran.** Los totales suman, los porcentajes dan, el IVA es el del país.
  Vas a estar frente a alguien que conoce sus márgenes de memoria.
- **Nombres del lugar.** Localidades, apellidos, calles, monedas y organismos reales del
  país donde opera la empresa.
- **Volumen suficiente.** Entre 12 y 25 clientes, 10 a 20 documentos, movimientos repartidos
  en varios meses. Que ninguna tabla se vea flaca.

## Lo que no puede faltar

**Un panel de inicio que hable de hoy.** No indicadores genéricos: lo que hay que hacer hoy,
lo que está por vencer, lo que se trabó. Es la primera pantalla y define todo.

**Algo que se mueva mientras miran.** Un mensaje que entra, un pedido nuevo, una oferta.
Cada 30-45 segundos, con un aviso. Cuando pasa en medio de la reunión, se vende solo.

**Un flujo completo de punta a punta**, que el vendedor pueda recorrer en un minuto:
llega un pedido → se factura → baja el stock → se arma la entrega → se cobra. Ese recorrido
es la demo; el resto es el decorado que lo hace creíble.

**Ctrl+K.** Buscar cualquier cosa y ejecutar acciones desde el teclado. Es barato de hacer y
sorprende a todo el mundo.

**Un tablero para arrastrar.** Oportunidades, pedidos, obras, lo que sea. Arrastrar una
tarjeta y ver que algo cambia en otro lado es lo que más se recuerda.

**Alertas derivadas de los datos**, nunca escritas a mano: lo que está vencido se calcula
mirando las fechas, lo que está bajo mínimo mirando el stock. Cuando el cliente cambia algo
y la alerta desaparece sola, entendió que el sistema piensa.

**Exportar a CSV** de verdad, con `Blob` y descarga. La pregunta "¿esto lo puedo bajar a
Excel?" aparece siempre.

**Un tour de tres pasos** que se pueda volver a abrir, para cuando el cliente entre solo al
link después de la reunión y no tenga a nadie al lado explicándole.

## El detalle que convence

Metete en el rubro. Lo que hace que un cliente diga "pero esto ya sabe cómo trabajamos" no
son los módulos, son las cosas chicas:

- Una distribuidora de un producto de uso continuo: calcular cuándo se le termina al cliente
  según el consumo, y avisar antes.
- Un escritorio rural: guía de propiedad y tránsito, DICOSE, categorías de hacienda, 4ª
  balanza.
- Una empresa que importa: el costo landed, con flete y aduana prorrateados por unidad.
- Cualquiera que venda en varios países: cada uno con su moneda, su IVA y su régimen de
  factura electrónica, y el consolidado en dólares.

Una sola de estas cosas, bien hecha, vale más que tres módulos genéricos.

## El tono

Español rioplatense, voseo, como habla el cliente. Nada de "presione el botón": "apretá".
Los textos de ayuda explican el porqué en una línea, sin manual.

Escribí los nombres de las cosas como los dice el rubro, no como los diría un programador.
"Guía de propiedad y tránsito", no "documento de transporte". "Hacienda", no "inventario
de animales".
