# hooks/ — Hafıza v3 deterministik guard'lar + kurulum

| Dosya | Görev |
|---|---|
| `pre-bash-guard.sh` | PreToolUse (Bash\|PowerShell): komutu `rules.txt`'e göre tarar; eşleşme → exit 2 (engel). Parse hatasında fail-open. |
| `pre-write-guard.sh` | PreToolUse (Write\|Edit): secret dosyaları (.env/*.pem/*.key/credentials) ve `supabase/migrations/` numara çakışması. |
| `rules.txt` | `REGEX<TAB>L-no<TAB>mesaj<TAB>[TOOL]` — 4. sütun BASH/POWERSHELL/ANY (boş=ANY). |
| `settings.snippet.json` | `~/.claude/settings.json`'a eklenen PreToolUse bağları (install.sh merge eder). |
| `test-guards.sh` | 30 test (MATCH → 2, NOMATCH → 0). Her kural değişikliğinde çalıştır. |
| `install.sh` | **Faz 2 kurulum:** hook'lar + `agents/bsa-denetci.md` + seed hafıza + `skills/bsa-*` → `~/.claude`; settings.json idempotent merge. |
| `bsa-doctor.sh` | **`bsa doctor`:** ön koşul + kurulum + drift + guard testi + plugin/MCP kontrolü (L-0097). FAIL varsa exit 1. |
| `bsa.sh` | Sarmalayıcı: `bash hooks/bsa.sh install|doctor|test`. |

## Kurulum (Windows, Git Bash; PowerShell'den `bash hooks/install.sh` yazılır)
```
cd C:\Users\BSA\Projects\BSA-Starter
bash hooks/install.sh --dry-run
bash hooks/install.sh --seed-memory
bash hooks/bsa-doctor.sh
```
- `--seed-memory` yalnız ilk kurulumda: Faz 1 testinde otomatik oluşan `agent-memory/bsa-denetci/MEMORY.md` seed ile ezilir (yedeği `.bak-<tarih>`). Sonraki kurulumlarda parametre verilmez; ajanın öğrendikleri korunur.
- Hook'lar açık oturumda etkinleşmez; kurulumdan sonra **yeni oturum** aç (L-0049).
- `install.sh` her dosyayı repo sürümüyle ezer: kaynak tek yer BSA-Starter'dır (L-0096). Lokal kopyaya elle kural ekleme; PR aç.

## Yeni kural ekleme
1. `rules.txt`'e satır ekle (regex `-` ile başlıyorsa guard `grep -e` kullanır, sorun yok).
2. `test-guards.sh`'e bir MATCH + bir NOMATCH satırı ekle.
3. `bash hooks/test-guards.sh` → `FAIL=0`.
4. PR aç; merge sonrası `bash hooks/install.sh` ile yerel kopyayı yenile; `bash hooks/bsa-doctor.sh` drift'i doğrular.

Stateful dersler (L-0044 checks spam, L-0061 fork `--repo`) tek-atış regex'le yakalanamaz → skill/bsa-denetci'de.
