#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <input.md>" >&2
  exit 1
fi

BUNDLE_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT_MD="$1"
DOC_ROOT="$(cd "$(dirname "$INPUT_MD")" && pwd)"
INPUT_FILE="$(basename "$INPUT_MD")"
DOC_NAME="${INPUT_FILE%.*}"
TEMPLATES_DIR="$BUNDLE_DIR/cs.ext.md_bundle"
MDTOHTML_PY="$BUNDLE_DIR/mdtohtml.py"
PLANTUML_JAR="$BUNDLE_DIR/plantuml.8055.jar"
WKHTMLTOPDF_EXE="$BUNDLE_DIR/bin/wkhtmltopdf.exe"
LOCAL_WKHTML_DIR="$BUNDLE_DIR/.tools/wkhtmltox/dist"

cd "$DOC_ROOT"

if [[ "${MDTOHTML_GIT_PULL:-0}" == "1" ]] && [[ -d "$TEMPLATES_DIR/.git" ]] && command -v git >/dev/null 2>&1; then
  git -C "$TEMPLATES_DIR" pull --ff-only || true
fi

TEMPLATES_SLASH="${TEMPLATES_DIR//\\//}"
export BIBFILE="${BIBFILE:-$TEMPLATES_DIR/local.bib}"
export OVERRIDE_BIBFILE="${OVERRIDE_BIBFILE:-$TEMPLATES_DIR/local_override.bib}"
export EXT_BIBFILE="${EXT_BIBFILE:-$TEMPLATES_DIR/external.bib}"

python3 "$MDTOHTML_PY" "$INPUT_FILE" \
  -t "$TEMPLATES_DIR/tieto_templates/main.template.html" "$DOC_NAME.html" \
  -p logo "file:///$TEMPLATES_SLASH/tieto_templates/tieto_logo_blue.svg" \
  -p filename "$DOC_NAME.pdf" \
  -p cssroot "file:///$TEMPLATES_SLASH" \
  -t "$TEMPLATES_DIR/tieto_templates/header.template.html" "$DOC_NAME.header.html" \
  -t "$TEMPLATES_DIR/tieto_templates/footer.template.html" "$DOC_NAME.footer.html" \
  -t "$TEMPLATES_DIR/tieto_templates/cover.template.html" "$DOC_NAME.cover.html" \
  -t "$TEMPLATES_DIR/tieto_templates/toc.template.xsl" "$DOC_NAME.toc.xsl" > "$DOC_NAME.images"

if [[ -f "$DOC_NAME.images" ]]; then
  while IFS=: read -r kind path_rest; do
    [[ "$kind" == "image" ]] || continue
    [[ -n "$path_rest" ]] || continue
    if [[ -f "$path_rest" ]]; then
      continue
    fi

    template_fallback="$TEMPLATES_DIR/tieto_templates/$(basename "$path_rest")"
    if [[ -f "$template_fallback" ]]; then
      mkdir -p "$(dirname "$path_rest")"
      cp "$template_fallback" "$(dirname "$path_rest")/"
      continue
    fi

    if [[ -f "$PLANTUML_JAR" ]]; then
      while IFS= read -r uml_source; do
        java -Djava.awt.headless=true -jar "$PLANTUML_JAR" \
          -config "$TEMPLATES_DIR/tieto_templates/plantuml.cfg" \
          -v -o "$(dirname "$uml_source")/." "$uml_source"
      done < <(grep -rl -- "@startuml[[:space:]]*$(basename "$path_rest")" "$(dirname "$path_rest")" 2>/dev/null || true)
    fi
  done < "$DOC_NAME.images"
fi

if command -v wkhtmltopdf >/dev/null 2>&1; then
  wkhtmltopdf_cmd=(wkhtmltopdf)
  wkhtmltopdf_env=()
elif [[ -x "$LOCAL_WKHTML_DIR/bin/wkhtmltopdf" ]]; then
  wkhtmltopdf_cmd=("$LOCAL_WKHTML_DIR/bin/wkhtmltopdf")
  wkhtmltopdf_env=("DYLD_LIBRARY_PATH=$LOCAL_WKHTML_DIR/lib")
else
  wkhtmltopdf_cmd=()
  wkhtmltopdf_env=()
fi

wkhtml_ok=0
if [[ ${#wkhtmltopdf_cmd[@]} -gt 0 ]]; then
  set +e
  env "${wkhtmltopdf_env[@]}" "${wkhtmltopdf_cmd[@]}" \
    --enable-local-file-access \
    --load-error-handling ignore \
    --load-media-error-handling ignore \
    --page-size A4 \
    --margin-top 22mm \
    --margin-bottom 22mm \
    --margin-left 15mm \
    --margin-right 10mm \
    --header-spacing 5 \
    --footer-spacing 5 \
    --header-html "$DOC_NAME.header.html" \
    --footer-html "$DOC_NAME.footer.html" \
    page "$DOC_NAME.cover.html" \
    toc --xsl-style-sheet "$DOC_NAME.toc.xsl" \
    page "$DOC_NAME.html" "$DOC_NAME.pdf"
  wkhtml_exit=$?
  set -e

  if [[ $wkhtml_exit -eq 0 ]] && grep -aq "/Type /Page" "$DOC_NAME.pdf"; then
    wkhtml_ok=1
  else
    echo "Warning: wkhtmltopdf did not produce a valid PDF, falling back to WeasyPrint." >&2
  fi
fi

if [[ $wkhtml_ok -eq 0 ]]; then
  if command -v weasyprint >/dev/null 2>&1; then
    weasyprint "$DOC_NAME.html" "$DOC_NAME.pdf"
  else
    echo "Error: no working PDF renderer found (wkhtmltopdf failed, weasyprint missing)." >&2
    exit 1
  fi
fi

rm -f "$DOC_NAME.header.html" "$DOC_NAME.footer.html" "$DOC_NAME.cover.html" "$DOC_NAME.toc.xsl" "$DOC_NAME.images"

echo "Generated: $DOC_ROOT/$DOC_NAME.pdf"