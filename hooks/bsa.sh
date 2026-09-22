#!/bin/bash
# bsa.sh — kisa komut sarmalayici.  bash hooks/bsa.sh <install|doctor|test> [parametreler]
# (~/.claude/hooks/bsa.sh olarak da kurulur: bash ~/.claude/hooks/bsa.sh doctor)
DIR="$(cd "$(dirname "$0")" && pwd)"
case "${1:-}" in
  install) shift; [ -f "$DIR/install.sh" ] || { echo "install.sh burada yok; repo kokunden calistir: bash hooks/install.sh"; exit 1; }; exec bash "$DIR/install.sh" "$@" ;;
  doctor)  shift; exec bash "$DIR/bsa-doctor.sh" "$@" ;;
  test)    shift; exec bash "$DIR/test-guards.sh" "$@" ;;
  *) echo "kullanim: bash $0 <install|doctor|test> [--dry-run|--seed-memory|--no-doctor]"; exit 1 ;;
esac
