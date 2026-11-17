#!/bin/bash
# pre-compact.sh — CONTEXT-DRIFT (GLOBAL v3.2) denetimi. PreCompact olayinda calisir (install.sh settings.json'a kaydeder).
# Kural: uzun oturumda asistan otomatik sikistirmadan ONCE kayipsiz devir notu uretip yeni oturum onermeli.
# trigger=auto  -> sikistirma asistan devir notu uretmeden geldi: "CONTEXT-DRIFT IHLALI" satiri loglanir.
# trigger=manual -> kullanici /compact dedi: bilgi satiri loglanir (ihlal sayilmaz).
# Log: $BSA_REPORTS_DIR (varsayilan: %USERPROFILE%/_reports/bigbrain) /context-drift-log.md — klasor yoksa olusturulur.
# Makine-bagimsiz (v3.2): sabit kullanici yolu yok. ASLA bloklamaz (her durumda exit 0); hata stderr'e.
input="$(cat 2>/dev/null)"

trigger="manual"
case "$input" in
  *'"trigger":"auto"'*|*'"trigger": "auto"'*) trigger="auto" ;;
esac
sid="$(printf '%s' "$input" | tr -d '\r\n' | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"

up="${USERPROFILE:-}"
if [ -n "$up" ] && command -v cygpath >/dev/null 2>&1; then up="$(cygpath -u "$up")"; fi
[ -n "$up" ] || up="$HOME"
dir="${BSA_REPORTS_DIR:-$up/_reports/bigbrain}"
if ! mkdir -p "$dir" 2>/dev/null; then echo "pre-compact: log klasoru olusturulamadi: $dir" >&2; exit 0; fi
log="$dir/context-drift-log.md"
[ -f "$log" ] || printf '%s\n\n' "# CONTEXT-DRIFT log (GLOBAL v3.2) — PreCompact hook" > "$log" 2>/dev/null

ts="$(date '+%Y-%m-%d %H:%M:%S %z')"
proj="$(basename "${CLAUDE_PROJECT_DIR:-$PWD}")"
if [ "$trigger" = "auto" ]; then
  line="- $ts | CONTEXT-DRIFT IHLALI — devir notu uretilmeden otomatik sikistirma | proje=$proj | session=${sid:-?}"
else
  line="- $ts | bilgi: elle /compact (trigger=manual); devir notu uretildi mi kontrol et | proje=$proj | session=${sid:-?}"
fi
printf '%s\n' "$line" >> "$log" 2>/dev/null || echo "pre-compact: log yazilamadi: $log" >&2
exit 0
