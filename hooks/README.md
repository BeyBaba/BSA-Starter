# hooks/ — Hafıza v3 deterministik guard'lar + kurulum + doctor

| Dosya | Görev |
|---|---|
| `pre-bash-guard.sh` | PreToolUse (Bash\|PowerShell): komutu `rules.txt`'e göre tarar; eşleşme → exit 2 (engel). Parse hatasında fail-open. |
| `pre-write-guard.sh` | PreToolUse (Write\|Edit): secret dosyaları (.env/*.pem/*.key/credentials) ve `supabase/migrations/` numara çakışması. |
| `rules.txt` | `REGEX<TAB>L-no<TAB>mesaj<TAB>[TOOL]` — 4. sütun BASH/POWERSHELL/ANY (boş=ANY). |
| `settings.snippet.json` | `~/.claude/settings.json`'a eklenen PreToolUse bağları (install.sh merge eder). |
| `test-guards.sh` | Guard testleri (MATCH → 2, NOMATCH → 0). Her kural değişikliğinde çalıştır. |
| `global-session-start.sh` / `global-session-end.sh` | Global SessionStart / Stop hook'ları (BigBrain ders enjeksiyonu, oturum sonu ders kontrolü). install.sh lokal kopyayı farklıysa yedekleyip günceller. |
| `install.sh` | Kurulum: hook'lar + global session hook'ları + `agents/bsa-denetci.md` + seed hafıza + `skills/bsa-*` + `GLOBAL_CLAUDE_MD.md` → `~/.claude`; `bsa.sh`/`bsa.cmd`/`bsa-doctor.sh` → `~/.bsa`; settings.json idempotent merge. Log: `~/.bsa/logs/install-<tarih>.log`. |
| `bsa-doctor.sh` | `bsa doctor`: ön koşul + kurulum + drift + guard testi + plugin/MCP (L-0097). Son satır tek satır özet. |
| `bsa.sh` / `bsa.cmd` | Kısa komut: `bsa install|sync|doctor|test`. `bsa.cmd` PowerShell/cmd'den `bsa doctor` yazılmasını sağlar (`~/.bsa` PATH'e eklenince). |

## Kurulum (Windows, Git Bash; PowerShell'den `bash hooks/install.sh` yazılır)
```
cd C:\Users\BSA\Projects\BSA-Starter
bash hooks/install.sh --dry-run
bash hooks/install.sh --seed-memory
bash hooks/bsa-doctor.sh
```
Sonra (bir kez, elle): PATH'e `C:\Users\BSA\.bsa` ekle → PowerShell/cmd'den `bsa doctor`, `bsa sync`.

install.sh bayrakları: `--dry-run` (yazma, listele) · `--seed-memory` (MEMORY.md'yi yedekleyip seed ile ez; yalnız ilk kurulum / seed güncellemesi) · `--no-doctor` · `--no-global` (`~/.claude/CLAUDE.md` adımını atla).
Ortam: `CLAUDE_HOME` (vars. `~/.claude`), `BSA_HOME` (vars. `~/.bsa`).

- Idempotent: içerik aynıysa `[atla] ... zaten guncel`; yedek (`*.bak-<tarih>`) yalnız içerik değişecekse alınır (settings.json, global-session-*.sh, CLAUDE.md, MEMORY.md).
- Tüm betik/kural dosyaları LF'ye normalize kopyalanır (CRLF → rules.txt TOOL sütunu bozulur, guard fail-open; autocrlf tuzağı).
- Hook'lar açık oturumda etkinleşmez; kurulumdan sonra **yeni oturum** aç (L-0049).
- Kaynak tek yer BSA-Starter'dır (L-0096). Lokal kopyaya elle kural ekleme; PR aç.

## bsa komutu
- `bsa sync [install bayrakları]` — BSA-Starter ve BigBrain'de `git pull origin main` (yalnız main dalındaysa; değilse uyarır, o repoda pull atlar), sonra `install.sh`.
- `bsa doctor [--offline] [--quick]` — yanındaki `bsa-doctor.sh`, yoksa `~/.claude/hooks/bsa-doctor.sh`.
- `bsa install`, `bsa test`.
- `~/.bsa` dışından da çalışır; repo kökünü `BSA_STARTER_DIR` ya da bilinen yollardan bulur.

## bsa doctor
Bölümler: 1 ön koşul · 2 hook dosyaları · 3 settings.json · 4 ajan + hafıza · 5 skill'ler · 6 guard testleri · 7 BigBrain + global kurallar · 8 plugin/MCP.

Drift kontrolleri (DRIFT anahtarı):
| Kontrol | Sonuç | Anahtar |
|---|---|---|
| `~/.claude/CLAUDE.md` sürümü (`vX.Y`, ilk satır) == repo `GLOBAL_CLAUDE_MD.md` | WARN | `global-surum` |
| aynı dosyaların içeriği (satır sonu hariç) | WARN | `global-icerik` |
| bsa-denetci MEMORY.md "Son ders: L-XXXX" (yoksa en büyük L-XXXX) == BigBrain INDEX son `## L-XXXX` | FAIL | `denetci-memory` |
| 9 skill, hook dosyaları (LF), `agents/bsa-denetci.md` yerinde ve repo ile aynı | FAIL | `dosyalar` |
| settings.json'da `Bash\|PowerShell` ve `Write\|Edit` PreToolUse bağları, komut yolu var | FAIL | `settings` |
| BSA-Starter / BigBrain: lokal `main` == `origin/main` (fetch 3 sn zaman aşımı) | WARN | `<repo>-main` |

Bayraklar: `--offline` (git fetch yok, mevcut ref'ler) · `--quick` (bölüm 6 guard testleri ve bölüm 8 `claude plugin/mcp list` atlanır — SessionStart için).

Çıktı sonu:
```
=== SONUC: PASS=n WARN=n FAIL=n ===
v2.23 senkron          <- FAIL yok ve DRIFT boş (sürüm = repo GLOBAL_CLAUDE_MD.md)
DRIFT: denetci-memory,BigBrain-main   <- aksi halde (WARN kaynaklı drift'ler de listede)
```
Exit: FAIL varsa 1, yoksa 0 — WARN ve DRIFT exit kodunu etkilemez. Global sürüm farkı WARN'dır (global v3.0 PR'ı merge edilene kadar beklenen drift).

## Yeni kural ekleme
1. `rules.txt`'e satır ekle (regex `-` ile başlıyorsa guard `grep -e` kullanır, sorun yok).
2. `test-guards.sh`'e bir MATCH + bir NOMATCH satırı ekle.
3. `bash hooks/test-guards.sh` → `FAIL=0`.
4. PR aç; merge sonrası `bsa sync` (ya da `bash hooks/install.sh`) ile yerel kopyayı yenile; `bsa doctor` drift'i doğrular.

Stateful dersler (L-0044 checks spam, L-0061 fork `--repo`) tek-atış regex'le yakalanamaz → skill/bsa-denetci'de.
