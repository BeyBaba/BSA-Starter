#!/bin/bash
# install.sh — Hafiza v3 kurulumu: BSA-Starter'daki hook/agent/skill/global-kural dosyalarini ~/.claude ve ~/.bsa altina
# kopyalar; settings.snippet.json'daki PreToolUse girdilerini ~/.claude/settings.json'a IDEMPOTENT olarak ekler.
#
# Kullanim (repo kokunden, Git Bash):  bash hooks/install.sh [--dry-run] [--seed-memory] [--no-doctor] [--no-global]
#   --dry-run      : hicbir dosya yazma, yapilacaklari listele
#   --seed-memory  : mevcut ~/.claude/agent-memory/bsa-denetci/MEMORY.md'yi (yedekleyip) seed ile EZ
#                    (varsayilan: mevcutsa dokunma — ajanin ogrendikleri kaybolmasin)
#   --no-doctor    : kurulum sonunda bsa-doctor.sh calistirma
#   --no-global    : ~/.claude/CLAUDE.md (lokal global kural kopyasi) guncelleme adimini atla
# Ortam: CLAUDE_HOME (varsayilan $HOME/.claude), BSA_HOME (varsayilan $HOME/.bsa).
# Kaynak tek yer BSA-Starter'dir (L-0096): lokal kopyaya elle ek yapma. Tum betikler LF'ye normalize kopyalanir (autocrlf tuzagi).
# Idempotent: icerik ayniysa dosya yazilmaz, yedek (.bak-<tarih>) yalniz icerik degisecekse alinir.
# Log: $BSA_HOME/logs/install-<yyyyMMdd-HHmmss>.log (dry-run'da log yazilmaz)
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
BSA_HOME="${BSA_HOME:-$HOME/.bsa}"
DRY=0; SEED=0; DOCTOR=1; GLOBAL=1
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --seed-memory) SEED=1 ;;
    --no-doctor) DOCTOR=0 ;;
    --no-global) GLOBAL=0 ;;
    -h|--help) sed -n 2,14p "$0"; exit 0 ;;
    *) echo "bilinmeyen parametre: $a" >&2; exit 1 ;;
  esac
done
TS="$(date +%Y%m%d-%H%M%S)"

pick_py() { for c in /c/Python314/python python3 python; do "$c" --version >/dev/null 2>&1 && { echo "$c"; return; }; done; }
PY="$(pick_py)"
[ -z "$PY" ] && { echo "HATA: python bulunamadi (settings.json birlestirme icin gerekli). L-0063" >&2; exit 1; }

say() { printf '%s\n' "$*"; }
act() { # act <aciklama> <komut...>
  local desc="$1"; shift
  if [ "$DRY" = 1 ]; then say "[dry-run] $desc"; else "$@" && say "[ok] $desc" || { say "[HATA] $desc" >&2; exit 1; }; fi
}
same_lf() { [ -f "$1" ] && [ -f "$2" ] && cmp -s <(tr -d '\r' < "$1") <(tr -d '\r' < "$2"); }
cp_lf_raw() { tr -d '\r' < "$1" > "$2" && case "$2" in *.sh) chmod +x "$2" ;; esac; }
copy_lf() { # copy_lf <kaynak> <hedef> [yedek-adi]: LF normalize; ayniysa atla; yedek-adi verildiyse ve hedef farkliysa once yedekle
  local src="$1" dst="$2" bak="${3:-}"
  if same_lf "$src" "$dst"; then say "[atla] $dst zaten guncel"; return 0; fi
  if [ -n "$bak" ] && [ -f "$dst" ]; then act "yedek: $dst -> $bak" cp "$dst" "$bak"; fi
  act "kopyala(LF): $src -> $dst" cp_lf_raw "$src" "$dst"
}
copy_raw() { # ikili/CRLF-serbest dosyalar (bsa.cmd)
  if [ -f "$2" ] && cmp -s "$1" "$2"; then say "[atla] $2 zaten guncel"; return 0; fi
  act "kopyala: $1 -> $2" cp "$1" "$2"
}
mkd() { [ -d "$1" ] && return 0; act "klasor: $1" mkdir -p "$1"; }

main() {
say "=== Hafiza v3 kurulum ($TS) ==="
say "kaynak : $ROOT"
say "hedef  : $CLAUDE_HOME  |  $BSA_HOME"
say "python : $PY"
[ "$DRY" = 1 ] && say "(dry-run: hicbir sey yazilmayacak)"

# 1) Hook betikleri + rules.txt + test (LF normalize)
say "--- 1) hook betikleri -> $CLAUDE_HOME/hooks"
mkd "$CLAUDE_HOME/hooks"
for f in pre-bash-guard.sh pre-write-guard.sh rules.txt test-guards.sh bsa-doctor.sh bsa.sh; do
  [ -f "$DIR/$f" ] || { say "[HATA] eksik kaynak: hooks/$f" >&2; exit 1; }
  copy_lf "$DIR/$f" "$CLAUDE_HOME/hooks/$f"
done

# 1b) global-session-start.sh / global-session-end.sh (repo'da varsa; farkliysa yedekle)
say "--- 1b) global session hook'lari"
for f in global-session-start.sh global-session-end.sh; do
  if [ -f "$DIR/$f" ]; then copy_lf "$DIR/$f" "$CLAUDE_HOME/hooks/$f" "$CLAUDE_HOME/hooks/$f.bak-$TS"
  else say "[atla] repo'da hooks/$f yok"; fi
done

# 1c) ~/.bsa: kisa komut (bsa.sh + bsa.cmd + bsa-doctor.sh)
say "--- 1c) kisa komut -> $BSA_HOME"
mkd "$BSA_HOME"
copy_lf "$DIR/bsa.sh" "$BSA_HOME/bsa.sh"
copy_lf "$DIR/bsa-doctor.sh" "$BSA_HOME/bsa-doctor.sh"
[ -f "$DIR/bsa.cmd" ] && copy_raw "$DIR/bsa.cmd" "$BSA_HOME/bsa.cmd" || say "[atla] repo'da hooks/bsa.cmd yok"

# 2) bsa-denetci ajani
say "--- 2) bsa-denetci ajani"
mkd "$CLAUDE_HOME/agents"
copy_lf "$ROOT/agents/bsa-denetci.md" "$CLAUDE_HOME/agents/bsa-denetci.md"

# 3) bsa-denetci kalici hafiza (seed)
say "--- 3) bsa-denetci hafizasi"
MEM_DIR="$CLAUDE_HOME/agent-memory/bsa-denetci"
MEM="$MEM_DIR/MEMORY.md"
mkd "$MEM_DIR"
if [ -f "$MEM" ] && [ "$SEED" = 0 ]; then
  say "[atla] $MEM zaten var (ajan hafizasi korunuyor; seed ile ezmek icin --seed-memory)"
else
  copy_lf "$ROOT/agents/bsa-denetci.MEMORY.seed.md" "$MEM" "$MEM.bak-$TS"
fi

# 4) Skill'ler (skills/bsa-*/SKILL.md)
say "--- 4) skill'ler"
n=0
for s in "$ROOT"/skills/bsa-*/; do
  [ -d "$s" ] || continue
  s="${s%/}"; name="$(basename "$s")"
  [ -f "$s/SKILL.md" ] || { say "[uyari] $name: SKILL.md yok, atlandi"; continue; }
  mkd "$CLAUDE_HOME/skills/$name"
  copy_lf "$s/SKILL.md" "$CLAUDE_HOME/skills/$name/SKILL.md"
  n=$((n+1))
done
say "skill sayisi: $n"

# 5) Lokal global kural kopyasi: ~/.claude/CLAUDE.md <- GLOBAL_CLAUDE_MD.md (\r kirpilmis karsilastirma)
say "--- 5) global kurallar -> $CLAUDE_HOME/CLAUDE.md"
if [ "$GLOBAL" = 0 ]; then say "[atla] --no-global"
elif [ ! -f "$ROOT/GLOBAL_CLAUDE_MD.md" ]; then say "[uyari] $ROOT/GLOBAL_CLAUDE_MD.md yok, atlandi"
else copy_lf "$ROOT/GLOBAL_CLAUDE_MD.md" "$CLAUDE_HOME/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md.bak-$TS"; fi

# 6) settings.json birlestirme (idempotent: ayni matcher+betik varsa eklemez; icerik degismeyecekse yazmaz, yedek almaz)
say "--- 6) settings.json"
SETTINGS="$CLAUDE_HOME/settings.json"
SNIPPET="$DIR/settings.snippet.json"
# Windows Git Bash'te hook komutu icin C:/Users/... bicimi gerekir (Claude Code cmd ile calistirir).
if command -v cygpath >/dev/null 2>&1; then HOOKS_WIN="$(cygpath -m "$CLAUDE_HOME/hooks")"; else HOOKS_WIN="$CLAUDE_HOME/hooks"; fi
say "hook komut yolu: $HOOKS_WIN"
if [ "$DRY" = 1 ]; then
  say "[dry-run] settings.json birlestir: $SETTINGS  (snippet: $SNIPPET; degisecekse yedek: $SETTINGS.bak-$TS)"
else
  "$PY" - "$SETTINGS" "$SNIPPET" "$HOOKS_WIN" "$SETTINGS.bak-$TS" <<'PYEOF'
import json, sys, os, shutil
settings_path, snippet_path, hooks_dir, bak_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
snippet = json.load(open(snippet_path, encoding="utf-8"))
settings = {}; raw = ""
if os.path.exists(settings_path):
    with open(settings_path, encoding="utf-8") as f:
        raw = f.read()
    settings = json.loads(raw) if raw.strip() else {}
hooks = settings.setdefault("hooks", {})
added = 0
for event, entries in snippet.get("hooks", {}).items():
    lst = hooks.setdefault(event, [])
    for entry in entries:
        entry = json.loads(json.dumps(entry).replace("C:/Users/BSA/.claude/hooks", hooks_dir))
        matcher = entry.get("matcher")
        # Idempotency anahtari yola DUYARSIZ olmali: ayni betik farkli yol gosterimiyle
        # (cygpath -m vs ham yol, CLAUDE_HOME override) iki kez kaydedilmesin (bsa-denetci ders adayi).
        def basenames(e):
            import os as _os
            out = []
            for h in e.get("hooks", []):
                cmd = h.get("command") or ""
                out.append(_os.path.basename(cmd.split()[-1]) if cmd.split() else cmd)
            return sorted(out)
        want = basenames(entry)
        exists = any(e.get("matcher") == matcher and basenames(e) == want for e in lst)
        if not exists:
            lst.append(entry); added += 1
new = json.dumps(settings, ensure_ascii=False, indent=2) + "\n"
if added == 0 and new == raw:
    print(f"[atla] settings.json zaten guncel: 0 yeni PreToolUse girdisi, yedek alinmadi ({settings_path})"); sys.exit(0)
if raw:
    shutil.copyfile(settings_path, bak_path); print(f"[ok] yedek: {bak_path}")
with open(settings_path, "w", encoding="utf-8") as f:
    f.write(new)
print(f"[ok] settings.json birlestirildi: {added} yeni PreToolUse girdisi ({settings_path})")
PYEOF
  [ $? -ne 0 ] && { say "[HATA] settings.json birlestirilemedi" >&2; exit 1; }
fi

say "=== kurulum bitti ==="
say "Onemli: Hook degisiklikleri MEVCUT Claude Code oturumunda etkinlesmez; yeni oturum ac (L-0049)."
if command -v cygpath >/dev/null 2>&1; then BSA_WIN="$(cygpath -w "$BSA_HOME")"; else BSA_WIN="$BSA_HOME"; fi
say "Kisa komut icin PATH'e ekle (betik PATH'i DEGISTIRMEZ): $BSA_WIN  -> sonra PowerShell/cmd'den: bsa doctor"
if [ "$DOCTOR" = 1 ] && [ "$DRY" = 0 ]; then
  say ""; bash "$DIR/bsa-doctor.sh"
fi
}

if [ "$DRY" = 1 ]; then
  main
else
  mkdir -p "$BSA_HOME/logs" || { echo "HATA: log klasoru olusturulamadi: $BSA_HOME/logs" >&2; exit 1; }
  LOG="$BSA_HOME/logs/install-$TS.log"
  main 2>&1 | tee "$LOG"
  rc=${PIPESTATUS[0]}
  say "log: $LOG"
  exit "$rc"
fi
