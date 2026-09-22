#!/bin/bash
# bsa-doctor.sh — Hafiza v3 kurulum, on kosul ve DRIFT dogrulama (L-0097: "kurulu" gorunmek != calisiyor).
# Kullanim: bash hooks/bsa-doctor.sh [--offline] [--quick]
#   --offline : git fetch yapma (main == origin/main karsilastirmasi mevcut ref'lerle)
#   --quick   : bolum 6 (guard testleri) ve bolum 8 (claude plugin/mcp list) atlanir — SessionStart icin hizli mod
# Cikis: 0 = FAIL yok, 1 = en az bir FAIL. WARN ve DRIFT cikis kodunu etkilemez.
# Son satir TEK SATIR ozet: "vX.Y senkron" (FAIL yok + DRIFT bos) ya da "DRIFT: a,b,c".
# DRIFT anahtarlari: global-surum, global-icerik, denetci-memory, dosyalar, settings, <repo>-main
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
BSA_HOME="${BSA_HOME:-$HOME/.bsa}"
OFFLINE=0; QUICK=0
for a in "$@"; do
  case "$a" in
    --offline) OFFLINE=1 ;;
    --quick) QUICK=1 ;;
    -h|--help) sed -n 2,8p "$0"; exit 0 ;;
    *) echo "bilinmeyen parametre: $a" >&2; exit 1 ;;
  esac
done
# Repo koku: bu betik BSA-Starter/hooks/ altindaysa oradan; ~/.claude/hooks veya ~/.bsa'dan calisiyorsa BSA_STARTER_DIR ya da bilinen yollar
ROOT=""
if [ -f "$DIR/../GLOBAL_CLAUDE_MD.md" ]; then ROOT="$(cd "$DIR/.." && pwd)"
elif [ -n "${BSA_STARTER_DIR:-}" ] && [ -d "$BSA_STARTER_DIR" ]; then ROOT="$BSA_STARTER_DIR"
else for c in "$HOME/Projects/BSA-Starter" /c/Users/BSA/Projects/BSA-Starter; do [ -d "$c" ] && { ROOT="$c"; break; }; done; fi
BIGBRAIN="${BIGBRAIN_DIR:-}"
[ -z "$BIGBRAIN" ] && for c in "$HOME/Projects/BigBrain" /c/Users/BSA/Projects/BigBrain; do [ -d "$c" ] && { BIGBRAIN="$c"; break; }; done

pass=0; fail=0; warn=0; DRIFT=""
ok()   { echo "PASS  $*"; pass=$((pass+1)); }
bad()  { echo "FAIL  $*"; fail=$((fail+1)); }
wrn()  { echo "WARN  $*"; warn=$((warn+1)); }
drift(){ case ",$DRIFT," in *",$1,"*) ;; *) DRIFT="${DRIFT:+$DRIFT,}$1" ;; esac; }
same_lf() { cmp -s <(tr -d '\r' < "$1") <(tr -d '\r' < "$2"); }
ver_of() { head -1 "$1" 2>/dev/null | tr -d '\r' | grep -oE 'v[0-9]+\.[0-9]+' | head -1 | sed 's/^v//'; }
has_crlf() { ! cmp -s "$1" <(tr -d '\r' < "$1"); }
REPO_VER=""; [ -n "$ROOT" ] && REPO_VER="$(ver_of "$ROOT/GLOBAL_CLAUDE_MD.md")"

echo "=== bsa doctor ==="
echo "CLAUDE_HOME=$CLAUDE_HOME  repo=${ROOT:-<bulunamadi>}  BigBrain=${BIGBRAIN:-<bulunamadi>}  offline=$OFFLINE quick=$QUICK"

echo "--- 1) on kosullar"
PY=""; for c in /c/Python314/python python3 python; do "$c" --version >/dev/null 2>&1 && { PY="$c"; break; }; done
[ -n "$PY" ] && ok "python: $PY ($("$PY" --version 2>&1))" || bad "python yok — hook JSON parse fail-open olur, guard'lar CALISMAZ (L-0063)"
if command -v jq >/dev/null 2>&1 && echo '""' | jq . >/dev/null 2>&1; then ok "jq: $(jq --version 2>&1)"; else wrn "jq yok (python fallback kullanilir; double-shot-latte plugin'i jq ister)"; fi
command -v git >/dev/null 2>&1 && ok "git: $(git --version 2>&1)" || bad "git yok"
command -v gh  >/dev/null 2>&1 && ok "gh: $(gh --version 2>&1 | head -1)" || wrn "gh CLI yok (PR/release adimlari elle)"
command -v node >/dev/null 2>&1 && ok "node: $(node --version 2>&1)" || wrn "node yok (stdio MCP'ler npx ister)"
command -v claude >/dev/null 2>&1 && ok "claude CLI: $(claude --version 2>&1 | head -1)" || wrn "claude CLI PATH'te yok"

echo "--- 2) hook dosyalari (dosyalar)"
for f in pre-bash-guard.sh pre-write-guard.sh rules.txt test-guards.sh bsa-doctor.sh bsa.sh; do
  t="$CLAUDE_HOME/hooks/$f"
  if [ ! -f "$t" ]; then bad "eksik: $t (bash hooks/install.sh)"; drift dosyalar; continue; fi
  if [ -n "$ROOT" ] && [ -f "$ROOT/hooks/$f" ]; then
    same_lf "$ROOT/hooks/$f" "$t" && ok "$f kurulu ve repo ile ayni" || { bad "$f DRIFT: repo surumu farkli (bash hooks/install.sh) — L-0096"; drift dosyalar; }
  else ok "$f kurulu"; fi
done
if [ -f "$CLAUDE_HOME/hooks/rules.txt" ]; then
  ok "rules.txt kural sayisi: $(grep -cvE '^(#|$)' "$CLAUDE_HOME/hooks/rules.txt")"
  # Git Bash grep CR'i metin modunda bulamaz; LF'ye cevrilmis kopya ile cmp guvenilir
  has_crlf "$CLAUDE_HOME/hooks/rules.txt" && { bad "rules.txt CRLF: TOOL sutunu bozulur, guard fail-open (bash hooks/install.sh LF'ye cevirir)"; drift dosyalar; }
fi
for f in bsa.sh bsa.cmd bsa-doctor.sh; do
  [ -f "$BSA_HOME/$f" ] || wrn "$BSA_HOME/$f yok — 'bsa doctor' kisa komutu icin bash hooks/install.sh"
done

echo "--- 3) settings.json (PreToolUse baglari) (settings)"
S="$CLAUDE_HOME/settings.json"
if [ ! -f "$S" ]; then bad "settings.json yok: $S"; drift settings
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
        print(f"FAIL  {script} matcher '{e.get('matcher')}' (beklenen '{matcher}')"); rc = 2; continue
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
  if [ $rc -eq 0 ]; then pass=$((pass+2)); else fail=$((fail+1)); drift settings; fi
fi

echo "--- 4) bsa-denetci ajani + hafiza (dosyalar, denetci-memory)"
A="$CLAUDE_HOME/agents/bsa-denetci.md"
if [ -f "$A" ]; then
  if [ -n "$ROOT" ] && [ -f "$ROOT/agents/bsa-denetci.md" ]; then same_lf "$ROOT/agents/bsa-denetci.md" "$A" && ok "bsa-denetci.md kurulu ve repo ile ayni" || { bad "bsa-denetci.md DRIFT (bash hooks/install.sh)"; drift dosyalar; }; else ok "bsa-denetci.md kurulu"; fi
else bad "eksik: $A"; drift dosyalar; fi
M="$CLAUDE_HOME/agent-memory/bsa-denetci/MEMORY.md"
if [ -f "$M" ]; then
  sz=$(wc -c < "$M"); [ "$sz" -le 25600 ] && ok "MEMORY.md var ($sz bayt; ilk 25 KB yuklenir)" || wrn "MEMORY.md $sz bayt > 25 KB: fazlasi yuklenmez, budama gerek"
  # Son ders: once acik "Son ders: L-XXXX" satiri, yoksa dosyadaki en buyuk L-XXXX
  mem_last="$(grep -oiE '[Ss]on ders:? *L-[0-9]{4}' "$M" | head -1 | grep -oE '[0-9]{4}$')"
  [ -z "$mem_last" ] && mem_last="$(grep -oE 'L-[0-9]{4}' "$M" | sed 's/L-//' | sort -n | tail -1)"
  if [ -n "$BIGBRAIN" ] && [ -f "$BIGBRAIN/lessons/INDEX.md" ]; then
    idx_last="$(grep -oE '^## L-[0-9]{4}' "$BIGBRAIN/lessons/INDEX.md" | grep -oE '[0-9]{4}$' | sort -n | tail -1)"
    if [ -n "$mem_last" ] && [ "$mem_last" = "$idx_last" ]; then ok "denetci hafizasi son ders L-$mem_last == BigBrain INDEX L-$idx_last"
    else bad "denetci hafizasi son ders L-${mem_last:-?} != BigBrain INDEX L-${idx_last:-?} (seed guncelle: bash hooks/install.sh --seed-memory)"; drift denetci-memory; fi
  else wrn "BigBrain INDEX yok; denetci hafizasi son ders (L-${mem_last:-?}) karsilastirilamadi"; fi
else wrn "bsa-denetci MEMORY.md yok (ilk kosuda olusur; seed icin: bash hooks/install.sh --seed-memory)"; drift denetci-memory; fi

echo "--- 5) skill'ler (dosyalar)"
if [ -n "$ROOT" ] && ls -d "$ROOT"/skills/bsa-*/ >/dev/null 2>&1; then
  for s in "$ROOT"/skills/bsa-*/; do
    n="$(basename "$s")"; t="$CLAUDE_HOME/skills/$n/SKILL.md"
    if [ ! -f "$t" ]; then bad "skill eksik: $n (bash hooks/install.sh)"; drift dosyalar
    elif same_lf "$s/SKILL.md" "$t"; then ok "skill $n kurulu ve repo ile ayni"
    else bad "skill $n DRIFT"; drift dosyalar; fi
  done
else
  c=$(ls -d "$CLAUDE_HOME"/skills/bsa-*/ 2>/dev/null | wc -l); [ "$c" -gt 0 ] && ok "kurulu bsa-* skill: $c" || { bad "hic bsa-* skill kurulu degil"; drift dosyalar; }
fi
for req in frontend-design; do [ -d "$CLAUDE_HOME/skills/$req" ] && ok "harici skill: $req" || wrn "harici skill yok: $req (v2.22 zorunlu set)"; done

echo "--- 6) guard testleri (kurulu kopya uzerinde)"
if [ "$QUICK" = 1 ]; then echo "atla  --quick: guard testleri atlandi (tam kosu: bash hooks/bsa-doctor.sh)"
elif [ -f "$CLAUDE_HOME/hooks/test-guards.sh" ]; then
  out="$(bash "$CLAUDE_HOME/hooks/test-guards.sh" 2>&1)"
  line="$(printf '%s\n' "$out" | grep -E '^=== SONUC' | tail -1)"
  if printf '%s' "$line" | grep -q 'FAIL=0'; then ok "guard testleri: $line"; else bad "guard testleri: ${line:-calismadi}"; printf '%s\n' "$out" | grep '^FAIL' | head -5; fi
else bad "test-guards.sh kurulu degil"; drift dosyalar; fi

echo "--- 7) BigBrain hafiza + global kurallar (global-surum, global-icerik, <repo>-main)"
if [ -n "$BIGBRAIN" ] && [ -f "$BIGBRAIN/lessons/INDEX.md" ]; then ok "BigBrain INDEX: $(grep -c '^## L-' "$BIGBRAIN/lessons/INDEX.md") ders ($BIGBRAIN)"
else wrn "BigBrain lessons/INDEX.md bulunamadi (BIGBRAIN_DIR ver) — hafiza okuma grep'i calismaz"; fi
[ -f "$CLAUDE_HOME/hooks/global-session-start.sh" ] && ok "global-session-start.sh var (proje SessionStart hook'u devre disi kalir, L-0062)" || wrn "global-session-start.sh yok: BigBrain SessionStart hook'u yalniz BigBrain klasorunden acilan oturumda calisir"
[ -f "$CLAUDE_HOME/hooks/global-session-end.sh" ] && ok "global-session-end.sh var (Stop hook: ders kontrolu)" || wrn "global-session-end.sh yok: oturum sonu ders kontrolu calismaz"
# a) global surum: lokal ~/.claude/CLAUDE.md vs repo GLOBAL_CLAUDE_MD.md (WARN: global v3.0 PR'i merge edilene kadar drift beklenen durum)
G="$CLAUDE_HOME/CLAUDE.md"
if [ -z "$ROOT" ] || [ ! -f "$ROOT/GLOBAL_CLAUDE_MD.md" ]; then wrn "repo GLOBAL_CLAUDE_MD.md bulunamadi; global surum karsilastirilamadi"
elif [ ! -f "$G" ]; then wrn "lokal global kopya yok: $G (bash hooks/install.sh)"; drift global-surum
else
  LOC_VER="$(ver_of "$G")"
  if [ -n "$LOC_VER" ] && [ "$LOC_VER" = "$REPO_VER" ]; then ok "global surum: lokal v$LOC_VER == repo v$REPO_VER"
  else wrn "global surum DRIFT: lokal v${LOC_VER:-?} != repo v${REPO_VER:-?} (bash hooks/install.sh)"; drift global-surum; fi
  if same_lf "$G" "$ROOT/GLOBAL_CLAUDE_MD.md"; then ok "global icerik: lokal kopya repo ile ayni (satir sonu haric)"
  else wrn "global icerik DRIFT: lokal CLAUDE.md repo GLOBAL_CLAUDE_MD.md'den farkli (bash hooks/install.sh)"; drift global-icerik; fi
fi
# e) lokal main == origin/main (BSA-Starter, BigBrain)
for repo in "$ROOT" "$BIGBRAIN"; do
  [ -n "$repo" ] && [ -d "$repo/.git" ] || continue
  name="$(basename "$repo")"
  if [ "$OFFLINE" = 0 ]; then
    if command -v timeout >/dev/null 2>&1; then timeout 3 git -C "$repo" fetch -q origin main >/dev/null 2>&1 || wrn "$name: git fetch basarisiz/zaman asimi (3 sn); mevcut ref'ler kullanildi"
    else git -C "$repo" fetch -q origin main >/dev/null 2>&1 || wrn "$name: git fetch basarisiz; mevcut ref'ler kullanildi"; fi
  fi
  lm="$(git -C "$repo" rev-parse main 2>/dev/null)"; om="$(git -C "$repo" rev-parse origin/main 2>/dev/null)"
  if [ -z "$lm" ] || [ -z "$om" ]; then wrn "$name: main/origin/main ref'i okunamadi"
  elif [ "$lm" = "$om" ]; then ok "$name: lokal main == origin/main (${lm:0:7})"
  else wrn "$name: lokal main (${lm:0:7}) != origin/main (${om:0:7}) — bsa sync / git pull"; drift "$name-main"; fi
done

echo "--- 8) plugin / MCP (L-0097: listede olmak calisiyor demek degil)"
if [ "$QUICK" = 1 ]; then echo "atla  --quick: claude plugin/mcp list atlandi"
elif command -v claude >/dev/null 2>&1; then
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
[ "$fail" != 0 ] && echo "EKSIK/HATALI KURULUM — yukaridaki FAIL satirlarini duzelt (cogu icin: bash hooks/install.sh)"
echo "=== SONUC: PASS=$pass WARN=$warn FAIL=$fail ==="
if [ "$fail" = 0 ] && [ -z "$DRIFT" ]; then echo "v${REPO_VER:-?} senkron"; else echo "DRIFT: ${DRIFT:-yok}"; fi
[ "$fail" = 0 ] && exit 0 || exit 1
