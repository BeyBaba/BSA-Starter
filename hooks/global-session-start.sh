#!/bin/bash
# global-session-start.sh — BigBrain lesson injection + BSA_SCOPE guard
# L-0026: headers only, cap 1800 chars (no cat of full file)
# L-0027: no pipefail+pipe+head; Python handles all I/O (avoids SIGPIPE)
# L-0062: global hook only, no local hook duplication
# 2026-09-22: proje-ozel dersler + son 8 + inbox sayaci; proje CLAUDE.md kopyasi kaldirildi (Claude Code zaten yukluyor).
# 2026-09-22 (Hafiza v3): surum ~/.claude/CLAUDE.md ilk satirindan dinamik okunur; bsa-doctor tek satir ozeti basliga eklenir.

# 2026-11-17 (v3.2 makine bagimsiz): sabit C:/Users/BSA yollari kaldirildi. BigBrain sablon hook'la ayni sirayla aranir:
#   $BIGBRAIN_DIR -> proje klasoru (BigBrain'in kendisi) -> ../BigBrain -> $HOME/Projects/BigBrain -> %USERPROFILE%/Projects/BigBrain
#   -> ~/.cache/bigbrain (sablon hook'un bulut klonu). Bulunamazsa gorunur "YUKLENEMEDI" (asla sahte "yuklendi" yok).
#   Global kural kopyasi: ${CLAUDE_HOME:-$HOME/.claude}/CLAUDE.md
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

# --- BSA doctor (Hafiza v3) BEGIN — install.sh tam dosyayi kopyalar; elle ekleme icin blok global-session-start.snippet.sh
BSA_DOCTOR_LINE="${BSA_DOCTOR_LINE:-}"
if [ -f "$CLAUDE_HOME/hooks/bsa-doctor.sh" ]; then
  BSA_DOCTOR_LINE="$(bash "$CLAUDE_HOME/hooks/bsa-doctor.sh" --offline --quick 2>/dev/null | tail -n 1)"
fi
export BSA_DOCTOR_LINE
# --- BSA doctor END

# Windows-native python MSYS yolunu (/c/...) acamaz -> C:/... bicimine cevir
to_native() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }
find_bigbrain() {
  local d proj up=""
  proj="${CLAUDE_PROJECT_DIR:-$PWD}"
  [ -n "${USERPROFILE:-}" ] && command -v cygpath >/dev/null 2>&1 && up="$(cygpath -u "$USERPROFILE")"
  for d in "${BIGBRAIN_DIR:-}" "$proj" "$proj/../BigBrain" "$proj/../bigbrain" "$HOME/Projects/BigBrain" ${up:+"$up/Projects/BigBrain"} "${BIGBRAIN_CACHE:-$HOME/.cache/bigbrain}"; do
    [ -n "$d" ] && [ -f "$d/lessons/INDEX.md" ] && { (cd "$d" && pwd); return 0; }
  done
  return 1
}
BB="$(find_bigbrain)"
BSA_BIGBRAIN=""; [ -n "$BB" ] && BSA_BIGBRAIN="$(to_native "$BB")"
BSA_GLOBAL_MD="$(to_native "$CLAUDE_HOME/CLAUDE.md")"
export BSA_BIGBRAIN BSA_GLOBAL_MD

# Python aday zinciri (v3.2 makine bagimsiz, L-0063): eskiden /c/Python314/python yedeksizdi -> baska makinede hook kiriliyordu
pick_py() {
  local la c IFS=$'\n'
  la="${LOCALAPPDATA:-}"; [ -n "$la" ] && command -v cygpath >/dev/null 2>&1 && la="$(cygpath -u "$la")"; [ -n "$la" ] || la="$HOME/AppData/Local"
  for c in $(type -ap python3 python 2>/dev/null) "$la"/Programs/Python/Python3*/python.exe /c/Python3*/python.exe; do
    case "$c" in ""|*'*'*|*WindowsApps*) continue ;; esac
    "$c" --version >/dev/null 2>&1 && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}
PY="$(pick_py)"
if [ -z "$PY" ]; then
  # Sessiz cokme YASAK (v3.1): gorunur uyari
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"UYARI: BigBrain hafizasi YUKLENEMEDI - gercek python bulunamadi (pick_py: PATH python3/python, LOCALAPPDATA Programs, /c/Python3*). Kullaniciya bildir."}}'
  exit 0
fi

"$PY" - << 'PYEOF'
import sys, os, json, unicodedata, glob, re

BIGBRAIN = os.environ.get("BSA_BIGBRAIN", "")   # bash find_bigbrain sonucu (bos = bulunamadi)
lessons_path = os.path.join(BIGBRAIN, "lessons", "INDEX.md")
inbox_glob = os.path.join(BIGBRAIN, "lessons", "inbox", "*.md")
global_claude_md = os.environ.get("BSA_GLOBAL_MD") or os.path.join(os.path.expanduser("~"), ".claude", "CLAUDE.md")

proj = os.path.basename((os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()).rstrip("/\\"))

def norm_key(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode("ascii").lower()
    return "".join(ch for ch in s if ch.isalnum())

def ascii_line(s):
    return unicodedata.normalize("NFKD", s.rstrip()).encode("ascii", "ignore").decode("ascii").strip()

def global_version():
    # ~/.claude/CLAUDE.md ilk satiri: "GLOBAL CLAUDE.MD KURALLARI — v2.23" -> "2.23"; bulunamazsa "?"
    try:
        with open(global_claude_md, encoding="utf-8", errors="ignore") as f:
            first = f.readline()
        m = re.search(r"v(\d+\.\d+)", first)
        if m:
            return m.group(1)
    except Exception:
        pass
    return "?"

cwd_claude = os.path.join(os.getcwd(), "CLAUDE.md")
bsa_scope_false = False
if os.path.exists(cwd_claude):
    try:
        with open(cwd_claude, encoding="utf-8", errors="ignore") as f:
            if "BSA_SCOPE = false" in f.read():
                bsa_scope_false = True
    except Exception:
        pass

if bsa_scope_false:
    context = "[WARNING] BSA_SCOPE=false: lesson list skipped for this project."
elif not BIGBRAIN or not os.path.isfile(lessons_path):
    # Sessiz bos liste YASAK (v3.1/v3.2): eskiden sabit yol bulunamayinca "yok" diye sahte-temiz gorunuyordu
    context = ("Global CLAUDE.md v%s active. UYARI: BigBrain hafizasi YUKLENEMEDI - lessons/INDEX.md bulunamadi "
               "(arandi: BIGBRAIN_DIR, proje, ../BigBrain, ~/Projects/BigBrain, %%USERPROFILE%%/Projects/BigBrain, ~/.cache/bigbrain). "
               "Kullaniciya bildir; BIGBRAIN_DIR ayarla veya BigBrain'i ~/Projects altina klonla." % global_version())
else:
    headers = []        # tum ## L- basliklari (ascii)
    proj_headers = []   # blogu bu projeyi anan dersler
    projkey = norm_key(proj)
    cur = None
    cur_hit = False
    try:
        with open(lessons_path, encoding="utf-8", errors="ignore") as f:
            for line in f:
                if line.startswith("## L-"):
                    if cur and cur_hit:
                        proj_headers.append(cur)
                    cur = ascii_line(line)
                    if cur:
                        headers.append(cur)
                    cur_hit = False
                else:
                    nk = norm_key(line)
                    if projkey and "gorulduguprojeler" in nk and projkey in nk:
                        cur_hit = True
            if cur and cur_hit:
                proj_headers.append(cur)
    except Exception:
        pass

    try:
        inbox = [os.path.basename(p) for p in sorted(glob.glob(inbox_glob))]
        inbox = [n for n in inbox if n.lower() != "readme.md"]
    except Exception:
        inbox = []

    # INBOX blogu her zaman TAM gorunur; proje/son listeleri kalan butceye gore kirpilir.
    n = len(inbox)
    warn = "UYARI: " if n > 10 else ""
    inbox_part = "=== INBOX ===\n%s%d aday triyaj bekliyor" % (warn, n)
    if inbox:
        inbox_part += "\n" + "\n".join(inbox[-6:])

    head = "Global CLAUDE.md v%s active" % global_version()
    doctor = ascii_line(os.environ.get("BSA_DOCTOR_LINE", "") or "")
    if doctor:
        head += " | doctor: " + doctor
    head += ". BigBrain memory:"
    budget = 1800 - len(inbox_part) - len(head) - 8   # 8: ayirac newline'lar

    def fit(title, items, empty="yok"):
        block = title + "\n" + ("\n".join(items) if items else empty)
        return block

    # proje-ozel (en guncel) ve son dersler (son 8) — birlikte butceye sigdir
    son = headers[-8:]
    proj_show = proj_headers[-10:]
    while True:
        proj_block = fit("=== BU PROJEYE OZEL DERSLER (%s) ===" % proj, proj_show)
        if proj_headers and len(proj_show) < len(proj_headers):
            proj_block += "\n(+%d daha, lessons/INDEX.md)" % (len(proj_headers) - len(proj_show))
        son_block = fit("=== SON DERSLER (son 8) ===", son)
        if len(proj_block) + len(son_block) + 1 <= budget:
            break
        if len(proj_show) > 3:
            proj_show = proj_show[1:]
        elif len(son) > 3:
            son = son[1:]
        else:
            break

    context = "\n".join([head, proj_block, son_block, inbox_part])
    if len(context) > 1800:
        context = context[:1797] + "..."

out = {"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": context}}
sys.stdout.write(json.dumps(out, ensure_ascii=True) + "\n")
PYEOF
