---
name: passport-ui
description: >
  This skill should be used when working on responsive web UI that must survive short, wide viewports —
  "passport format" phones and foldable cover screens with 16:10, 5:3 or 16:9.5 aspect ratios
  (Galaxy Z Fold cover screen, iPhone Duo closed, Huawei Pura X View). Use it when building new
  layouts, auditing existing CSS, or verifying a page across device sizes.
  Triggers: pantalla pasaporte, formato pasaporte, móvil ancho, plegable, foldable, cover screen,
  viewport bajo, poca altura, landscape phone, 100vh, min-height 100vh, breakpoints, media queries,
  dvh, svh, lvh, container queries, aspect-ratio, safe-area-inset, viewport segments, hinge,
  "no cabe en pantalla", "se corta el contenido", responsive audit.
---

# Passport UI — layouts para pantallas anchas y cortas

## El problema en una frase

Un viewport de ~880×420 px CSS **entra por los breakpoints de tablet/desktop porque es ancho, pero
tiene la altura de un móvil apaisado**. Todo el CSS escrito en los últimos diez años asume lo
contrario: móvil = estrecho y alto.

## Regla madre

> **Nunca decidas el layout solo por el ancho.** Cada decisión de layout se toma con las tres
> entradas: ancho, **alto** y aspect-ratio. Si una media query de este proyecto solo mira `width`,
> es un bug latente en formato pasaporte.

Corolarios, en orden de importancia:

1. **`vh` está prohibido.** Usa `svh` / `dvh` / `lvh`. `100vh` en un héroe es el fallo nº1.
2. **Presupuesto vertical**: el chrome fijo (header + footer + barras) no puede superar el **15%**
   del alto del viewport. A 420 px de alto eso son ~63 px para *todo* lo fijo.
3. **Container queries por defecto**: el componente se adapta a su contenedor (`cqi`/`cqh`), no al
   viewport. Es lo que hace que el mismo componente sobreviva en 420×880 y en 880×420.
4. **Detecta la forma, nunca el dispositivo.** Nada de user-agent ni listas de modelos. Las APIs de
   plegables (`device-posture`, viewport segments) son acabado, no cimiento: solo Chromium.
   → `references/detection.md`.
5. **Cuando falta alto, el eje cambia**: nav inferior → rail lateral; stack vertical → grid de dos
   columnas. Hay ancho de sobra; el recurso escaso es el alto.

## Flujo A — construir UI nueva

1. Define el presupuesto vertical antes de escribir CSS: cuánto alto se lleva el chrome fijo.
2. Escribe el layout con grid `auto-fit`/`minmax` y container queries; añade media queries solo
   donde el grid no basta.
3. Aplica los patrones de `references/patterns.md` (unidades, tipografía con `clamp()` de dos
   entradas, art direction de imágenes, bisagra).
4. Verifica según `references/verify.md` **antes de darlo por hecho**. Una captura a 880×420 vale
   más que cualquier razonamiento sobre el CSS.

## Flujo B — auditar un proyecto existente

> Las rutas de abajo son **relativas al directorio de este skill** (el que contiene este SKILL.md).

1. Ejecuta el escáner estático (barato y determinista):

   ```bash
   bash <dir-de-este-skill>/scripts/scan.sh <ruta>
   ```

2. Lee `references/antipatterns.md` para interpretar cada hallazgo y su severidad.
3. Corrige empezando por los `CRITICAL` (rompen la primera pantalla), luego `WARN`.
4. Verifica con `references/verify.md`: captura antes y después a los mismos perfiles.

## Comandos

| Comando | Qué hace | ¿Modifica archivos? |
|---|---|---|
| `/passport-optimize [ruta] [url]` | Pipeline completo: mide, corrige y vuelve a medir | **Sí** |
| `/passport-audit [ruta]` | Diagnóstico priorizado, con archivo y línea | No |
| `/passport-check [url]` | Verificación visual contra los perfiles | No |

Los flujos de arriba son lo que hacen esos comandos por dentro; también se siguen a mano cuando el
usuario no los invoca.

## Referencias

| Archivo | Cuándo leerlo |
|---|---|
| `references/devices.md` | Antes de verificar: perfiles de viewport y sus px CSS |
| `references/antipatterns.md` | Al interpretar hallazgos de `scan.sh` |
| `references/patterns.md` | Al escribir o corregir CSS |
| `references/detection.md` | Al escribir la lógica que decide el layout: qué se puede detectar y cuánto fiarse |
| `references/verify.md` | Siempre que haya que comprobar el resultado en Chrome |
| `assets/harness.html` | El banco de pruebas: carga la página en un iframe por perfil (lo usa `verify.md`) |

## Límites conocidos

Decir "esta web funciona en un plegable" es una afirmación más amplia de lo que este skill sostiene.
Lo que cubre de verdad:

| | |
|---|---|
| **Pantalla cerrada** (cover, formato pasaporte) | cubierta: detección automática, patrones y verificación medible |
| **Pantalla abierta** | cubierta en lo esencial — medida de línea, anchos fijos, hover, multiventana (`patterns.md` §13) |
| **Bisagra** | hay una receta (`patterns.md` §11), **no verificada en hardware real**. Chromium únicamente |
| **`env(safe-area-inset-*)`** | **no verificable** con el harness: vale 0 dentro de un iframe. Se revisa leyendo el CSS |
| **Postura a medio plegar** | no simulable en ningún entorno de escritorio |
| **Continuidad al desplegar** | se simula un cambio de tamaño del mismo documento; un dispositivo real puede recargar la página |

Nada de esto se ha probado en un plegable físico. El método de iframes reproduce fielmente media
queries, `dvh` y container queries — por eso las medidas son fiables para lo que miden — pero no el
DPR, ni la bisagra, ni las peculiaridades del navegador del dispositivo.

> **En el roadmap:** conseguir un plegable físico y validar sobre hardware real. Es lo que convertiría
> los puntos no verificados de arriba en hechos comprobados — o en correcciones.

## Qué no hace este skill

No decide la dirección estética (tipografía, paleta, personalidad visual) — eso es `frontend-design`.
Este skill se ocupa exclusivamente de que el contenido **quepa y sea usable** en viewports anchos y
cortos. Los dos se complementan y pueden usarse en la misma tarea.
