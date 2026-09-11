# Perfiles de viewport

Tamaños en **píxeles CSS** (no físicos). Son los que hay que pasar a `resize_window` o a
`setViewportSize`.

> ⚠️ **Los valores marcados con `~` son aproximados.** Los fabricantes no publican el viewport CSS,
> solo pulgadas y resolución física; el px CSS depende del DPR y de la UI del navegador. Antes de
> afirmar una cifra concreta al usuario, confírmala midiendo: `innerWidth`/`innerHeight` reales en el
> dispositivo o en el emulador. Para el trabajo de layout, lo que importa es la **clase**, no el píxel exacto.

## Clases objetivo

| Clase | Aspecto | Perfil de prueba (px CSS) | Representa |
|---|---|---|---|
| `passport-cover` | ~16:10 | **~880 × 550** | Cover de plegable tipo Galaxy Z Fold 8 (5,5", 16:10) |
| `passport-cover-xs` | ~5:3 | **~820 × 490** | El caso más apretado: cover pequeño, alto mínimo |
| `passport-wide` | ~16:9.5 | **~900 × 535** | Huawei Pura X View (6,39", 16:9.5), pasaporte no plegable |
| `unfolded` | ~4:3 | **~1000 × 750** | Interior del plegable (7,6"), con bisagra |
| `split-unfolded` | ~2:3 | **~500 × 750** | Interior del plegable en **multiventana**: dos apps lado a lado |
| `phone-tall` | ~19.5:9 | **390 × 844** | Control: el móvil clásico, no debe romperse |
| `landscape-classic` | ~16:9 | **844 × 390** | Control: móvil clásico girado, muy parecido a pasaporte |

**Mínimo viable para una verificación rápida**: `passport-cover-xs`, `unfolded`, `phone-tall`.
El primero encuentra casi todos los fallos de alto, el segundo los de la pantalla abierta (medida de
línea, anchos fijos), y el último confirma que no rompiste el caso normal.

La multiventana no es un extra: en un plegable abierto es un uso habitual, y `split-unfolded` es más
estrecho que un móvil normal siendo igual de alto — rompe los layouts calibrados para `unfolded`.

## Por qué estos rompen el CSS típico

- 820–900 px de ancho cae **por encima** de los breakpoints móviles habituales (640/768 px) y **por
  debajo** de los de desktop (1024 px): el layout recibido es el de tablet, con 490 px de alto.
- 490–550 px de alto es **menos que el `min-height: 100vh` de un móvil en vertical** (844 px). Todo
  lo que estaba calibrado para 844 px de alto se desborda.
- En `unfolded` hay además una **bisagra** que parte el viewport en dos segmentos; el contenido
  colocado en el centro queda ilegible.

## Notas por dispositivo

- **Plegables cerrados**: el navegador de la cover suele tener barras de UI más gruesas en proporción.
  El alto *útil* es menor que el nominal → razón de más para usar `dvh`, no `vh`.
- **Bisagra**: se detecta con `@media (horizontal-viewport-segments: 2)` y las variables
  `env(viewport-segment-width 0 0)`, `env(viewport-segment-left 1 0)`, etc.
- **Safe areas**: cámaras y esquinas redondeadas siguen existiendo; `env(safe-area-inset-*)` aplica
  igual, y en apaisado los insets **laterales** son los grandes.
