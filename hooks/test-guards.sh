#!/bin/bash
# Guard testleri: her kural icin eslesen (exit 2 beklenir) + eslesmeyen (exit 0) sahte JSON.
# JSON'u python ile guvenli kur (jq/tirnak tuzagi yok). python: /c/Python314/python -> python3 -> python (L-0063 stub).
# Hafiza v3 faz 2: L-0011 inbox istisnasi (sahte git repolari) + L-0093 UUID guard'i (content parametresi).
DIR="$(cd "$(dirname "$0")" && pwd)"
PY=""
for c in /c/Python314/python python3 python; do "$c" --version >/dev/null 2>&1 && { PY="$c"; break; }; done
[ -z "$PY" ] && { echo "python bulunamadi"; exit 1; }

pass=0; fail=0
mkbash() { "$PY" -c "import json,sys;print(json.dumps({'tool_name':sys.argv[1],'tool_input':{'command':sys.argv[2]}}))" "$1" "$2"; }
mkwrite() { # tool filepath [content]  -> Write icin content, Edit icin new_string
  "$PY" -c "
import json,sys
tool,fp=sys.argv[1],sys.argv[2]
ti={'file_path':fp}
if len(sys.argv)>3:
    ti['new_string' if tool=='Edit' else 'content']=sys.argv[3]
print(json.dumps({'tool_name':tool,'tool_input':ti}))" "$@"; }

runb() { # ad beklenen tool cmd
  local name="$1" exp="$2" tool="$3" cmd="$4" rc
  mkbash "$tool" "$cmd" | bash "$DIR/pre-bash-guard.sh" >/dev/null 2>&1; rc=$?
  if [ "$rc" = "$exp" ]; then echo "PASS  [$name] exit=$rc (beklenen $exp)"; pass=$((pass+1));
  else echo "FAIL  [$name] exit=$rc (beklenen $exp)"; fail=$((fail+1)); fi
}
runw() { # ad beklenen tool filepath [content]
  local name="$1" exp="$2" tool="$3" fp="$4" rc
  shift 4
  mkwrite "$tool" "$fp" "$@" | bash "$DIR/pre-write-guard.sh" >/dev/null 2>&1; rc=$?
  if [ "$rc" = "$exp" ]; then echo "PASS  [$name] exit=$rc (beklenen $exp)"; pass=$((pass+1));
  else echo "FAIL  [$name] exit=$rc (beklenen $exp)"; fail=$((fail+1)); fi
}
runb_in() { # ad beklenen cwd cmd  -> guard'i verilen klasorde (hook cwd) calistirir
  local name="$1" exp="$2" dir="$3" cmd="$4" rc
  (cd "$dir" && mkbash Bash "$cmd" | bash "$DIR/pre-bash-guard.sh" >/dev/null 2>&1); rc=$?
  if [ "$rc" = "$exp" ]; then echo "PASS  [$name] exit=$rc (beklenen $exp)"; pass=$((pass+1));
  else echo "FAIL  [$name] exit=$rc (beklenen $exp)"; fail=$((fail+1)); fi
}
# Sahte repo: $1 klasor, $2 origin/main sonrasi commit'lenecek dosya (relatif).
mkrepo() {
  local dir="$1" f="$2"
  mkdir -p "$dir"
  git -C "$dir" init -q
  printf 'seed\n' > "$dir/README.md"
  git -C "$dir" add README.md
  git -C "$dir" -c user.email=test@example.invalid -c user.name=test commit -q -m "init"
  git -C "$dir" update-ref refs/remotes/origin/main HEAD
  mkdir -p "$dir/$(dirname "$f")"
  printf 'x\n' > "$dir/$f"
  git -C "$dir" add "$f"
  git -C "$dir" -c user.email=test@example.invalid -c user.name=test commit -q -m "change"
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
echo "=== pre-bash-guard L-0011 inbox istisnasi (sahte git repolari) ==="
GDIR="$(mktemp -d 2>/dev/null || echo C:/Users/BSA/AppData/Local/Temp/gtest.$$)"
mkrepo "$GDIR/a/BigBrain"          "lessons/inbox/2026-09-22-x-slug.md"
mkrepo "$GDIR/b/BigBrain"          "lessons/INDEX.md"
mkrepo "$GDIR/c/arya-life-reborn"  "lessons/inbox/x.md"
runb_in "inbox-only-bigbrain PASS"     0 "$GDIR/a/BigBrain"         "git push origin main"
runb_in "index-change-bigbrain BLOCK"  2 "$GDIR/b/BigBrain"         "git push origin main"
runb_in "inbox-other-repo BLOCK"       2 "$GDIR/c/arya-life-reborn" "git push origin main"
rm -rf "$GDIR" 2>/dev/null

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
echo "=== pre-write-guard L-0093 UUID (backfill/script -> 2, migration -> 0) ==="
FAKE_UUID="00000000-0000-4000-8000-000000000001"
runw "uuid-backfill BLOCK"    2 Write "C:/proj/supabase/backfills/x.sql"        "update profiles set role='admin' where id='$FAKE_UUID';"
runw "uuid-migration PASS"    0 Write "C:/proj/supabase/migrations/0040_x.sql"  "insert into roles(id) values ('$FAKE_UUID');"

echo ""
echo "=== SONUC: PASS=$pass FAIL=$fail ==="
[ "$fail" = 0 ] && echo "TUM KURALLAR GECTI" || echo "BAZI KURALLAR GECMEDI"
exit 0
