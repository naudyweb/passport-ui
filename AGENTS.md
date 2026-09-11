# passport-ui — reglas para agentes

Instrucciones para cualquier agente de código que trabaje en **UI web responsive**. Formato
[AGENTS.md](https://agents.md), leído por Codex, Copilot, Cursor, Gemini CLI, Aider, Zed, Windsurf y
otros. Los usuarios de Claude Code reciben lo mismo a través del skill `passport-ui`.

## Instalación en tu proyecto

Trae las herramientas al repo y añade estas reglas al `AGENTS.md` del proyecto (o usa este archivo
tal cual).

```bash
# submódulo: recibe actualizaciones con git submodule update --remote
git submodule add https://github.com/naudyweb/passport-ui .passport-ui
#   → <PU> = .passport-ui/passport-ui/skills/passport-ui

# o una copia plana, sin submódulos
git clone --depth 1 https://github.com/naudyweb/passport-ui /tmp/pu \
  && cp -r /tmp/pu/passport-ui/skills/passport-ui .passport-ui && rm -rf /tmp/pu
#   → <PU> = .passport-ui
```

En lo que sigue, **`<PU>` es la carpeta que contiene `scripts/`, `references/` y `assets/`**, según la
opción elegida. Dentro de este propio repo es `passport-ui/skills/passport-ui`.

## El problema

Las pantallas vuelven a ser **anchas y cortas**: covers de plegables, móviles "formato pasaporte",
relaciones 16:10, 5:3 y 16:9.5. Un viewport de 880×550 px CSS **entra por los breakpoints de tablet
porque es ancho, pero tiene la altura de un móvil apaisado**. Todo el CSS de los últimos diez años
asume lo contrario: móvil = estrecho y alto.

## Regla madre

> **Nunca decidas el layout solo por el ancho.** Cada decisión se toma con las tres entradas: ancho,
> **alto** y aspect-ratio. Una media query que solo mira `width` es un bug latente.

Corolarios, por orden de importancia:

1. **`vh` está prohibido** para alturas de layout. Usa `svh` / `dvh` / `lvh`. `100vh` en un héroe es
   el fallo nº1.
2. **Presupuesto vertical**: el chrome fijo (header + footer + barras) ≤ **15%** del alto del viewport.
   A 490 px de alto son ~73 px para *todo* lo fijo.
3. **Container queries por defecto**: el componente se adapta a su contenedor (`cqi`/`cqb`), no al
   viewport. Es lo que le hace sobrevivir a formatos que aún no existen.
4. **Detecta la forma, nunca el dispositivo.** Nada de user-agent ni listas de modelos. Las APIs de
   plegables (`device-posture`, viewport segments) son acabado, no cimiento: solo Chromium.
5. **Cuando falta alto, el eje cambia**: nav inferior → rail lateral; stack vertical → dos columnas.
   Hay ancho de sobra; el recurso escaso es el alto.

## Flujo A — construir UI nueva

1. Define el presupuesto vertical antes de escribir CSS.
2. Layout con grid `auto-fit`/`minmax` y container queries; media queries solo donde el grid no basta.
3. Aplica los patrones de `<PU>/references/patterns.md`.
4. Verifica antes de darlo por hecho. Una captura a 820×490 vale más que cualquier razonamiento
   sobre el CSS.

## Flujo B — auditar un proyecto existente

```bash
bash <PU>/scripts/scan.sh <ruta>     # bash + grep, sin dependencias
```

Interpreta cada hallazgo con `<PU>/references/antipatterns.md` (incluye los falsos positivos conocidos),
corrige empezando por los `CRITICAL`, y verifica.

## Verificar

Sirve `<PU>/assets/harness.html` por HTTP desde el mismo origen que la página y ábrelo con
`?url=<url-codificada>`. Carga la página en un iframe por perfil de viewport, así que mide igual que
un dispositivo real y **no depende del gestor de ventanas** (redimensionar la ventana no funciona bajo
Hyprland, sway o i3: se ignora en silencio).

Pulsa **Medir** o ejecuta `probeAll()` en la consola. Criterios de aprobado en `<PU>/references/verify.md`.

Para CI, con Playwright instalado: `node <PU>/scripts/shots.mjs <url> <dir-salida>` (exit ≠ 0 si algún
perfil falla).

## Referencias

Todas bajo `<PU>/` — Markdown puro, sin dependencias de ninguna herramienta:

| Archivo | Cuándo |
|---|---|
| `references/devices.md` | Perfiles de viewport y sus px CSS |
| `references/antipatterns.md` | Interpretar los hallazgos de `scan.sh` |
| `references/patterns.md` | Escribir o corregir CSS |
| `references/detection.md` | Lógica que decide el layout; qué se puede detectar y cuánto fiarse |
| `references/verify.md` | Comprobar el resultado |

## Límites conocidos

Decir "esta web funciona en un plegable" es una afirmación más amplia de lo que estas reglas sostiene.
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

## Alcance

Esto no decide la dirección estética (tipografía, paleta, personalidad). Solo se ocupa de que el
contenido **quepa y sea usable** en viewports anchos y cortos.
