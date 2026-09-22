# --- BSA doctor (Hafiza v3) BEGIN — install.sh idempotent ekler
BSA_DOCTOR_LINE="${BSA_DOCTOR_LINE:-}"
if [ -f "$HOME/.claude/hooks/bsa-doctor.sh" ]; then
  BSA_DOCTOR_LINE="$(bash "$HOME/.claude/hooks/bsa-doctor.sh" --offline --quick 2>/dev/null | tail -n 1)"
fi
export BSA_DOCTOR_LINE
# --- BSA doctor END
