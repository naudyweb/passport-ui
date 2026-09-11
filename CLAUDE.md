# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es este repositorio

**No es una aplicación: es un plugin de Claude Code.** El "producto" son instrucciones que otro agente
leerá — `SKILL.md`, los comandos y las referencias — más tres herramientas ejecutables. Editar
`SKILL.md` no cambia código en ejecución: cambia el comportamiento de un agente futuro. Escribe esos
archivos pensando en quien los va a *seguir*, no en quien los va a *leer*.

El dominio: adaptar UI web a viewports **anchos y cortos** (formato pasaporte, covers de plegables) y
a plegables abiertos. La regla que ordena todo el contenido: *el layout se decide con ancho, alto y
aspect-ratio, nunca solo con el ancho.*

**Toda la documentación está en español.** Mantenlo.

## Estructura

```
.claude-plugin/marketplace.json   marketplace local; "source": "./passport-ui"
AGENTS.md                         misma doctrina para agentes que no son Claude Code
passport-ui/
  .claude-plugin/plugin.json
  commands/                       3 comandos, ver abajo
  skills/passport-ui/
    SKILL.md                      núcleo delgado; solo esto se carga al activarse
    references/                   5 documentos, cargados bajo demanda
    scripts/scan.sh               escáner estático
    scripts/shots.mjs             fallback de CI con Playwright
    assets/harness.html           banco de pruebas en el navegador
```

## Desarrollo y verificación

**No hay build, ni linter, ni runner de tests.** La verificación es manual y consiste en tres cosas:

```bash
# 1. El escáner, contra un directorio con CSS
bash passport-ui/skills/passport-ui/scripts/scan.sh <ruta>
bash -n passport-ui/skills/passport-ui/scripts/scan.sh     # sintaxis
node --check passport-ui/skills/passport-ui/scripts/shots.mjs
```

```bash
# 2. El harness, en el navegador. SIEMPRE a loopback.
cp passport-ui/skills/passport-ui/assets/harness.html <dir-servido>/
python3 -m http.server 8731 --bind 127.0.0.1
# abrir http://localhost:8731/harness.html?url=<url-codificada>
# medir con probeAll() en consola; simulateUnfold() para la apertura
```

Chrome **no navega a `file://`** desde el MCP: sirve siempre por HTTP.

**3. Al tocar `scan.sh`, prueba contra fixtures con y sin el patrón.** No hay fixtures versionados —
créalos en el scratchpad. Un cambio en el escáner no está verificado hasta que detecta el caso malo
**y** deja limpio el caso bueno. Si un fixture "limpio" empieza a saltar, comprueba si es un verdadero
positivo antes de ablandar la regla: suele serlo.

## Arquitectura

### Divulgación progresiva

`SKILL.md` (~110 líneas) contiene la regla madre, dos flujos y un índice. Todo lo detallado vive en
`references/` y se carga solo cuando hace falta. **No engordes `SKILL.md`**: si una explicación crece,
va a una referencia.

### Doble audiencia, y la convención de rutas que la sostiene

El contenido sirve a Claude Code (como plugin) y a otros agentes (vía `AGENTS.md`). De ahí una
invariante que es fácil romper sin darse cuenta:

- **`${CLAUDE_PLUGIN_ROOT}` solo puede aparecer en `commands/`.** Los comandos únicamente existen
  dentro de un plugin.
- **Dentro de `skills/`, las rutas son relativas al directorio del skill.** Si esa variable aparece
  en `SKILL.md` o en `references/`, se rompe para quien copie la carpeta suelta a `~/.claude/skills/`.

### Los tres comandos tienen papeles disjuntos

| Comando | Papel | `allowed-tools` |
|---|---|---|
| `/passport-optimize` | mide, corrige, vuelve a medir | incluye `Edit` |
| `/passport-audit` | solo diagnóstico | **sin `Edit`**, a propósito |
| `/passport-check` | solo verificación visual | sin `Edit` |

Que `audit` no pueda escribir es una decisión, no un descuido. No le devuelvas `Edit`.

### `scan.sh`: cuatro tipos de comprobación

- `report` — patrón presente en archivos CSS/plantilla (severidad, línea, arreglo).
- `report_js` — igual, sobre un conjunto **aparte** de archivos JS/TS. Existe para que las reglas de
  CSS no generen ruido sobre código JavaScript.
- `absence` — algo que debería estar y no está en todo el proyecto.
- `absence_if` — algo presente al que le falta su guarda (p. ej. `:hover` sin `@media (hover: hover)`).

Cada regla cita el archivo y la sección de `references/` que la arregla. Mantén esa disciplina: un
hallazgo sin arreglo concreto no sirve.

**`scan.sh` nunca debe ejecutar contenido del proyecto analizado.** Solo `find` y `grep`. Nada de
`eval` ni sustitución de comandos sobre datos ajenos.

### `harness.html`: por qué iframes, y sus invariantes de seguridad

Mide cargando la página objetivo en **un iframe por perfil**, no redimensionando la ventana: bajo un
gestor tiling la petición de redimensionado se ignora en silencio y falsea toda medición.

Dos invariantes, ambas producto de XSS reales ya corregidos:

- **Nada que venga de la página analizada entra por `innerHTML`.** El informe se construye con nodos y
  `textContent`; los nombres de clase se sanean en la propia sonda. Los únicos `innerHTML` que quedan
  interpolan constantes internas.
- **`iframe.src` solo acepta `http:` y `https:`.** Un `src="javascript:…"` ejecuta con el origen del
  harness. La validación está en `safeUrl()`.

`harness.html` es una herramienta de depuración que se copia a la raíz servida del proyecto: la
documentación debe seguir avisando de borrarla y de no desplegarla.

### Duplicaciones que hay que mantener sincronizadas

- **Los perfiles de viewport están en dos sitios**: `harness.html` y `shots.mjs`. Son 6 y deben
  coincidir. `devices.md` los documenta.
- **"Límites conocidos" aparece en tres documentos**: `SKILL.md`, `AGENTS.md` y `README.md`. Si cambia
  lo que está o no verificado, cambia en los tres.

## Alcance del contenido

El skill se ocupa de que el contenido **quepa y sea usable**. No decide dirección estética —
tipografía, paleta, personalidad visual. Esa frontera está escrita en `SKILL.md`, `AGENTS.md` y
`README.md`; respétala al añadir patrones.

Nada se ha probado en un plegable físico. Los patrones de bisagra (`patterns.md` §11) y
`env(safe-area-inset-*)` **no están verificados en hardware real**, y la documentación lo dice de forma
explícita. No retires esas advertencias sin medidas de un dispositivo.

## Publicación

Repo público en `naudyweb/passport-ui`; el marketplace vive en la raíz. Se instala con
`/plugin marketplace add naudyweb/passport-ui` y `/plugin install passport-ui`. Un `git push` a `main`
publica: la rama es la distribución.
