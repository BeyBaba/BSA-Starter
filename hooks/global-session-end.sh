#!/bin/bash
# Global Stop hook - Gorev kapanisi (BigBrain global): bsa-denetci + ders adayi (inbox) kontrolu.
# BigBrain inbox yolu MUTLAK; dongu korumali (stop_hook_active true -> exit 0, cikti yok).
# install.sh bu dosyayi ~/.claude/hooks/global-session-end.sh olarak kopyalar.
set -euo pipefail

INPUT=$(cat)

# Dongu korumasi: bu durus zaten hook'un tetikledigi turdan geliyorsa izin ver
# Borusuz kontrol (L-0027: pipefail + pipe kalibi yok)
case "$INPUT" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

cat <<'EOF'
{"decision":"block","reason":"GOREV KAPANISI (BigBrain global): (1) bsa-denetci ajanini cagir, ciktisini rapora 'Denetim' bolumu olarak ekle. (2) Ders adayi varsa C:/Users/BSA/Projects/BigBrain/lessons/inbox/ altina YYYY-AA-GG-<proje>-<slug>.md yaz (bsa-denetci yazdiysa tekrar yazma). Format: ## Belirti / ## Kok Neden / ## Kural-Cozum / ## Goruldugu projeler. INDEX.md'ye DOKUNMA. (3) Ders yoksa tek satir 'Ders adayi yok' de ve bitir."}
EOF
