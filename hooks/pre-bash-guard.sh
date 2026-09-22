#!/bin/bash
# PreToolUse guard — Bash|PowerShell araclari. stdin: hook JSON.
# rules.txt satiri: REGEX<TAB>L-no<TAB>mesaj[<TAB>TOOL]   (TOOL ops: BASH|POWERSHELL|ANY; yoksa ANY)
# Eslesen kural -> exit 2 + stderr "ENGELLENDI (L-XXXX): <mesaj>. Dogru yol: <kisa>".
# jq -> python3 -> /c/Python314/python zinciri (L-0028/0063 stub, L-0064 /tmp). Parse hatasinda fail-open (exit 0).
# CR dayanikliligi: rules.txt CRLF olsa bile her satirin sonundaki \r atilir (aksi halde TOOL sutunu "ANY\r" olur, guard fail-open).
# L-0011 istisnasi: BigBrain reposunda origin/main..HEAD farki YALNIZ lessons/inbox/ dosyalariysa main'e push serbest.
DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
RULES="$DIR/rules.txt"
input="$(cat)"

pick_py() {
  for c in /c/Python314/python python3 python; do
    if "$c" --version >/dev/null 2>&1; then echo "$c"; return; fi
  done
}

extract() { # $1 = json path key (command|tool_name)
  local key="$1" out=""
  if command -v jq >/dev/null 2>&1; then
    if [ "$key" = "command" ]; then out="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
    else out="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"; fi
  fi
  if [ -z "$out" ]; then
    local PY; PY="$(pick_py)"
    if [ -n "$PY" ]; then
      if [ "$key" = "command" ]; then out="$(printf '%s' "$input" | "$PY" -c "import sys,json;print(json.load(sys.stdin).get('tool_input',{}).get('command','') or '')" 2>/dev/null)"
      else out="$(printf '%s' "$input" | "$PY" -c "import sys,json;print(json.load(sys.stdin).get('tool_name','') or '')" 2>/dev/null)"; fi
    fi
  fi
  printf '%s' "$out"
}

# L-0011 inbox istisnasi: cwd BigBrain reposu VE origin/main..HEAD farki bos degil VE her satir lessons/inbox/ ile basliyor -> 0.
# git hatasi (repo degil, origin/main yok vb.) -> istisna uygulanmaz (1).
inbox_exception() {
  local top base diff line
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  [ -n "$top" ] || return 1
  base="$(basename "$top")"
  [ "$base" = "BigBrain" ] || return 1
  diff="$(git diff --name-only origin/main..HEAD 2>/dev/null)" || return 1
  [ -n "$diff" ] || return 1
  while IFS= read -r line; do
    line="${line%$'\r'}"
    [ -z "$line" ] && continue
    case "$line" in
      lessons/inbox/*) ;;
      *) return 1 ;;
    esac
  done <<EOF
$diff
EOF
  return 0
}

cmd="$(extract command)"
tool="$(extract tool_name)"
cmd="${cmd%$'\r'}"; tool="${tool%$'\r'}"   # Windows python print \r\n basar
[ -z "$cmd" ] && exit 0
[ -f "$RULES" ] || exit 0

toolkey="ANY"
case "$tool" in
  *PowerShell*|*powershell*) toolkey="POWERSHELL" ;;
  *Bash*|*bash*) toolkey="BASH" ;;
esac

while IFS= read -r line || [ -n "$line" ]; do
  line="${line%$'\r'}"
  IFS=$'\t' read -r rx lno msg scope <<EOF
$line
EOF
  case "$rx" in ''|'#'*) continue ;; esac
  rx="${rx%$'\r'}"; lno="${lno%$'\r'}"; msg="${msg%$'\r'}"; scope="${scope%$'\r'}"
  [ -z "$scope" ] && scope="ANY"
  if [ "$scope" != "ANY" ] && [ "$scope" != "$toolkey" ]; then continue; fi
  if printf '%s' "$cmd" | grep -Eiq -e "$rx"; then
    if [ "$lno" = "L-0011" ]; then
      if inbox_exception; then
        exit 0
      fi
      echo "ENGELLENDI ($lno): $msg (Istisna: BigBrain'de yalniz lessons/inbox/ degisikligi main'e serbest)" >&2
      exit 2
    fi
    echo "ENGELLENDI ($lno): $msg" >&2
    exit 2
  fi
done < "$RULES"
exit 0
