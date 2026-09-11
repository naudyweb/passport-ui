# Anti-patrones: qué detecta `scan.sh` y por qué importa

Severidades: **CRITICAL** = rompe la primera pantalla en formato pasaporte · **WARN** = degrada la
experiencia · **INFO** = revisar a mano, puede ser intencional.

---

## CRITICAL

### 1. `vh` para alturas de layout
```css
.hero { min-height: 100vh; }   /* ❌ */
```
`vh` ignora las barras de UI del navegador móvil: en una cover screen el héroe se sale por debajo y
el CTA queda fuera de vista. Además, a 490 px de alto un "héroe de pantalla completa" ya no tiene
espacio para nada. → `patterns.md` §1 y §2.

### 2. Breakpoints solo por ancho
```css
@media (max-width: 768px) { /* ❌ "esto es móvil" */ }
```
880×550 **no** entra aquí: recibe el layout de escritorio con la altura de un móvil. Es la causa raíz
de la mayoría de los fallos. → `patterns.md` §3.

### 3. Header fijo **y** footer fijo a la vez
```css
header { position: fixed; height: 64px; }
footer { position: fixed; height: 72px; }   /* ❌ juntos: 136px de 490 = 28% */
```
Supera el presupuesto vertical del 15%. En pasaporte, uno de los dos se convierte en rail lateral.
→ `patterns.md` §5.

### 4. Alturas fijas en modales, drawers y overlays
```css
.modal { height: 600px; }   /* ❌ más alto que el viewport entero */
```
El modal no cabe, el scroll interno no existe y los botones de acción quedan inalcanzables.

---

## WARN

### 5. `orientation: portrait` como sinónimo de "móvil"
Un plegable cerrado puede reportar `portrait` siendo ancho, y `landscape` siendo un formato
perfectamente usable. La orientación no dice nada útil por sí sola: usa aspect-ratio.

### 6. `aspect-ratio` en media sin tope de alto
```css
.cover { width: 100%; aspect-ratio: 16 / 9; }   /* ❌ a 880px de ancho → 495px de alto */
```
A lo ancho del viewport pasaporte, un 16:9 se come la pantalla completa. Necesita
`max-block-size` o un aspect-ratio distinto por media query.

### 7. Tipografía escalada solo por el ancho
```css
h1 { font-size: clamp(2rem, 8vw, 5rem); }   /* ❌ 8vw de 880px = 70px de titular */
```
Titular gigante en una pantalla de 490 px de alto. → `patterns.md` §4.

### 8. Secciones a pantalla completa / scroll-snap vertical
Carruseles y secciones `height: 100dvh` con `scroll-snap-type: y mandatory`: cada "pantalla" tiene
490 px y el contenido diseñado para 844 px se corta sin aviso de que hay más.

### 9. User-agent sniffing para decidir el layout
```js
const isMobile = /iPhone|Android/.test(navigator.userAgent);   // ❌
```
El UA no dice nada de la forma del viewport: falla con ventanas divididas, con escritorio y con cada
modelo nuevo. Igual de malo: `screen.width`, `window.orientation` y las listas de modelos.
→ `detection.md`.

### 10. `padding`/`margin` verticales grandes y fijos
`padding-block: 96px` repetido por sección consume el viewport entero en dos secciones. Debe escalar
con el alto disponible.

---

## INFO

### 11. Ausencia de `env(safe-area-inset-*)`
Si el proyecto usa `position: fixed` en los bordes y nunca menciona `safe-area-inset`, en apaisado
los insets laterales recortan el contenido.

### 12. Ausencia total de container queries
No es un bug, pero un proyecto con muchos breakpoints de viewport y cero `@container` va a necesitar
un breakpoint nuevo por cada formato que aparezca. → `patterns.md` §6.

### 13. Ninguna referencia a `viewport-segments`
Solo relevante si el proyecto apunta a plegables abiertos. Contenido centrado + bisagra = ilegible.

---

## Falsos positivos frecuentes

- `100vh` dentro de un bloque `@supports not (height: 100dvh)` → es el fallback correcto, ignóralo.
- `vh` en `transform`, `translateY`, animaciones o `box-shadow` → no es altura de layout.
- `height: 100vh` en `html`/`body` de una app con scroll interno propio → revisar, pero suele ser
  intencional; verifica antes de tocarlo.
