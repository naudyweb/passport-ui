# Detección: qué se puede saber del dispositivo, y cuánto fiarse

## La distinción que ordena todo

No se detecta **"esto es un móvil pasaporte"** — no se debe ni intentar. Se detecta **la forma del
viewport que ha tocado**. Una cover de plegable, un móvil ancho y un móvil normal girado plantean el
mismo problema y merecen la misma solución; el modelo es irrelevante.

Tres niveles, de más fiable a menos:

| Nivel | Qué detecta | Soporte | Papel |
|---|---|---|---|
| **0 · Forma** | ancho, alto, aspect-ratio | universal | **lleva el layout** |
| **1 · Segmentos** | el viewport partido por una bisagra | Chromium, experimental | acabado |
| **2 · Postura** | plegado / plano | Chromium, experimental | acabado |

> **Regla:** el nivel 0 conduce; los niveles 1 y 2 son accesorios. Un diseño que *depende* de
> `device-posture` o de los segmentos se cae en Safari y Firefox. Progressive enhancement siempre:
> la página tiene que estar bien **antes** de aplicarlos.

---

## Nivel 0 — la forma (el 95% del trabajo)

```css
/* pasaporte: ancho y bajo */
@media (max-height: 600px) and (min-aspect-ratio: 3/2) { … }
/* móvil clásico: estrecho y alto */
@media (max-width: 600px) and (max-aspect-ratio: 3/4) { … }
/* plegable abierto: grande y casi cuadrado */
@media (min-width: 900px) and (min-height: 700px) and (max-aspect-ratio: 4/3) { … }
```

**Abrir el plegable ya está cubierto aquí.** Pasar de la cover al interior es, para la web, un cambio
de viewport (820×490 → 1000×750). No hace falta ninguna API de plegables.

```js
const shapes = {
  passport: '(max-height: 600px) and (min-aspect-ratio: 3/2)',
  unfolded: '(min-width: 900px) and (min-height: 700px) and (max-aspect-ratio: 4/3)',
};
for (const [name, q] of Object.entries(shapes)) {
  const mq = matchMedia(q);
  const apply = () => document.documentElement.classList.toggle(`is-${name}`, mq.matches);
  mq.addEventListener('change', apply);
  apply();
}
```

`matchMedia` + `change` en vez de escuchar `resize`: solo dispara al cruzar el umbral, no en cada píxel.

## Nivel 1 — la bisagra

```css
@media (horizontal-viewport-segments: 2) {
  .layout { display: grid;
    grid-template-columns: env(viewport-segment-width 0 0) auto 1fr; }
  .gutter { visibility: hidden; }   /* nada de contenido sobre la ranura */
}
```

Sin API de enumeración estable; para leerlo desde JS, publica el `env()` como custom property:

```css
:root { --seg0-w: env(viewport-segment-width 0 0, 0px); }
```
```js
const seg0 = getComputedStyle(document.documentElement).getPropertyValue('--seg0-w');
```

También existe `vertical-viewport-segments` para los que se doblan en horizontal.

## Nivel 2 — la postura

```css
@media (device-posture: folded)     { … }  /* a medio plegar, tipo portátil */
@media (device-posture: continuous) { … }  /* plano */
```
```js
if ('devicePosture' in navigator) {
  const sync = () => { document.documentElement.dataset.posture = navigator.devicePosture.type; };
  navigator.devicePosture.addEventListener('change', sync);
  sync();
}
```

**Trampa:** `continuous` significa "plano", y eso cubre **tanto abierto del todo como cerrado del todo**.
La postura no dice nada del tamaño — para eso sigue haciendo falta el nivel 0.

## Detección de soporte

Para *media features* `CSS.supports` no vale. El test correcto:

```js
const supports = q => matchMedia(q).media !== 'not all';
supports('(device-posture: folded)');           // false en Safari/Firefox
supports('(horizontal-viewport-segments: 2)');
```

---

## Qué NO hacer

- **User-agent sniffing, listas de modelos, `screen.width`.** Se rompen con ventanas divididas, con
  escritorio y con cada móvil nuevo — justo el escenario que se intenta sobrevivir. Si el proyecto
  decide el layout con `navigator.userAgent`, eso es el bug, no el CSS.
- **Decidir el layout por `navigator.devicePosture`** sin una regla de forma equivalente detrás.
- **Escuchar `resize`** para cambiar el layout, cuando `matchMedia` dispara solo en el umbral.

## Qué se puede simular en pruebas, y qué no

| Cosa | ¿Simulable? | Cómo |
|---|---|---|
| Cerrado → abierto (cambio de viewport) | **Sí** | `assets/harness.html`, botón **Simular apertura**; o los perfiles `passport-cover-xs` y `unfolded` en paralelo |
| Bisagra / segmentos | Parcial | DevTools tiene emulación de dispositivos plegables |
| Postura **a medio plegar** (`folded`) | **No** | DevTools solo emula abierto o cerrado del todo: `device-posture` siempre devuelve `continuous`. Requiere hardware real |

La transición de apertura merece una mirada propia, y es sobre todo una **cuestión estética**: el
usuario abre el móvil a mitad de una frase. Qué revisar mientras se abre:

- El contenido **no salta** ni se reordena de forma brusca — cambian clases y reglas CSS, no se
  desmontan ni se vuelven a montar componentes.
- Se conservan **scroll, foco y lo que hubiera escrito**.
- Si hay animación, respeta `prefers-reduced-motion` y dura poco (≤ 200 ms); la apertura física ya es
  el movimiento, la interfaz no tiene que competir con él.
