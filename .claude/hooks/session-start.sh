#!/bin/bash
# SessionStart hook - BigBrain hafizasini context'e enjekte eder.
# Tasinabilirlik: jq -> python3 -> python -> node fallback zinciri.
# Hicbiri yoksa gorunur uyari basar (sessiz cokme YASAK - kontrol noktasi).
set -euo pipefail

# Global hook varsa devre disi kal (L-0062 cift tetikleme korumasi)
[ -f "$HOME/.claude/hooks/global-session-start.sh" ] && exit 0

DIR="${CLAUDE_PROJECT_DIR:-.}"
OUT="$(mktemp)"
trap 'rm -f "$OUT" "$OUT.tmp"' EXIT

{
  echo "BigBrain hafizasi yuklendi (SessionStart hook)."
  echo "Gecmis projelerden cikarilmis dersleri (L-XXXX) dikkate al, ayni hatayi tekrarlama."
  echo
  if [ -f "$DIR/lessons/INDEX.md" ]; then
    DERS_SAYISI=$(grep -c '^## L-' "$DIR/lessons/INDEX.md" 2>/dev/null || echo 0)
    echo "=== DERSLER (Toplam: $DERS_SAYISI, son 12 gosteriliyor) ==="
    grep '^## L-' "$DIR/lessons/INDEX.md" 2>/dev/null | tail -12 || true
    echo "Onceki dersler ve detay icin lessons/INDEX.md oku."
    echo
  fi
  if [ -f "$DIR/projects/INDEX.md" ]; then
    PROJE_SAYISI=$(grep -cE '^\| [^-]' "$DIR/projects/INDEX.md" 2>/dev/null || echo 0)
    echo "=== PROJELER (Toplam: $PROJE_SAYISI) ==="
    echo "Detay: projects/INDEX.md"
    echo
  fi
  echo "Detay gerekirse: lessons/INDEX.md ve projects/INDEX.md dosyalarini oku."
} > "$OUT"
head -c 1800 "$OUT" > "$OUT.tmp" && mv "$OUT.tmp" "$OUT"

emit_json() {
  if command -v jq >/dev/null 2>&1 && echo '""' | jq . >/dev/null 2>&1; then
    jq -Rs '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:.}}' < "$OUT"
  elif python3 -c "pass" >/dev/null 2>&1; then
    python3 -c 'import json,sys;print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.stdin.read()}}))' < "$OUT"
  elif python -c "pass" >/dev/null 2>&1; then
    python -c 'import json,sys;print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.stdin.read()}}))' < "$OUT"
  elif node -e "" >/dev/null 2>&1; then
    node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>console.log(JSON.stringify({hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:d}})))' < "$OUT"
  else
    echo '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"UYARI: BigBrain hafizasi YUKLENEMEDI - jq/python/node hicbiri bulunamadi. Dersler bu session icin kayip. Kullaniciya bildir."}}'
  fi
}
emit_json
