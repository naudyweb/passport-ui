# passport-ui

Plugin de [Claude Code](https://claude.com/claude-code) para adaptar interfaces web a las pantallas
**anchas y cortas** que están volviendo al mercado: covers de plegables, móviles "formato pasaporte",
relaciones de aspecto 16:10, 5:3 y 16:9.5.

## El problema

Un viewport de 880×550 px CSS **entra por los breakpoints de tablet porque es ancho, pero tiene la
altura de un móvil apaisado**. Todo el CSS escrito en los últimos diez años asume lo contrario:
móvil = estrecho y alto. El resultado son héroes de `100vh` que ocupan tres pantallas, headers y
footers fijos que se comen el 60% del alto útil, modales que no caben y titulares gigantes.

## Qué incluye

- **Skill `passport-ui`** — se activa solo cuando trabajas en UI responsive. Su regla madre: *nunca
  decidas el layout solo por el ancho; usa ancho, alto y aspect-ratio*.
- **`/passport-audit [ruta]`** — escanea un proyecto, prioriza los hallazgos y aplica los arreglos.
- **`/passport-check [url]`** — verificación visual contra perfiles de viewport reales.
- **`scripts/scan.sh`** — escáner estático determinista: 13 anti-patrones con severidad, línea exacta
  y el arreglo concreto para cada uno.
- **`assets/harness.html`** — banco de pruebas que carga la página en un iframe por perfil y mide
  chrome fijo, scroll y desbordamientos. Incluye un botón **Simular apertura** que lleva el mismo
  iframe de cover a plegable abierto sin recargar, para ver qué pasa con el estado del usuario.
- **Referencias** sobre anti-patrones, patrones correctos, perfiles de dispositivo, detección de
  plegables y protocolo de verificación.

## Instalación

```
/plugin marketplace add naudyweb/passport-ui
/plugin install passport-ui
```

## Uso

Normalmente no hay que invocarlo: el skill se activa solo al trabajar en layouts responsive. Para
lanzarlo a mano:

```
/passport-audit ./src      # auditar y corregir
/passport-check http://localhost:3000   # solo verificar
```

## Resultado de ejemplo

Una landing corriente, medida en el perfil `passport-cover-xs` (820×490):

| | Antes | Después |
|---|---|---|
| Chrome fijo | 31% del alto | 11% |
| Scroll hasta el CTA | 2.3 pantallas | 1 |
| Veredicto | FALLA | pasa |

## Nota sobre `resize_window`

Bajo un gestor de ventanas tiling (Hyprland, sway, i3), redimensionar la ventana del navegador para
probar tamaños **no funciona**: la petición se ignora en silencio y la medición sale falseada. Por eso
el harness usa iframes, que son independientes del gestor de ventanas.

## Licencia

MIT
