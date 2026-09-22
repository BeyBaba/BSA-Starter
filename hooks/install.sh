#!/bin/bash
# install.sh — Hafiza v3 Faz 2 kurulumu: BSA-Starter'daki hook/agent/skill dosyalarini ~/.claude altina kopyalar
# ve settings.snippet.json'daki PreToolUse girdilerini ~/.claude/settings.json'a IDEMPOTENT olarak ekler.
#
# Kullanim (repo kokunden, Git Bash):  bash hooks/install.sh [--dry-run] [--seed-memory] [--no-doctor]
#   --dry-run      : hicbir dosya yazma, yapilacaklari listele
#   --seed-memory  : mevcut ~/.claude/agent-memory/bsa-denetci/MEMORY.md'yi (yedekleyip) seed ile EZ
#                    (varsayilan: mevcutsa dokunma — ajanin ogrendikleri kaybolmasin)
#   --no-doctor    : kurulum sonunda bsa-doctor.sh calistirma
# Ortam: CLAUDE_HOME (varsayilan $HOME/.claude). Kaynak tek yer BSA-Starter'dir (L-0096): lokal kopyaya elle ek yapma.
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
DRY=0; SEED=0; DOCTOR=1
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --seed-memory) SEED=1 ;;
    --no-doctor) DOCTOR=0 ;;
    -h|--help) sed -n 2,12p "$0"; exit 0 ;;
    *) echo "bilinmeyen parametre: $a" >&2; exit 1 ;;
  esac
done

pick_py() { for c in /c/Python314/python python3 python; do "$c" --version >/dev/null 2>&1 && { echo "$c"; return; }; done; }
PY="$(pick_py)"
[ -z "$PY" ] && { echo "HATA: python bulunamadi (settings.json birlestirme icin gerekli). L-0063" >&2; exit 1; }

say() { printf '%s\n' "$*"; }
act() { # act <aciklama> <komut...>
  local desc="$1"; shift
  if [ "$DRY" = 1 ]; then say "[dry-run] $desc"; else "$@" && say "[ok] $desc" || { say "[HATA] $desc" >&2; exit 1; }; fi
}
copy() { act "kopyala: $1 -> $2" cp "$1" "$2"; }
mkd()  { act "klasor: $1" mkdir -p "$1"; }

say "=== Hafiza v3 Faz 2 kurulum ==="
say "kaynak : $ROOT"
say "hedef  : $CLAUDE_HOME"
say "python : $PY"
[ "$DRY" = 1 ] && say "(dry-run: hicbir sey yazilmayacak)"

# 1) Hook betikleri + rules.txt + test
mkd "$CLAUDE_HOME/hooks"
for f in pre-bash-guard.sh pre-write-guard.sh rules.txt test-guards.sh bsa-doctor.sh bsa.sh; do
  [ -f "$DIR/$f" ] || { say "[HATA] eksik kaynak: hooks/$f" >&2; exit 1; }
  copy "$DIR/$f" "$CLAUDE_HOME/hooks/$f"
done

# 2) bsa-denetci ajani
mkd "$CLAUDE_HOME/agents"
copy "$ROOT/agents/bsa-denetci.md" "$CLAUDE_HOME/agents/bsa-denetci.md"

# 3) bsa-denetci kalici hafiza (seed)
MEM_DIR="$CLAUDE_HOME/agent-memory/bsa-denetci"
MEM="$MEM_DIR/MEMORY.md"
mkd "$MEM_DIR"
if [ -f "$MEM" ] && [ "$SEED" = 0 ]; then
  say "[atla] $MEM zaten var (ajan hafizasi korunuyor; seed ile ezmek icin --seed-memory)"
else
  if [ -f "$MEM" ]; then
    copy "$MEM" "$MEM.bak-$(date +%Y%m%d-%H%M%S)"
  fi
  copy "$ROOT/agents/bsa-denetci.MEMORY.seed.md" "$MEM"
fi

# 4) Skill'ler (skills/bsa-*/SKILL.md)
n=0
for s in "$ROOT"/skills/bsa-*/; do
  [ -d "$s" ] || continue
  s="${s%/}"; name="$(basename "$s")"
  [ -f "$s/SKILL.md" ] || { say "[uyari] $name: SKILL.md yok, atlandi"; continue; }
  mkd "$CLAUDE_HOME/skills/$name"
  copy "$s/SKILL.md" "$CLAUDE_HOME/skills/$name/SKILL.md"
  n=$((n+1))
done
say "skill sayisi: $n"

# 5) settings.json birlestirme (idempotent: ayni matcher+command varsa eklemez)
SETTINGS="$CLAUDE_HOME/settings.json"
SNIPPET="$DIR/settings.snippet.json"
# Windows Git Bash'te hook komutu icin C:/Users/... bicimi gerekir (Claude Code cmd ile calistirir).
if command -v cygpath >/dev/null 2>&1; then HOOKS_WIN="$(cygpath -m "$CLAUDE_HOME/hooks")"; else HOOKS_WIN="$CLAUDE_HOME/hooks"; fi
say "hook komut yolu: $HOOKS_WIN"
if [ "$DRY" = 1 ]; then
  say "[dry-run] settings.json birlestir: $SETTINGS  (snippet: $SNIPPET)"
else
  [ -f "$SETTINGS" ] && cp "$SETTINGS" "$SETTINGS.bak-$(date +%Y%m%d-%H%M%S)"
  "$PY" - "$SETTINGS" "$SNIPPET" "$HOOKS_WIN" <<'PYEOF'
import json, sys, os
settings_path, snippet_path, hooks_dir = sys.argv[1], sys.argv[2], sys.argv[3]
snippet = json.load(open(snippet_path, encoding="utf-8"))
settings = {}
if os.path.exists(settings_path):
    with open(settings_path, encoding="utf-8") as f:
        raw = f.read().strip()
    settings = json.loads(raw) if raw else {}
hooks = settings.setdefault("hooks", {})
added = 0
for event, entries in snippet.get("hooks", {}).items():
    lst = hooks.setdefault(event, [])
    for entry in entries:
        entry = json.loads(json.dumps(entry).replace("C:/Users/BSA/.claude/hooks", hooks_dir))
        matcher = entry.get("matcher")
        cmds = [h.get("command") for h in entry.get("hooks", [])]
        exists = any(e.get("matcher") == matcher and
                     [h.get("command") for h in e.get("hooks", [])] == cmds for e in lst)
        if not exists:
            lst.append(entry); added += 1
with open(settings_path, "w", encoding="utf-8") as f:
    json.dump(settings, f, ensure_ascii=False, indent=2); f.write("\n")
print(f"[ok] settings.json birlestirildi: {added} yeni PreToolUse girdisi ({settings_path})")
PYEOF
  [ $? -ne 0 ] && { say "[HATA] settings.json birlestirilemedi" >&2; exit 1; }
fi

say "=== kurulum bitti ==="
say "Onemli: Hook degisiklikleri MEVCUT Claude Code oturumunda etkinlesmez; yeni oturum ac (L-0049)."
if [ "$DOCTOR" = 1 ] && [ "$DRY" = 0 ]; then
  say ""; bash "$DIR/bsa-doctor.sh"
fi
