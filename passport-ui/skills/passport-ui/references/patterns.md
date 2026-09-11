# Patrones correctos

## §1 — Unidades de alto: nunca `vh`

| Unidad | Qué mide | Cuándo |
|---|---|---|
| `dvh` | alto **dinámico**: cambia al aparecer/ocultarse las barras | por defecto para layout |
| `svh` | alto **pequeño**: con las barras visibles | cuando algo NO puede quedar tapado nunca |
| `lvh` | alto **grande**: con las barras ocultas | fondos decorativos |
| `vh`  | alto del viewport ideal, ignora barras | ❌ nunca para layout |

```css
.hero {
  min-height: 100vh;   /* fallback para navegadores viejos */
  min-height: 100dvh;  /* gana donde se soporta */
}
```

## §2 — El héroe deja de ser "pantalla completa" cuando no hay alto

```css
.hero { min-height: 100dvh; display: grid; place-content: center; }

/* Poco alto: el héroe se dimensiona por su contenido, no por la pantalla */
@media (max-height: 600px) {
  .hero { min-height: auto; padding-block: clamp(1rem, 6dvh, 3rem); }
}
```
Regla: por debajo de ~600 px de alto, "ocupar la pantalla" deja de ser un objetivo estético y pasa a
ser un obstáculo.

## §3 — Media queries de tres entradas

```css
/* ❌ el viejo mundo */
@media (max-width: 768px) { … }

/* ✅ el caso pasaporte, explícito */
@media (max-height: 600px) and (min-aspect-ratio: 3/2) { … }

/* ✅ "de verdad es un móvil estrecho y alto" */
@media (max-width: 600px) and (max-aspect-ratio: 3/4) { … }

/* ✅ escritorio real: ancho Y alto */
@media (min-width: 1024px) and (min-height: 700px) { … }
```

Los tres umbrales que merece la pena nombrar como custom properties o variables de Sass/Tailwind:
`--h-short: 600px`, `--ar-wide: 3/2`, `--w-desk: 1024px`.

## §4 — Tipografía con las dos dimensiones

```css
h1 {
  /* vmin mira la dimensión MENOR: en pasaporte es el alto, que es lo escaso */
  font-size: clamp(1.75rem, 4vmin + 0.5rem, 3.5rem);
}
```
`vmin` en lugar de `vw` es el cambio de una línea que arregla la mayoría de los titulares. Para
componentes, `cqi`/`cqb` es mejor todavía (§6).

## §5 — Chrome fijo: presupuesto del 15%

A 490 px de alto son ~73 px para header + footer + barras juntos. Cuando no cabe, **cambia el eje**:

```css
/* Alto: nav abajo, a lo ancho */
.nav { position: fixed; inset-block-end: 0; inset-inline: 0; height: 64px; }

/* Pasaporte: el nav pasa a rail lateral — hay ancho de sobra, falta alto */
@media (max-height: 600px) and (min-aspect-ratio: 3/2) {
  .nav {
    inset-block: 0; inset-inline-end: auto; inset-inline-start: 0;
    height: auto; width: 72px; flex-direction: column;
    padding-inline-start: env(safe-area-inset-left);
  }
  .page { padding-inline-start: 72px; padding-block-end: 0; }
}
```
Mismo principio para headers: `position: fixed` → `sticky` o estático cuando el alto aprieta.

## §6 — Container queries como mecanismo por defecto

```css
.card-grid { container-type: inline-size; }

.card { display: grid; gap: 1rem; }
@container (min-width: 30rem) {
  .card { grid-template-columns: 8rem 1fr; }  /* el mismo componente, otra forma */
}
```
Un componente que responde a su contenedor sobrevive a cualquier formato nuevo sin tocar CSS. Unidades
disponibles: `cqi` (inline), `cqb` (block), `cqmin`, `cqmax`. Requiere `container-type` en el padre.

## §7 — Grid que se adapta sin breakpoints

```css
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(18rem, 100%), 1fr));
  gap: clamp(0.75rem, 2vmin, 1.5rem);
}
```
`min(18rem, 100%)` evita el desbordamiento en pantallas estrechas. Cero media queries.

## §8 — Imágenes: art direction por aspect-ratio

```html
<picture>
  <source media="(min-aspect-ratio: 3/2)" srcset="hero-wide.avif" width="1600" height="700">
  <img src="hero-tall.avif" width="900" height="1200" alt="…">
</picture>
```
Y tope de alto para cualquier media que ocupe todo el ancho:
```css
.cover { width: 100%; aspect-ratio: 16/9; max-block-size: 45dvh; object-fit: cover; }
```

## §9 — Espaciado vertical que escala

```css
section { padding-block: clamp(1.5rem, 6dvh, 5rem); }
```
Sustituye cualquier `padding-block` fijo de más de 48 px.

## §10 — Modales y drawers

```css
.modal {
  max-block-size: min(90dvh, 40rem);
  display: grid; grid-template-rows: auto 1fr auto;  /* head / scroll / acciones */
  overflow: hidden;
}
.modal__body { overflow-y: auto; overscroll-behavior: contain; }
```
Las acciones nunca hacen scroll fuera de vista.

## §11 — Bisagra (plegable abierto)

```css
@media (horizontal-viewport-segments: 2) {
  .layout {
    display: grid;
    grid-template-columns:
      env(viewport-segment-right 0 0)
      calc(env(viewport-segment-left 1 0) - env(viewport-segment-right 0 0))  /* la bisagra */
      1fr;
  }
  .layout > .gutter { visibility: hidden; }  /* nada de contenido sobre la bisagra */
}
```
Soporte aún parcial (solo Chromium): siempre detrás de una media query, nunca como base del layout.
Qué se puede detectar y con cuánta confianza: `references/detection.md`.

## §12 — Safe areas en apaisado

```css
.page {
  padding-inline: max(1rem, env(safe-area-inset-left), env(safe-area-inset-right));
  padding-block-end: max(1rem, env(safe-area-inset-bottom));
}
```
En formato pasaporte los insets **laterales** son los relevantes, no los verticales. Requiere
`<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">`.

## §13 — Cuando sobra espacio: la pantalla abierta

El interior de un plegable invierte el problema. Ya no falta alto: **sobra ancho**, y con él llegan
fallos distintos que el resto de este documento no cubre.

### Medida de línea

```css
/* El contenedor puede ser ancho; la línea de texto, no */
.prose > * { max-inline-size: 65ch; }
.prose > figure, .prose > table { max-inline-size: none; }
```
A 1000 px de ancho, un párrafo sin tope llega a 120 caracteres por línea y el ojo pierde el renglón al
volver. El rango legible es **45–75 caracteres**; 65ch es el valor seguro.

### Anchos fijos, nunca

```css
.shell { width: min(1440px, 100%); margin-inline: auto; }   /* ✅ */
.shell { width: 1440px; }                                   /* ❌ desborda por debajo de 1440 */
```

### Es una pantalla táctil, no un escritorio

El ancho de la pantalla abierta se parece al de un portátil, y ese parecido engaña: sigue siendo
táctil y se sigue sujetando con las manos.

```css
/* El hover es un extra, nunca el único camino */
@media (hover: hover) {
  .card:hover .card__acciones { opacity: 1; }
}
.card__acciones { opacity: 1; }   /* accesible siempre */
```
Objetivos táctiles ≥ 44×44 px también aquí, y nada de tooltips como única fuente de información.

### Aprovechar no es estirar

Con 1000×750 hay sitio para **dos columnas**, no para una columna de 1000 px:

```css
.layout {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(22rem, 100%), 1fr));
  gap: clamp(1rem, 3vmin, 2rem);
}
```
Centrar una columna estrecha en un mar de vacío desaprovecha la pantalla tanto como estirarla.

### Los pulgares siguen en los bordes

Las acciones relacionadas se mantienen **agrupadas**, no repartidas a los dos extremos porque haya
sitio: en una pantalla que se sujeta con dos manos, cruzar 1000 px es un gesto costoso.

---

## Traducción a Tailwind

```js
// tailwind.config.js
screens: {
  'short':    { 'raw': '(max-height: 600px)' },
  'passport': { 'raw': '(max-height: 600px) and (min-aspect-ratio: 3/2)' },
  'tall':     { 'raw': '(min-height: 700px)' },
}
```
Uso: `min-h-dvh passport:min-h-auto passport:py-4`. Tailwind v3.4+ ya trae las utilidades `dvh`/`svh`
(`h-dvh`, `min-h-dvh`).
