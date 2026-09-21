#!/bin/bash
# PreToolUse guard — Bash|PowerShell araclari. stdin: hook JSON.
# rules.txt satiri: REGEX<TAB>L-no<TAB>mesaj[<TAB>TOOL]   (TOOL ops: BASH|POWERSHELL|ANY; yoksa ANY)
# Eslesen kural -> exit 2 + stderr "ENGELLENDI (L-XXXX): <mesaj>. Dogru yol: <kisa>".
# jq -> python3 -> /c/Python314/python zinciri (L-0028/0063 stub, L-0064 /tmp). Parse hatasinda fail-open (exit 0).
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

cmd="$(extract command)"
tool="$(extract tool_name)"
[ -z "$cmd" ] && exit 0
[ -f "$RULES" ] || exit 0

toolkey="ANY"
case "$tool" in
  *PowerShell*|*powershell*) toolkey="POWERSHELL" ;;
  *Bash*|*bash*) toolkey="BASH" ;;
esac

while IFS=$'\t' read -r rx lno msg scope; do
  case "$rx" in ''|'#'*) continue ;; esac
  [ -z "$scope" ] && scope="ANY"
  if [ "$scope" != "ANY" ] && [ "$scope" != "$toolkey" ]; then continue; fi
  if printf '%s' "$cmd" | grep -Eiq -e "$rx"; then
    echo "ENGELLENDI ($lno): $msg" >&2
    exit 2
  fi
done < "$RULES"
exit 0
