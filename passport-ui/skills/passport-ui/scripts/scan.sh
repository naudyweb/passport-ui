#!/usr/bin/env bash
# passport-ui: escáner estático de anti-patrones de layout para viewports anchos y cortos.
# Uso: scan.sh [ruta]   (por defecto: directorio actual)
set -uo pipefail

ROOT="${1:-.}"
[ -d "$ROOT" ] || { echo "scan.sh: '$ROOT' no es un directorio" >&2; exit 2; }

EXCLUDE_DIRS='node_modules|\.git|dist|build|out|\.next|\.nuxt|vendor|coverage|\.venv|__pycache__'
FILES=$(find "$ROOT" -type f \
  \( -name '*.css' -o -name '*.scss' -o -name '*.sass' -o -name '*.less' \
     -o -name '*.html' -o -name '*.vue' -o -name '*.svelte' \
     -o -name '*.jsx' -o -name '*.tsx' -o -name '*.astro' \) \
  2>/dev/null | grep -Ev "/($EXCLUDE_DIRS)/")

[ -z "$FILES" ] && { echo "No se encontraron archivos de estilos/plantillas en '$ROOT'."; exit 0; }

FILES_JS=$(find "$ROOT" -type f \
  \( -name '*.js' -o -name '*.mjs' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx' \
     -o -name '*.vue' -o -name '*.svelte' \) \
  2>/dev/null | grep -Ev "/($EXCLUDE_DIRS)/" | grep -Ev '\.(min|bundle)\.js$')

FILE_COUNT=$(echo "$FILES" | wc -l)
TOTAL=0
declare -A COUNTS=([CRITICAL]=0 [WARN]=0 [INFO]=0)

# report SEVERIDAD "regla" "regex" "arreglo" [regex_de_exclusion]
report() {
  local sev="$1" rule="$2" re="$3" fix="$4" skip="${5:-}"
  local hits
  hits=$(echo "$FILES" | tr '\n' '\0' | xargs -0 grep -nEH "$re" 2>/dev/null)
  [ -n "$skip" ] && hits=$(echo "$hits" | grep -Ev "$skip")
  hits=$(echo "$hits" | grep -v '^$')
  [ -z "$hits" ] && return 0
  local n; n=$(echo "$hits" | wc -l)
  COUNTS[$sev]=$(( COUNTS[$sev] + n )); TOTAL=$(( TOTAL + n ))
  echo "── [$sev] $rule  ($n)"
  echo "   arreglo: $fix"
  echo "$hits" | head -20 | sed -e "s|^${ROOT%/}/||" -e 's/^/   /'
  [ "$n" -gt 20 ] && echo "   … y $(( n - 20 )) más"
  echo
}

# report_js SEVERIDAD "regla" "regex" "arreglo"  → sobre archivos JS/TS
report_js() {
  local sev="$1" rule="$2" re="$3" fix="$4"
  [ -z "$FILES_JS" ] && return 0
  local hits
  hits=$(echo "$FILES_JS" | tr '\n' '\0' | xargs -0 grep -nEH "$re" 2>/dev/null | grep -v '^$')
  [ -z "$hits" ] && return 0
  local n; n=$(echo "$hits" | wc -l)
  COUNTS[$sev]=$(( COUNTS[$sev] + n )); TOTAL=$(( TOTAL + n ))
  echo "── [$sev] $rule  ($n)"
  echo "   arreglo: $fix"
  echo "$hits" | head -20 | sed -e "s|^${ROOT%/}/||" -e 's/^/   /'
  [ "$n" -gt 20 ] && echo "   … y $(( n - 20 )) más"
  echo
}

# absence_if SEVERIDAD "regla" "regex_presente" "regex_guarda" "mensaje"
#   → informa si lo primero aparece en el proyecto pero su guarda no
absence_if() {
  local sev="$1" rule="$2" re="$3" guard="$4" msg="$5"
  echo "$FILES" | tr '\n' '\0' | xargs -0 grep -lE "$re" >/dev/null 2>&1 || return 0
  echo "$FILES" | tr '\n' '\0' | xargs -0 grep -lE "$guard" >/dev/null 2>&1 && return 0
  COUNTS[$sev]=$(( COUNTS[$sev] + 1 )); TOTAL=$(( TOTAL + 1 ))
  echo "── [$sev] $rule"
  echo "   $msg"
  echo
}

# absence RULE "regex" "mensaje"  → informa si NO aparece en ningún archivo
absence() {
  local rule="$1" re="$2" msg="$3"
  if ! echo "$FILES" | tr '\n' '\0' | xargs -0 grep -lE "$re" >/dev/null 2>&1; then
    COUNTS[INFO]=$(( COUNTS[INFO] + 1 )); TOTAL=$(( TOTAL + 1 ))
    echo "── [INFO] $rule  (0 apariciones en todo el proyecto)"
    echo "   $msg"
    echo
  fi
}

echo "passport-ui scan · $ROOT · $FILE_COUNT archivos"
echo "=================================================================="
echo

report CRITICAL "vh en alturas de layout (usa dvh/svh)" \
  '(min-|max-)?height[[:space:]]*:[[:space:]]*[0-9.]+vh|h-\[[0-9.]+vh\]|(min-h|max-h|h)-screen' \
  'patterns.md §1 — min-height:100dvh con fallback vh' \
  'dvh|svh|lvh|@supports'

report CRITICAL "media query solo por ancho" \
  '@media[^{]*\((min|max)-width[^{]*\)' \
  'patterns.md §3 — añade height / aspect-ratio a la condición' \
  'height|aspect-ratio'

report CRITICAL "position:fixed / sticky (revisa el presupuesto vertical del 15%)" \
  'position[[:space:]]*:[[:space:]]*(fixed|sticky)|\bfixed (top|bottom|inset)|\bsticky\b' \
  'patterns.md §5 — header+footer fijos juntos no caben; pasa uno a rail lateral'

report CRITICAL "altura fija en modal/drawer/dialog/overlay/sheet" \
  '\.(modal|drawer|dialog|overlay|sheet|popup)[^{]*\{[^}]*height[[:space:]]*:[[:space:]]*[0-9]{3,}px' \
  'patterns.md §10 — max-block-size:min(90dvh,40rem) + cuerpo con scroll'

report WARN "orientation: portrait|landscape como sinónimo de dispositivo" \
  '\(orientation[[:space:]]*:' \
  'antipatterns.md §5 — usa aspect-ratio, la orientación no dice nada útil'

report WARN "aspect-ratio en media a ancho completo sin tope de alto" \
  'aspect-ratio[[:space:]]*:[[:space:]]*(16[[:space:]]*/[[:space:]]*9|21[[:space:]]*/[[:space:]]*9|2[[:space:]]*/[[:space:]]*1)|aspect-video' \
  'patterns.md §8 — añade max-block-size: 45dvh' \
  'max-block-size|max-height'

report WARN "tipografía escalada por vw (usa vmin o cqi)" \
  'font-size[[:space:]]*:[^;]*[0-9.]+vw' \
  'patterns.md §4 — clamp(1.75rem, 4vmin + .5rem, 3.5rem)'

report WARN "scroll-snap vertical / secciones a pantalla completa" \
  'scroll-snap-type[[:space:]]*:[[:space:]]*y' \
  'antipatterns.md §8 — a 490px de alto cada sección pierde la mitad del contenido'

report WARN "padding/margin vertical fijo y grande (>64px)" \
  '(padding|margin)(-block|-top|-bottom)?[[:space:]]*:[^;]*\b([6-9][4-9]|[1-9][0-9]{2,})px' \
  'patterns.md §9 — clamp(1.5rem, 6dvh, 5rem)'

report_js WARN "user-agent sniffing para decidir layout" \
  'navigator\.(userAgent|userAgentData|platform|vendor)|window\.orientation\b' \
  'detection.md — el UA no dice la forma del viewport; usa matchMedia sobre aspect-ratio y altura'

report_js WARN "escucha resize para relayout (matchMedia dispara solo en el umbral)" \
  "addEventListener\\([\\\"']resize[\\\"']" \
  'detection.md §Nivel 0 — matchMedia(q).addEventListener("change", …)'

report_js INFO "usa devicePosture / viewport segments desde JS" \
  'devicePosture|viewport-segment|windowSegments' \
  'detection.md — solo Chromium: asegúrate de que hay una regla de forma equivalente detrás'

report INFO "usa device-posture / viewport-segments en CSS" \
  'device-posture|horizontal-viewport-segments|vertical-viewport-segments' \
  'detection.md — acabado, no cimiento: la página debe estar bien sin esto en Safari/Firefox'

# ── pantalla abierta: el problema deja de ser que falte alto y pasa a que sobre ancho

absence_if WARN "sin tope de medida de línea" \
  'font-size|line-height|<p[ >]|<article' \
  'max-(width|inline-size)[^;]*[0-9]+(ch|em)|\bmax-w-(prose|\[[0-9]+ch\])' \
  'En la pantalla abierta (1000px) el texto sin tope se estira a más de 100 caracteres por línea
   y deja de ser legible. patterns.md §13 — max-inline-size: 65ch en los contenedores de texto.'

absence_if WARN ":hover sin guardar tras @media (hover: hover)" \
  ':hover' \
  '\(hover:[[:space:]]*hover\)|\(any-hover' \
  'El interior de un plegable es una pantalla táctil grande, no un escritorio: lo que solo se
   alcanza con hover queda inaccesible. patterns.md §13.'

report WARN "contenedor con ancho fijo grande (no se adapta a la pantalla abierta)" \
  '(width|max-width|min-width)[[:space:]]*:[[:space:]]*(1[2-9][0-9]{2}|[2-9][0-9]{3})px' \
  'patterns.md §13 — min(<ancho>, 100%) o una rejilla que reflowe, no un ancho fijo'

absence "sin env(safe-area-inset-*)" 'safe-area-inset' \
  'Si hay elementos fijos en los bordes, en apaisado los insets laterales recortan contenido. patterns.md §12'
absence "sin container queries" '@container|container-type' \
  'Cada formato nuevo va a exigir un breakpoint nuevo. patterns.md §6'
absence "sin viewport-fit=cover" 'viewport-fit[[:space:]]*=[[:space:]]*cover' \
  'Sin él, env(safe-area-inset-*) siempre vale 0. patterns.md §12'

echo "=================================================================="
printf 'Total: %d hallazgos · CRITICAL %d · WARN %d · INFO %d\n' \
  "$TOTAL" "${COUNTS[CRITICAL]}" "${COUNTS[WARN]}" "${COUNTS[INFO]}"
echo
echo "Siguiente paso: leer references/antipatterns.md, corregir los CRITICAL,"
echo "y verificar con references/verify.md antes de dar nada por hecho."
[ "${COUNTS[CRITICAL]}" -gt 0 ] && exit 1
exit 0
