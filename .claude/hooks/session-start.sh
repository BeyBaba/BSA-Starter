#!/bin/bash
# SessionStart hook (BSA-Starter şablonu) — projeler-arası hafızayı yükler.
# Claude-Memory reposundan lessons/INDEX.md + projects/INDEX.md'yi sparse çekip
# context'e enjekte eder. Erişim/ağ yoksa ASLA bloklamaz; tek satır uyarı geçer.
set -euo pipefail

MEM_REPO="https://github.com/BeyBaba/Claude-Memory.git"
TMP="$(mktemp -d)"
OUT="$(mktemp)"
trap 'rm -rf "$TMP" "$OUT"' EXIT

fetched=0
if git clone --depth 1 --filter=blob:none --sparse "$MEM_REPO" "$TMP/mem" >/dev/null 2>&1; then
  git -C "$TMP/mem" sparse-checkout set lessons projects >/dev/null 2>&1 || true
  [ -f "$TMP/mem/lessons/INDEX.md" ] && fetched=1
fi

{
  if [ "$fetched" = "1" ]; then
    echo "📚 Projeler-arası hafıza yüklendi (Claude-Memory / SessionStart hook)."
    echo "Geçmiş projelerden çıkarılmış dersleri (L-XXXX) dikkate al, aynı hatayı tekrarlama."
    echo
    echo "=== Claude-Memory/lessons/INDEX.md ==="
    cat "$TMP/mem/lessons/INDEX.md"
    echo
    if [ -f "$TMP/mem/projects/INDEX.md" ]; then
      echo "=== Claude-Memory/projects/INDEX.md ==="
      cat "$TMP/mem/projects/INDEX.md"
    fi
  else
    echo "⚠️ Hafıza okunamadı (Claude-Memory erişilemedi), devam ediyorum."
    echo "Erişim varsa BeyBaba/Claude-Memory içindeki lessons/INDEX.md'yi manuel oku."
  fi
} > "$OUT"

if command -v jq >/dev/null 2>&1; then
  jq -Rs '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:.}}' < "$OUT"
else
  python3 -c 'import json,sys;print(json.dumps({"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":sys.stdin.read()}}))' < "$OUT"
fi
