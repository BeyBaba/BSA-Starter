#!/bin/bash
# bsa.sh — kisa komut sarmalayici.  bsa <install|sync|doctor|test> [parametreler]
# Kurulum yerleri: ~/.bsa/bsa.sh (bsa.cmd ile PowerShell/cmd'den "bsa doctor") ve ~/.claude/hooks/bsa.sh; repo: hooks/bsa.sh
#   install [--dry-run|--seed-memory|--no-doctor|--no-global] : repo kokundeki hooks/install.sh
#   sync    [install parametreleri]                            : BSA-Starter + BigBrain'de git pull origin main (yalniz main dalindaysa), sonra install
#   doctor  [--offline|--quick]                                : yanindaki bsa-doctor.sh, yoksa ~/.claude/hooks/bsa-doctor.sh
#   test                                                       : yanindaki test-guards.sh, yoksa ~/.claude/hooks/test-guards.sh
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

find_root() { # BSA-Starter repo koku
  if [ -n "${BSA_STARTER_DIR:-}" ] && [ -d "$BSA_STARTER_DIR" ]; then echo "$BSA_STARTER_DIR"; return; fi
  if [ -f "$DIR/../GLOBAL_CLAUDE_MD.md" ]; then cd "$DIR/.." && pwd; return; fi
  for c in "$HOME/Projects/BSA-Starter" /c/Users/BSA/Projects/BSA-Starter; do [ -d "$c" ] && { echo "$c"; return; }; done
}
find_bigbrain() {
  if [ -n "${BIGBRAIN_DIR:-}" ] && [ -d "$BIGBRAIN_DIR" ]; then echo "$BIGBRAIN_DIR"; return; fi
  for c in "$HOME/Projects/BigBrain" /c/Users/BSA/Projects/BigBrain; do [ -d "$c" ] && { echo "$c"; return; }; done
}
pull_main() { # pull_main <repo>: yalniz main dalindaysa git pull origin main
  local repo="$1" name br
  name="$(basename "$repo")"
  [ -d "$repo/.git" ] || { echo "[uyari] $name: git deposu degil, pull atlandi"; return; }
  br="$(git -C "$repo" branch --show-current 2>/dev/null)"
  if [ "$br" != "main" ]; then echo "[uyari] $name: dal '$br' (main degil), pull atlandi — kurulum mevcut calisma kopyasindan yapilir"; return; fi
  echo "[sync] $name: git pull origin main"
  git -C "$repo" pull --ff-only origin main || echo "[uyari] $name: pull basarisiz (ff-only); kurulum mevcut kopyadan devam ediyor"
}

case "${1:-}" in
  install)
    shift; ROOT="$(find_root)"
    [ -n "$ROOT" ] && [ -f "$ROOT/hooks/install.sh" ] || { echo "install.sh bulunamadi; BSA_STARTER_DIR ver ya da repo kokunden: bash hooks/install.sh" >&2; exit 1; }
    exec bash "$ROOT/hooks/install.sh" "$@" ;;
  sync)
    shift; ROOT="$(find_root)"; BB="$(find_bigbrain)"
    [ -n "$ROOT" ] && [ -f "$ROOT/hooks/install.sh" ] || { echo "BSA-Starter bulunamadi; BSA_STARTER_DIR ver" >&2; exit 1; }
    pull_main "$ROOT"
    [ -n "$BB" ] && pull_main "$BB" || echo "[uyari] BigBrain bulunamadi (BIGBRAIN_DIR ver), pull atlandi"
    exec bash "$ROOT/hooks/install.sh" "$@" ;;
  doctor)
    shift
    if [ -f "$DIR/bsa-doctor.sh" ]; then exec bash "$DIR/bsa-doctor.sh" "$@"; fi
    [ -f "$CLAUDE_HOME/hooks/bsa-doctor.sh" ] && exec bash "$CLAUDE_HOME/hooks/bsa-doctor.sh" "$@"
    echo "bsa-doctor.sh bulunamadi (bash hooks/install.sh)" >&2; exit 1 ;;
  test)
    shift
    if [ -f "$DIR/test-guards.sh" ]; then exec bash "$DIR/test-guards.sh" "$@"; fi
    [ -f "$CLAUDE_HOME/hooks/test-guards.sh" ] && exec bash "$CLAUDE_HOME/hooks/test-guards.sh" "$@"
    echo "test-guards.sh bulunamadi (bash hooks/install.sh)" >&2; exit 1 ;;
  *) echo "kullanim: bsa <install|sync|doctor|test> [--dry-run|--seed-memory|--no-doctor|--no-global|--offline|--quick]"; exit 1 ;;
esac
