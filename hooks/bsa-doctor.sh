#!/bin/bash
# bsa-doctor.sh — Hafiza v3 kurulum ve on kosul dogrulama (L-0097: "kurulu" gorunmek != calisiyor).
# Kullanim: bash hooks/bsa-doctor.sh   (repo icinden: drift kontrolu de yapar; disaridan: yalniz kurulum kontrolu)
# Cikis: 0 = FAIL yok, 1 = en az bir FAIL. WARN cikis kodunu etkilemez.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
# Repo koku: bu betik BSA-Starter/hooks/ altindaysa oradan; ~/.claude/hooks'tan calisiyorsa BSA_STARTER_DIR ortam degiskeni ya da bilinen yollar
ROOT=""
if [ -f "$DIR/../GLOBAL_CLAUDE_MD.md" ]; then ROOT="$(cd "$DIR/.." && pwd)"
elif [ -n "${BSA_STARTER_DIR:-}" ] && [ -d "$BSA_STARTER_DIR" ]; then ROOT="$BSA_STARTER_DIR"
else for c in "$HOME/Projects/BSA-Starter" /c/Users/BSA/Projects/BSA-Starter; do [ -d "$c" ] && { ROOT="$c"; break; }; done; fi
BIGBRAIN="${BIGBRAIN_DIR:-}"
[ -z "$BIGBRAIN" ] && for c in "$HOME/Projects/BigBrain" /c/Users/BSA/Projects/BigBrain; do [ -d "$c" ] && { BIGBRAIN="$c"; break; }; done

pass=0; fail=0; warn=0
ok()   { echo "PASS  $*"; pass=$((pass+1)); }
bad()  { echo "FAIL  $*"; fail=$((fail+1)); }
wrn()  { echo "WARN  $*"; warn=$((warn+1)); }
same() { cmp -s "$1" "$2"; }

echo "=== bsa doctor ==="
echo "CLAUDE_HOME=$CLAUDE_HOME  repo=${ROOT:-<bulunamadi>}  BigBrain=${BIGBRAIN:-<bulunamadi>}"

echo "--- 1) on kosullar"
PY=""; for c in /c/Python314/python python3 python; do "$c" --version >/dev/null 2>&1 && { PY="$c"; break; }; done
[ -n "$PY" ] && ok "python: $PY ($("$PY" --version 2>&1))" || bad "python yok — hook JSON parse fail-open olur, guard'lar CALISMAZ (L-0063)"
if command -v jq >/dev/null 2>&1 && echo '""' | jq . >/dev/null 2>&1; then ok "jq: $(jq --version 2>&1)"; else wrn "jq yok (python fallback kullanilir; double-shot-latte plugin'i jq ister)"; fi
command -v git >/dev/null 2>&1 && ok "git: $(git --version 2>&1)" || bad "git yok"
command -v gh  >/dev/null 2>&1 && ok "gh: $(gh --version 2>&1 | head -1)" || wrn "gh CLI yok (PR/release adimlari elle)"
command -v node >/dev/null 2>&1 && ok "node: $(node --version 2>&1)" || wrn "node yok (stdio MCP'ler npx ister)"
command -v claude >/dev/null 2>&1 && ok "claude CLI: $(claude --version 2>&1 | head -1)" || wrn "claude CLI PATH'te yok"

echo "--- 2) hook dosyalari"
for f in pre-bash-guard.sh pre-write-guard.sh rules.txt test-guards.sh bsa-doctor.sh bsa.sh; do
  t="$CLAUDE_HOME/hooks/$f"
  if [ ! -f "$t" ]; then bad "eksik: $t (bash hooks/install.sh)"; continue; fi
  if [ -n "$ROOT" ] && [ -f "$ROOT/hooks/$f" ]; then
    same "$ROOT/hooks/$f" "$t" && ok "$f kurulu ve repo ile ayni" || bad "$f DRIFT: repo surumu farkli (bash hooks/install.sh) — L-0096"
  else ok "$f kurulu"; fi
done
[ -f "$CLAUDE_HOME/hooks/rules.txt" ] && ok "rules.txt kural sayisi: $(grep -cvE '^(#|$)' "$CLAUDE_HOME/hooks/rules.txt")"

echo "--- 3) settings.json (PreToolUse baglari)"
S="$CLAUDE_HOME/settings.json"
if [ ! -f "$S" ]; then bad "settings.json yok: $S"
elif [ -z "$PY" ]; then wrn "python yok, settings.json dogrulanamadi"
else
  "$PY" - "$S" "$CLAUDE_HOME/hooks" <<'PYEOF'
import json, sys, re, os
p, hooks_dir = sys.argv[1], sys.argv[2]
try:
    s = json.load(open(p, encoding="utf-8"))
except Exception as e:
    print(f"FAIL  settings.json gecersiz JSON: {e}"); sys.exit(2)
pre = s.get("hooks", {}).get("PreToolUse", [])
need = {"pre-bash-guard.sh": "Bash|PowerShell", "pre-write-guard.sh": "Write|Edit"}
rc = 0
for script, matcher in need.items():
    hits = [e for e in pre if any(script in (h.get("command") or "") for h in e.get("hooks", []))]
    if not hits:
        print(f"FAIL  PreToolUse'da {script} bagli degil (bash hooks/install.sh)"); rc = 2; continue
    e = hits[0]
    if e.get("matcher") != matcher:
        print(f"WARN  {script} matcher '{e.get('matcher')}' (beklenen '{matcher}')")
    cmd = next(h.get("command") for h in e["hooks"] if script in (h.get("command") or ""))
    m = re.search(r"bash\s+(.+?)\s*$", cmd)
    path = (m.group(1) if m else cmd).strip('"')
    # Git Bash: C:/x -> /c/x
    alt = re.sub(r"^([A-Za-z]):/", lambda mm: "/" + mm.group(1).lower() + "/", path)
    if os.path.exists(path) or os.path.exists(alt):
        print(f"PASS  PreToolUse {matcher} -> {cmd}")
    else:
        print(f"FAIL  hook komut yolu yok: {cmd}"); rc = 2
sys.exit(rc)
PYEOF
  rc=$?
  # python ciktisindaki PASS/FAIL satirlarini sayaca ekle
  if [ $rc -eq 0 ]; then pass=$((pass+2)); else fail=$((fail+1)); fi
fi

echo "--- 4) bsa-denetci ajani + hafiza"
A="$CLAUDE_HOME/agents/bsa-denetci.md"
if [ -f "$A" ]; then
  if [ -n "$ROOT" ] && [ -f "$ROOT/agents/bsa-denetci.md" ]; then same "$ROOT/agents/bsa-denetci.md" "$A" && ok "bsa-denetci.md kurulu ve repo ile ayni" || bad "bsa-denetci.md DRIFT (bash hooks/install.sh)"; else ok "bsa-denetci.md kurulu"; fi
else bad "eksik: $A"; fi
M="$CLAUDE_HOME/agent-memory/bsa-denetci/MEMORY.md"
if [ -f "$M" ]; then
  sz=$(wc -c < "$M"); [ "$sz" -le 25600 ] && ok "MEMORY.md var ($sz bayt; ilk 25 KB yuklenir)" || wrn "MEMORY.md $sz bayt > 25 KB: fazlasi yuklenmez, budama gerek"
else wrn "bsa-denetci MEMORY.md yok (ilk kosuda olusur; seed icin: bash hooks/install.sh --seed-memory)"; fi

echo "--- 5) skill'ler"
if [ -n "$ROOT" ] && ls -d "$ROOT"/skills/bsa-*/ >/dev/null 2>&1; then
  for s in "$ROOT"/skills/bsa-*/; do
    n="$(basename "$s")"; t="$CLAUDE_HOME/skills/$n/SKILL.md"
    if [ ! -f "$t" ]; then bad "skill eksik: $n (bash hooks/install.sh)"
    elif same "$s/SKILL.md" "$t"; then ok "skill $n kurulu ve repo ile ayni"
    else bad "skill $n DRIFT"; fi
  done
else
  c=$(ls -d "$CLAUDE_HOME"/skills/bsa-*/ 2>/dev/null | wc -l); [ "$c" -gt 0 ] && ok "kurulu bsa-* skill: $c" || bad "hic bsa-* skill kurulu degil"
fi
for req in frontend-design; do [ -d "$CLAUDE_HOME/skills/$req" ] && ok "harici skill: $req" || wrn "harici skill yok: $req (v2.22 zorunlu set)"; done

echo "--- 6) guard testleri (kurulu kopya uzerinde)"
if [ -f "$CLAUDE_HOME/hooks/test-guards.sh" ]; then
  out="$(bash "$CLAUDE_HOME/hooks/test-guards.sh" 2>&1)"
  line="$(printf '%s\n' "$out" | grep -E '^=== SONUC' | tail -1)"
  if printf '%s' "$line" | grep -q 'FAIL=0'; then ok "guard testleri: $line"; else bad "guard testleri: ${line:-calismadi}"; printf '%s\n' "$out" | grep '^FAIL' | head -5; fi
else bad "test-guards.sh kurulu degil"; fi

echo "--- 7) BigBrain hafiza"
if [ -n "$BIGBRAIN" ] && [ -f "$BIGBRAIN/lessons/INDEX.md" ]; then ok "BigBrain INDEX: $(grep -c '^## L-' "$BIGBRAIN/lessons/INDEX.md") ders ($BIGBRAIN)"
else wrn "BigBrain lessons/INDEX.md bulunamadi (BIGBRAIN_DIR ver) — hafiza okuma grep'i calismaz"; fi
[ -f "$CLAUDE_HOME/hooks/global-session-start.sh" ] && ok "global-session-start.sh var (proje SessionStart hook'u devre disi kalir, L-0062)" || wrn "global-session-start.sh yok: BigBrain SessionStart hook'u yalniz BigBrain klasorunden acilan oturumda calisir"

echo "--- 8) plugin / MCP (L-0097: listede olmak calisiyor demek degil)"
if command -v claude >/dev/null 2>&1; then
  pl="$(claude plugin list 2>/dev/null)"; ml="$(claude mcp list 2>/dev/null)"
  for p in superpowers episodic-memory double-shot-latte feature-dev code-review pr-review-toolkit security-guidance hookify claude-code-setup typescript-lsp; do
    printf '%s' "$pl" | grep -qi "$p" && ok "plugin: $p" || wrn "plugin eksik: $p"
  done
  for m in context7 memory sequential-thinking filesystem; do
    if printf '%s' "$ml" | grep -qi "$m"; then
      printf '%s' "$ml" | grep -i "$m" | grep -qiE 'fail|error|disconnect' && wrn "MCP $m listede ama baglanamiyor" || ok "MCP: $m"
    else wrn "MCP eksik: $m"; fi
  done
else wrn "claude CLI yok; plugin/MCP kontrolu atlandi"; fi

echo ""
echo "=== SONUC: PASS=$pass WARN=$warn FAIL=$fail ==="
[ "$fail" = 0 ] && { echo "KURULUM SAGLIKLI"; exit 0; } || { echo "EKSIK/HATALI KURULUM — yukaridaki FAIL satirlarini duzelt (cogu icin: bash hooks/install.sh)"; exit 1; }
