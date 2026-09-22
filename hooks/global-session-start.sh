#!/bin/bash
# global-session-start.sh — BigBrain lesson injection + BSA_SCOPE guard
# L-0026: headers only, cap 1800 chars (no cat of full file)
# L-0027: no pipefail+pipe+head; Python handles all I/O (avoids SIGPIPE)
# L-0062: global hook only, no local hook duplication
# 2026-09-22: proje-ozel dersler + son 8 + inbox sayaci; proje CLAUDE.md kopyasi kaldirildi (Claude Code zaten yukluyor).
# 2026-09-22 (Hafiza v3): surum ~/.claude/CLAUDE.md ilk satirindan dinamik okunur; bsa-doctor tek satir ozeti basliga eklenir.

# --- BSA doctor (Hafiza v3) BEGIN — install.sh idempotent ekler
BSA_DOCTOR_LINE="${BSA_DOCTOR_LINE:-}"
if [ -f "$HOME/.claude/hooks/bsa-doctor.sh" ]; then
  BSA_DOCTOR_LINE="$(bash "$HOME/.claude/hooks/bsa-doctor.sh" --offline --quick 2>/dev/null | tail -n 1)"
fi
export BSA_DOCTOR_LINE
# --- BSA doctor END

/c/Python314/python - << 'PYEOF'
import sys, os, json, unicodedata, glob, re

BIGBRAIN = "C:/Users/BSA/Projects/BigBrain"
lessons_path = os.path.join(BIGBRAIN, "lessons", "INDEX.md")
inbox_glob = os.path.join(BIGBRAIN, "lessons", "inbox", "*.md")
global_claude_md = "C:/Users/BSA/.claude/CLAUDE.md"

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
