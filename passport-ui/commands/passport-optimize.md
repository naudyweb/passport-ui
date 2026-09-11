---
description: Optimiza un proyecto para pantallas formato pasaporte y plegables: mide, aplica las correcciones y vuelve a medir.
argument-hint: "[ruta] [url-del-dev-server]"
allowed-tools: Bash, Read, Edit, Glob, Grep, ToolSearch, mcp__claude-in-chrome__*
---

Deja el proyecto de `$1` (o el directorio actual) **optimizado** para viewports anchos y cortos y para
plegables. A diferencia de `/passport-audit`, que solo informa, este comando **aplica los cambios**.

`$2` es la URL del dev server; si no se indica, usa `http://localhost:3000`. Si no hay servidor
levantado, sáltate los pasos de medición y dilo explícitamente en el informe final.

## 0. Antes de tocar nada

```bash
git -C "${1:-.}" status --porcelain 2>/dev/null | head -5
```

- **Repo limpio** → adelante: el usuario podrá revisar todo con `git diff`.
- **Repo con cambios sin confirmar, o no es un repo** → avisa de que vas a editar archivos sin una
  línea base para revertir, y **espera confirmación** antes de continuar.

## 1. Medir el estado inicial

Sigue `${CLAUDE_PLUGIN_ROOT}/skills/passport-ui/references/verify.md`. Guarda las cifras de cada perfil: chrome fijo %, pantallas de scroll,
medida de línea en ch, scroll horizontal y qué desborda. Son la línea base del informe final.

## 2. Detectar

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/passport-ui/scripts/scan.sh" "${1:-.}"
```

Interpreta cada hallazgo con `${CLAUDE_PLUGIN_ROOT}/skills/passport-ui/references/antipatterns.md` y **descarta los falsos positivos que ese
archivo documenta** antes de tocar nada.

## 3. Planificar

Presenta el plan en una lista corta: archivo, qué cambia y por qué, agrupado por severidad. Si hay
más de 15 cambios, resume por patrón en lugar de enumerarlos uno a uno.

## 4. Aplicar

En este orden, y con el arreglo de `${CLAUDE_PLUGIN_ROOT}/skills/passport-ui/references/patterns.md` que corresponda a cada caso:

1. `CRITICAL` — rompen la primera pantalla: `vh` → `dvh`, breakpoints de tres entradas, presupuesto
   vertical del chrome fijo, modales con alto máximo.
2. `WARN` — degradan la experiencia: medida de línea, anchos fijos, `aspect-ratio` sin tope,
   tipografía por `vmin`, hover guardado, espaciado que escala.
3. `INFO` — solo si son triviales y sin riesgo (`viewport-fit=cover`, safe areas).

Reglas de edición:

- **Cambios mínimos.** Modifica las declaraciones afectadas, no reescribas hojas de estilo ni
  componentes enteros.
- **Conserva los fallbacks.** `min-height: 100vh` se queda como línea previa a `100dvh`.
- **No toques la dirección estética**: tipografía, paleta y personalidad visual son del proyecto.
- **No inventes breakpoints nuevos** donde una rejilla `auto-fit` o una container query resuelven.

## 5. Verificar

Repite la medición del paso 1 sobre los mismos perfiles. Si algún perfil empeora — en especial el
control `phone-tall` — revierte ese cambio concreto e indícalo.

## 6. Informar

Cierra con:

- **Tabla antes/después** por perfil: chrome %, scroll, medida en ch, veredicto.
- **Resumen del diff**: archivos tocados y número de cambios por patrón.
- **Lo que no se aplicó** y por qué (falso positivo, riesgo, requiere decisión de diseño).
- **Lo que no es verificable aquí**: bisagra, safe areas y postura a medio plegar, según
  la sección de límites conocidos.
