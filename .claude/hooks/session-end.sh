#!/bin/bash
# Stop hook - Session sonunda ders cikarma kontrolu (yarim otomatik hafiza).
# Ilk duruşta Claude'a "ders var mi degerlendir" talimati verir (decision: block).
# Hook kaynakli ikinci durusta (stop_hook_active=true) serbest birakir - dongu olmaz.
set -euo pipefail

# Global hook varsa devre disi kal (L-0062 cift tetikleme korumasi)
[ -f "$HOME/.claude/hooks/global-session-end.sh" ] && exit 0

INPUT=$(cat)

# Dongu korumasi: bu durus zaten hook'un tetikledigi turdan geliyorsa izin ver
if echo "$INPUT" | grep -q '"stop_hook_active":[[:space:]]*true'; then
  exit 0
fi

cat <<'EOF'
{"decision":"block","reason":"DERS KONTROLU (BigBrain): Bu session'da tekrar edilebilir bir hata, kok neden veya genellestirilebilir bir karar cikti mi? (1) CIKTIYSA: lessons/inbox/ altina YYYY-AA-GG-kisa-slug.md dosyasi yaz. Format: '## Belirti' / '## Kok Neden' / '## Kural-Cozum' uc bolum, kisa ve net. INDEX.md'ye DOKUNMA - triyaj kullanici onayiyla yapilir. (2) CIKMADIYSA: hicbir dosya yazma, tek satir 'Ders adayi yok' de ve bitir."}
EOF
