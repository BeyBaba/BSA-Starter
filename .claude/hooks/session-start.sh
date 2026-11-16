#!/bin/bash
# SessionStart hook - BigBrain hafizasini context'e enjekte eder.
# Tasinabilirlik: jq -> python3 -> python -> node fallback zinciri.
# Hicbiri yoksa gorunur uyari basar (sessiz cokme YASAK - kontrol noktasi).
# v3.1: Dersler proje klasorunde degil BigBrain'de durur. Sirayla aranir:
#   proje (BigBrain'in kendisi) -> ../BigBrain -> ~/Projects/BigBrain -> ~/.cache/bigbrain
#   -> bulunamazsa sparse klon denenir (bulut oturumu). Yine yoksa "YUKLENEMEDI" uyarisi (asla sahte "yuklendi" yok).
set -uo pipefail

# Global hook varsa devre disi kal (L-0062 cift tetikleme korumasi)
[ -f "$HOME/.claude/hooks/global-session-start.sh" ] && exit 0

DIR="${CLAUDE_PROJECT_DIR:-.}"
REPO_URL="${BIGBRAIN_REPO_URL:-https://github.com/BeyBaba/BigBrain}"
CACHE="${BIGBRAIN_CACHE:-$HOME/.cache/bigbrain}"
OUT="$(mktemp)"
trap 'rm -f "$OUT" "$OUT.tmp"' EXIT

find_bigbrain() {
  local d
  for d in "$DIR" "$DIR/../BigBrain" "$DIR/../bigbrain" "$HOME/Projects/BigBrain" "$CACHE"; do
    if [ -f "$d/lessons/INDEX.md" ]; then echo "$d"; return 0; fi
  done
  return 1
}

BB="$(find_bigbrain)"
CLONE_NOTE=""
if [ -z "$BB" ] && command -v git >/dev/null 2>&1; then
  # Bulut oturumu: kucuk sparse klon (yalniz lessons + projects), 25 sn sinir; basarisizsa sessiz degil, asagida uyarir
  rm -rf "$CACHE.tmp"
  if timeout 25 git clone -q --depth 1 --filter=blob:none --sparse "$REPO_URL" "$CACHE.tmp" >/dev/null 2>&1 \
     && git -C "$CACHE.tmp" sparse-checkout set lessons projects >/dev/null 2>&1; then
    rm -rf "$CACHE" && mv "$CACHE.tmp" "$CACHE"
    BB="$CACHE"
    CLONE_NOTE=" (BigBrain bu oturum icin indirildi: $CACHE)"
  else
    rm -rf "$CACHE.tmp"
  fi
fi

{
  if [ -n "$BB" ]; then
    echo "BigBrain hafizasi yuklendi (SessionStart hook)$CLONE_NOTE."
    echo "Gecmis projelerden cikarilmis dersleri (L-XXXX) dikkate al, ayni hatayi tekrarlama."
    echo
    DERS_SAYISI=$(grep -c '^## L-' "$BB/lessons/INDEX.md" 2>/dev/null || echo 0)
    echo "=== DERSLER (Toplam: $DERS_SAYISI, son 12 gosteriliyor) ==="
    grep '^## L-' "$BB/lessons/INDEX.md" 2>/dev/null | tail -12 || true
    echo
    if [ -f "$BB/projects/INDEX.md" ]; then
      PROJE_SAYISI=$(grep -cE '^\| [^-]' "$BB/projects/INDEX.md" 2>/dev/null || echo 0)
      echo "=== PROJELER (Toplam: $PROJE_SAYISI) === Detay: $BB/projects/INDEX.md"
    fi
    echo "Gorev basinda ilgili dersleri ara: grep -i <konu> $BB/lessons/INDEX.md"
  else
    echo "UYARI: BigBrain hafizasi YUKLENEMEDI - dersler bu oturumda YOK (yerelde bulunamadi, indirilemedi)."
    echo "Bulut oturumundaysan: BeyBaba/BigBrain reposunu oturuma ekle (add_repo) ve lessons/INDEX.md'yi tara."
    echo "Ekleyemiyorsan ise baslamadan kullaniciya bildir (global kural v3.1 HAFIZA)."
  fi
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
