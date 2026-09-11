---
description: Verifica visualmente una URL en tamaños de pantalla formato pasaporte usando Chrome.
argument-hint: "<url> (por defecto: http://localhost:3000)"
allowed-tools: Bash, Read, ToolSearch, mcp__claude-in-chrome__*
---

Verifica `$1` (o `http://localhost:3000`) en viewports anchos y cortos. **Solo verificación: no edites código.**

Sigue el protocolo de `${CLAUDE_PLUGIN_ROOT}/skills/passport-ui/references/verify.md`:

1. Carga las herramientas de Chrome en una sola llamada a ToolSearch (la lista está en `verify.md`).
2. Copia `assets/harness.html` a la raíz servida del proyecto y ábrelo con `?url=<la-url>`.
   No uses `resize_window`: bajo un WM tiling no cambia el viewport y la medición sale falseada.
3. Mide con `javascript_tool` → `probeAll()`, y captura con `computer` → `screenshot`.
4. Informa en una tabla: perfil · chrome fijo % · scroll horizontal · elementos desbordados ·
   qué queda fuera de la primera pantalla.
5. Termina con un veredicto por perfil (pasa / falla) y los tres arreglos de mayor impacto,
   citando la sección de `references/patterns.md` correspondiente.
