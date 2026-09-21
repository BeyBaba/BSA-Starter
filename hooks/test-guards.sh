#!/bin/bash
# Guard testleri: her kural icin eslesen (exit 2 beklenir) + eslesmeyen (exit 0) sahte JSON.
# JSON'u python ile guvenli kur (jq/tirnak tuzagi yok). python: /c/Python314/python -> python3 -> python (L-0063 stub).
DIR="$(cd "$(dirname "$0")" && pwd)"
PY=""
for c in /c/Python314/python python3 python; do "$c" --version >/dev/null 2>&1 && { PY="$c"; break; }; done
[ -z "$PY" ] && { echo "python bulunamadi"; exit 1; }

pass=0; fail=0
mkbash() { "$PY" -c "import json,sys;print(json.dumps({'tool_name':sys.argv[1],'tool_input':{'command':sys.argv[2]}}))" "$1" "$2"; }
mkwrite() { "$PY" -c "import json,sys;print(json.dumps({'tool_name':sys.argv[1],'tool_input':{'file_path':sys.argv[2]}}))" "$1" "$2"; }

runb() { # ad beklenen tool cmd
  local name="$1" exp="$2" tool="$3" cmd="$4" rc
  mkbash "$tool" "$cmd" | bash "$DIR/pre-bash-guard.sh" >/dev/null 2>&1; rc=$?
  if [ "$rc" = "$exp" ]; then echo "PASS  [$name] exit=$rc (beklenen $exp)"; pass=$((pass+1));
  else echo "FAIL  [$name] exit=$rc (beklenen $exp)"; fail=$((fail+1)); fi
}
runw() { # ad beklenen tool filepath
  local name="$1" exp="$2" tool="$3" fp="$4" rc
  mkwrite "$tool" "$fp" | bash "$DIR/pre-write-guard.sh" >/dev/null 2>&1; rc=$?
  if [ "$rc" = "$exp" ]; then echo "PASS  [$name] exit=$rc (beklenen $exp)"; pass=$((pass+1));
  else echo "FAIL  [$name] exit=$rc (beklenen $exp)"; fail=$((fail+1)); fi
}

echo "=== pre-bash-guard (eslesen -> 2, eslesmeyen -> 0) ==="
runb "main-push MATCH"        2 Bash       "git push origin main"
runb "feature-push NOMATCH"   0 Bash       "git push origin feat/x"
runb "force-push MATCH"       2 Bash       "git push origin feat/x --force"
runb "reset-hard MATCH"       2 Bash       "git reset --hard origin/main"
runb "rm-rf MATCH"            2 Bash       "rm -rf build/"
runb "no-verify MATCH"        2 Bash       "git commit --no-verify -m x"
runb "drop-table MATCH"       2 Bash       "psql -c 'drop table users'"
runb "add-env MATCH"          2 Bash       "git add .env.local"
runb "add-normal NOMATCH"     0 Bash       "git add src/index.ts"
runb "add-worktrees MATCH"    2 Bash       "git add .claude/worktrees/x"
runb "add-swjs MATCH"         2 Bash       "git add public/sw.js"
runb "add-zip MATCH"          2 Bash       "git add archive.zip"
runb "service-role MATCH"     2 Bash       "echo NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=x"
runb "gh-repo-delete MATCH"   2 Bash       "gh repo delete foo/bar"
runb "gh-body MATCH"          2 Bash       "gh pr create --title x --body \"cok satir\""
runb "gh-bodyfile NOMATCH"    0 Bash       "gh pr create --title x --body-file /tmp/b.md"
runb "ps-amp MATCH(PS)"       2 PowerShell "cd x && npm run build"
runb "bash-amp NOMATCH(Bash)" 0 Bash       "cd x && npm run build"
runb "ps-cmdlet-in-bash MATCH" 2 Bash      "Get-Content foo.txt"
runb "ps-cmdlet-in-ps NOMATCH" 0 PowerShell "Get-Content foo.txt"
runb "addcontent-claude MATCH" 2 PowerShell "Add-Content -Path CLAUDE.md -Value x"
runb "stop-process-claude MATCH" 2 PowerShell "Stop-Process -Name claude"
runb "flutterfire MATCH"      2 Bash       "flutterfire configure"
runb "gh-pr-merge MATCH"      2 Bash       "gh pr merge 20 --squash"
runb "plain-ls NOMATCH"       0 Bash       "ls -la src"

echo ""
echo "=== pre-write-guard (secret/.env + migration cakismasi) ==="
runw "write-env MATCH"        2 Write      "C:/proj/.env.local"
runw "write-pem MATCH"        2 Write      "C:/proj/key.pem"
runw "write-normal NOMATCH"   0 Write      "C:/proj/src/app/page.tsx"

# Migration cakismasi testi (gecici klasor)
TDIR="$(mktemp -d 2>/dev/null || echo C:/Users/BSA/AppData/Local/Temp/mtest.$$)"
mkdir -p "$TDIR/supabase/migrations"
printf 'x' > "$TDIR/supabase/migrations/0035_existing.sql"
runw "migration-collision MATCH" 2 Write   "$TDIR/supabase/migrations/0035_new_name.sql"
runw "migration-fresh NOMATCH"   0 Write   "$TDIR/supabase/migrations/0036_new.sql"
rm -rf "$TDIR" 2>/dev/null

echo ""
echo "=== SONUC: PASS=$pass FAIL=$fail ==="
[ "$fail" = 0 ] && echo "TUM KURALLAR GECTI" || echo "BAZI KURALLAR GECMEDI"
exit 0
