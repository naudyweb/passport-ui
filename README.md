<h1 align="center">passport-ui</h1>

<p align="center">
  <strong>Interfaces web que sobreviven a las pantallas anchas y cortas.</strong><br>
  Auditoría, corrección y verificación visual para viewports de formato pasaporte.
</p>

<p align="center">
  <a href="LICENSE"><img alt="Licencia MIT" src="https://img.shields.io/badge/licencia-MIT-blue.svg"></a>
  <img alt="Sin dependencias" src="https://img.shields.io/badge/dependencias-ninguna-brightgreen.svg">
  <img alt="Claude Code y AGENTS.md" src="https://img.shields.io/badge/compatible-Claude%20Code%20%C2%B7%20AGENTS.md-8A63D2.svg">
</p>

---

## El problema

Las pantallas de los móviles están volviendo a ser **anchas y cortas**: covers de plegables, formatos
pasaporte, relaciones de aspecto 16:10, 5:3 y 16:9.5.

Un viewport de 880×550 px CSS entra por los breakpoints de tablet **porque es ancho**, pero tiene la
altura de un móvil apaisado. El CSS de la última década asume justo lo contrario — móvil igual a
estrecho y alto — y el resultado es predecible:

- héroes de `100vh` que ocupan tres pantallas
- headers y footers fijos que consumen el 60% del alto útil
- modales más altos que la pantalla, con los botones fuera de alcance
- titulares escalados por el ancho que quedan desproporcionados

`passport-ui` detecta esos fallos, propone el arreglo concreto y verifica el resultado contra perfiles
de viewport reales.

## Características

| | |
|---|---|
| **Auditoría estática** | 13 anti-patrones con severidad, línea exacta y arreglo sugerido. Bash y grep: sin instalación, sin dependencias |
| **Verificación visual** | Banco de pruebas que carga la página en un iframe por perfil y mide chrome fijo, scroll y desbordamientos |
| **Simulación de apertura** | Transición de cover a plegable abierto sin recargar, para comprobar que el estado del usuario sobrevive |
| **Corpus de patrones** | Cinco referencias sobre unidades, breakpoints de tres entradas, container queries, bisagras y detección de plegables |
| **Listo para CI** | Script de Playwright que devuelve código de salida distinto de cero cuando un perfil falla |

## Instalación

**Claude Code** — skill con activación automática y dos comandos:

```
/plugin marketplace add naudyweb/passport-ui
/plugin install passport-ui
```

**Otros agentes** (Codex, Copilot, Cursor, Gemini CLI, Aider, Zed, Windsurf) — vía
[`AGENTS.md`](AGENTS.md), el formato de instrucciones de la Linux Foundation:

```bash
git submodule add https://github.com/naudyweb/passport-ui .passport-ui
```

Después, copia el contenido de [`AGENTS.md`](AGENTS.md) al `AGENTS.md` del proyecto. Ese archivo
documenta las dos formas de instalación y las rutas que resultan de cada una.

**Sin agente** — las herramientas funcionan solas:

```bash
bash .passport-ui/passport-ui/skills/passport-ui/scripts/scan.sh ./src
```

## Uso

En Claude Code el skill se activa solo al trabajar en layouts responsive. Para invocarlo a mano:

```
/passport-audit ./src                     # auditar y aplicar correcciones
/passport-check http://localhost:3000     # solo verificar
```

Desde la línea de comandos:

```bash
scan.sh <ruta>                       # informe de anti-patrones
node shots.mjs <url> <dir-salida>    # capturas y veredicto por perfil
```

## Cómo funciona

La regla que ordena todo el proyecto:

> **El layout no se decide solo por el ancho.** Cada decisión usa las tres entradas: ancho, alto y
> aspect-ratio.

La verificación carga la página objetivo en **iframes dimensionados a cada perfil**, en lugar de
redimensionar la ventana del navegador. Las media queries, `dvh`, `cqi` y `aspect-ratio` responden al
tamaño del iframe, de modo que la medición equivale a la de un dispositivo real y no depende del
gestor de ventanas — los gestores tiling ignoran las peticiones de redimensionado sin avisar, lo que
falsea silenciosamente cualquier prueba basada en ellas.

Perfiles incluidos: `passport-cover-xs`, `passport-cover`, `passport-wide`, `unfolded` y `phone-tall`
como control de regresión.

## Resultados

Una landing convencional, medida en el perfil `passport-cover-xs` (820×490):

| Métrica | Antes | Después |
|---|---|---|
| Chrome fijo | 31% del alto | 11% |
| Scroll hasta la acción principal | 2,3 pantallas | 1 |
| Veredicto | FALLA | pasa |

## Requisitos

Bash y `grep` para la auditoría. Un navegador para la verificación. Node y Playwright únicamente para
el script opcional de CI.

## Alcance

`passport-ui` no decide la dirección estética de un proyecto — tipografía, paleta, personalidad
visual. Se ocupa exclusivamente de que el contenido quepa y sea usable en viewports anchos y cortos.

## Licencia

[MIT](LICENSE)
