#!/bin/bash
# PreToolUse guard — Write|Edit|MultiEdit araclari. stdin: hook JSON (tool_input.file_path).
# Engel (exit 2): secret dosyalari (.env / credentials / *.pem / *.key) yazimi;
# supabase/migrations/ altinda MEVCUT numarali dosyayla NUMARA CAKISMASI (farkli ad, ayni NNNN onek);
# L-0093: supabase/backfills/ veya scripts/ altina gercek UUID literal'i yazimi (migration'da serbest).
# Parse hatasinda fail-open (exit 0). L-0014 (secret commit), migration numara cakismasi, L-0093 (UUID).
# CR dayanikliligi: file_path sonundaki \r atilir.
input="$(cat)"

pick_py() { for c in /c/Python314/python python3 python; do "$c" --version >/dev/null 2>&1 && { echo "$c"; return; }; done; }
PY="$(pick_py)"

fp=""
if command -v jq >/dev/null 2>&1; then
  fp="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
fi
if [ -z "$fp" ]; then
  [ -n "$PY" ] && fp="$(printf '%s' "$input" | "$PY" -c "import sys,json;t=json.load(sys.stdin).get('tool_input',{});print(t.get('file_path') or t.get('path') or '')" 2>/dev/null)"
fi
fp="$(printf '%s' "$fp" | tr -d '\r')"   # Windows python print \r\n basar; CRLF JSON'da da olabilir
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

# 3) L-0093: backfill/script icine gercek UUID yazma (migration altinda serbest)
uuid_scope=0
case "$norm" in
  */supabase/backfills/*|supabase/backfills/*|*/scripts/*|scripts/*) uuid_scope=1 ;;
esac
if [ "$uuid_scope" = 1 ]; then
  content=""
  if command -v jq >/dev/null 2>&1; then
    content="$(printf '%s' "$input" | jq -r '[.tool_input.content // empty, .tool_input.new_string // empty, (.tool_input.edits // [] | .[] | .new_string // empty)] | join("\n")' 2>/dev/null)"
  fi
  if [ -z "$content" ] && [ -n "$PY" ]; then
    content="$(printf '%s' "$input" | "$PY" -c "
import sys,json
t=json.load(sys.stdin).get('tool_input',{}) or {}
parts=[t.get('content') or '', t.get('new_string') or '']
for e in (t.get('edits') or []):
    if isinstance(e,dict): parts.append(e.get('new_string') or '')
sys.stdout.write('\n'.join(p for p in parts if p))
" 2>/dev/null)"
  fi
  if [ -n "$content" ] && printf '%s' "$content" | grep -Eq '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'; then
    echo "ENGELLENDI (L-0093): backfill/script içine gerçek UUID yazma. Doğru yol: '<admin-uuid>' placeholder + çalıştırmadan önce geçici koy, commit etme" >&2
    exit 2
  fi
fi
exit 0
