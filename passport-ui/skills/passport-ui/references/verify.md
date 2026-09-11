# Verificación visual

Ninguna corrección de layout se da por buena sin una medición y una captura. El razonamiento sobre CSS
falla; el harness a 820×490 no.

## Camino principal: el harness de iframes

`assets/harness.html` carga la página objetivo en un **iframe por perfil**, al tamaño exacto en px CSS.
Las media queries, `dvh`, `cqi` y `aspect-ratio` responden al tamaño del iframe, así que el resultado es
idéntico a un viewport real — y **no depende del gestor de ventanas**.

> ⚠️ **No uses `resize_window` para esto.** Bajo un WM tiling (Hyprland/Omarchy, sway, i3) la petición se
> ignora en silencio: la llamada devuelve éxito y el viewport sigue igual. Medido en la práctica:
> `resize_window(820,600)` → `innerWidth` seguía siendo 1707. El harness no tiene ese problema.

### Puesta en marcha

El harness debe servirse **por HTTP desde el mismo origen que la página** — así la sonda puede leer el
iframe y Chrome no bloquea `file://`:

```bash
cp <dir-de-este-skill>/assets/harness.html <raiz-servida-del-proyecto>/
# si no hay dev server, uno mínimo:
#   python3 -m http.server 8731   (en background)
```

### Herramientas de Chrome (una sola llamada a ToolSearch)

```
select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__tabs_create_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__javascript_tool,mcp__claude-in-chrome__tabs_close_mcp
```

### Protocolo

1. `tabs_context_mcp` → `tabs_create_mcp` (pestaña nueva; no reutilices una del usuario).
2. `navigate` a `http://<host>/harness.html?url=<url-codificada>` — todos los perfiles en fila.
   Para uno solo a tamaño 1:1: `&profile=passport-cover-xs`.
3. Medir: `javascript_tool` con
   ```js
   await new Promise(r => setTimeout(r, 900)); probeAll()
   ```
   Devuelve una línea por perfil: `pasa|FALLA · chrome % · pantallas de scroll · scroll horizontal · qué desborda`.
4. `computer` → `screenshot` (`save_to_disk: true` si el usuario quiere el archivo).
5. Al corregir: repite 3–4 y presenta **antes y después del mismo perfil**.
6. `tabs_close_mcp` y para el servidor si lo levantaste tú.

### Criterios de aprobado

| Métrica | Objetivo | Falla si |
|---|---|---|
| `chrome %` (fijo/sticky a ancho completo) | ≤ 15% | > 25% |
| `horiz` (scroll horizontal) | `false` | `true` — siempre es un bug |
| `desborda` | vacío | cualquier entrada nombra al culpable |
| `scroll` en una landing | ≤ 1.5x hasta el CTA principal | el CTA cae tras la 2ª pantalla |
| Captura en `passport-cover-xs` | acción principal visible sin scroll | — |
| Control `phone-tall` | sigue pasando | arreglaste pasaporte rompiendo el móvil normal |

A ojo en la captura, además: titulares que no caben en dos líneas, imágenes que ocupan más de la mitad
del alto, botones bajo el fold, texto pegado al borde.

**Ejemplo real** (la demo del propio plugin): antes → `FALLA chrome 31% scroll 2.3x`;
después de aplicar `patterns.md` §1 §2 §3 §4 §5 §8 §9 → `pasa chrome 11% scroll 1x`, y los cinco
perfiles en verde.

## Simular la apertura del plegable

El botón **Simular apertura** (o `await simulateUnfold()` desde `javascript_tool`) lleva **el mismo
iframe** de `passport-cover-xs` (820×490) a `unfolded` (1000×750) con una transición, **sin recargar**.
Es la única forma de ver lo que ve el usuario que abre el móvil a mitad de una frase.

Devuelve `conserva estado` / `PIERDE ESTADO` comparando scroll y foco antes y después, y el resto se
juzga a ojo en la captura: ¿saltó el contenido?, ¿se reordenó de golpe?

Es sobre todo una **cuestión estética**: la apertura física ya es el movimiento: la interfaz no debería
competir con él. Animación corta (≤ 200 ms), `prefers-reduced-motion` respetado, y cambio de clases
CSS en vez de desmontar y remontar componentes.

## Qué se puede simular y qué no

| Cosa | ¿Simulable? | Cómo |
|---|---|---|
| Cualquier tamaño de viewport | **Sí** | el harness, un perfil por iframe |
| Cerrado → abierto | **Sí** | botón **Simular apertura** |
| Bisagra / segmentos | Parcial | emulación de plegables de DevTools |
| Postura **a medio plegar** (`device-posture: folded`) | **No** | DevTools solo emula abierto o cerrado del todo; siempre devuelve `continuous`. Requiere hardware real |

## Limitaciones del harness

- No emula **DPR** ni user-agent móvil (irrelevante para fallos de layout, que es lo que buscamos).
- `env(safe-area-inset-*)` vale 0 dentro del iframe: los safe areas se revisan leyendo el CSS, no midiendo.
- Requiere **mismo origen**; una URL externa se muestra pero no se puede medir (lo dice en pantalla).

## Fallback para CI: Playwright

Si el proyecto ya tiene Playwright instalado:

```bash
node <dir-de-este-skill>/scripts/shots.mjs http://localhost:3000 ./passport-shots
```

Emula DPR y user-agent, y devuelve exit≠0 si algún perfil falla. Si Playwright no está instalado,
**no lo instales sin preguntar**: usa el harness.

## Extra

`read_console_messages` — los errores de JS dependientes del tamaño (carruseles, `ResizeObserver`)
solo aparecen en ciertos viewports. `gif_creator` cuando el usuario quiera un recorrido animado.
