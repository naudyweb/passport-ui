---
description: Diagnostica un proyecto web para pantallas formato pasaporte (anchas y cortas). Informa, no modifica.
argument-hint: "[ruta] (por defecto: directorio actual)"
allowed-tools: Bash, Read, Glob, Grep
---

Audita el proyecto en `$1` (o el directorio actual si no se indica) para viewports **anchos y cortos**
(formato pasaporte: covers de plegables, 16:10, 5:3, 16:9.5).

Sigue el **Flujo B** del skill `passport-ui`:

1. Ejecuta el escáner:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/passport-ui/scripts/scan.sh" "${1:-.}"
   ```
2. Lee `${CLAUDE_PLUGIN_ROOT}/skills/passport-ui/references/antipatterns.md` e interpreta cada hallazgo:
   descarta los falsos positivos documentados allí antes de tocar nada.
3. Presenta los hallazgos reales agrupados por severidad, cada uno con el arreglo concreto de
   `references/patterns.md` y el archivo y línea donde aplica.
4. Cierra con el orden de ataque recomendado y el impacto esperado de cada grupo.

**Este comando no modifica archivos.** Es diagnóstico. Para aplicar las correcciones y dejar el
proyecto optimizado, `/passport-optimize`. Para solo verificar en el navegador, `/passport-check`.
