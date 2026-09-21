#!/bin/bash
# PreToolUse guard — Write|Edit araclari. stdin: hook JSON (tool_input.file_path).
# Engel (exit 2): secret dosyalari (.env / credentials / *.pem / *.key) yazimi;
# supabase/migrations/ altinda MEVCUT numarali dosyayla NUMARA CAKISMASI (farkli ad, ayni NNNN onek).
# Parse hatasinda fail-open (exit 0). L-0014 (secret commit), migration numara cakismasi.
input="$(cat)"

pick_py() { for c in /c/Python314/python python3 python; do "$c" --version >/dev/null 2>&1 && { echo "$c"; return; }; done; }

fp=""
if command -v jq >/dev/null 2>&1; then
  fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
fi
if [ -z "$fp" ]; then
  PY="$(pick_py)"
  [ -n "$PY" ] && fp="$(printf '%s' "$input" | "$PY" -c "import sys,json;t=json.load(sys.stdin).get('tool_input',{});print(t.get('file_path') or t.get('path') or '')" 2>/dev/null)"
fi
[ -z "$fp" ] && exit 0

base="$(basename "$fp")"

# 1) Secret dosyalari
case "$base" in
  .env|.env.*|*.pem|*.key|credentials|credentials.*|*.credentials)
    echo "ENGELLENDI (L-0014): secret/kimlik dosyasi ($base) yazilamaz/commit edilemez. Dogru yol: degeri .secrets veya ortam degiskeninde tut, dosyayi .gitignore'a ekle." >&2
    exit 2 ;;
esac

# 2) Migration numara cakismasi
norm="$(printf '%s' "$fp" | tr '\\' '/')"
case "$norm" in
  */supabase/migrations/*)
    dir="$(dirname "$norm")"
    num="$(printf '%s' "$base" | grep -oE '^[0-9]{4}' || true)"
    if [ -n "$num" ] && [ -d "$dir" ]; then
      for existing in "$dir/${num}"_*; do
        [ -e "$existing" ] || continue
        if [ "$(basename "$existing")" != "$base" ]; then
          echo "ENGELLENDI (migration numara cakismasi): $num zaten $(basename "$existing") ile kullanilmis. Dogru yol: bir sonraki bos numarayi kullan (db push --include-all sira-disi uygular)." >&2
          exit 2
        fi
      done
    fi ;;
esac
exit 0
