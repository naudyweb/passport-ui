---
description: Audita un proyecto web para pantallas formato pasaporte (anchas y cortas) y aplica los arreglos.
argument-hint: "[ruta] (por defecto: directorio actual)"
allowed-tools: Bash, Read, Edit, Glob, Grep
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
3. Presenta los hallazgos reales agrupados por severidad, cada uno con el arreglo concreto que propones
   (tomado de `references/patterns.md`). **Espera confirmación antes de editar.**
4. Aplica los arreglos aprobados, empezando por los CRITICAL.
5. Verifica siguiendo `references/verify.md`: captura del mismo perfil antes y después.

No reescribas la dirección estética del proyecto: solo lo que impide que el contenido quepa y sea usable.
