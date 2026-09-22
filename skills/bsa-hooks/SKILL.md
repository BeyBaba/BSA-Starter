---
name: bsa-hooks
description: Claude Code hook'ları (SessionStart / Stop / PreToolUse guard) kurulurken, düzenlenirken, test edilirken veya "hook çalışmıyor", "iki kez tetiklendi", "yeni kural ekle", "session özeti" dendiğinde tetiklenir; BSA-Starter Faz 1 hook mimarisini ve BLOK 23 oturum sürekliliği kurallarını uygular.
---
# bsa-hooks — Hook mimarisi, kural ekleme ve oturum sürekliliği

## Ne zaman
- `hooks/`, `.claude/hooks/`, `~/.claude/settings.json`, `rules.txt` veya `test-guards.sh` dosyalarına dokunulacaksa.
- Belirtiler: "hook çalışmıyor", "hook iki kez çalıştı", "hookEventName eksik", "python bulunamadı exit 49", "hook çıktısı kesildi".
- Yeni bir deterministik kural (komut deseni → engel) eklenecek veya mevcut kural test edilecekse.
- Yeni terminal session açılırken, session sonu özeti üretilirken, CLAUDE.md düzenlendikten sonra (BLOK 23).

## Görev başı kontrol listesi
1. `grep -i 'hook' C:/Users/BSA/Projects/BigBrain/lessons/INDEX.md` → ilgili dersleri (L-0026, L-0027, L-0049, L-0050, L-0062, L-0063, L-0065, L-0083, L-0097) "Uygulanan dersler" olarak not al.
2. Kurulu global hook'lar: `ls ~/.claude/hooks/` → global-session-start.sh, global-session-end.sh, pre-bash-guard.sh, pre-write-guard.sh, rules.txt bekle.
3. Proje yerel `.claude/settings.json`'da aynı event (SessionStart/Stop/PreToolUse) tanımlı mı → çakışma (L-0062).
4. `bash hooks/bsa-doctor.sh` → ön koşul ve kurulum doğrulaması ("kuruldu ≠ çalışıyor", L-0097).
5. Guard betiği veya rules.txt değiştiyse `bash hooks/test-guards.sh` → "TUM KURALLAR GECTI" görmeden PR açma.
6. Örnek komut içeren doküman/rapor yazacaksan Write aracı kullan (L-0083).

## Kurallar (BigBrain dersleri)
- **L-0049** — SessionStart hook açık session içinde tetiklenemez; "yeni session aç" komutu Claude Code'a verilemez. Önce çık (exit veya Ctrl-C), terminalde repo klasörüne `cd`, ayrı satırda `claude` çalıştır.
- **L-0062** — Global (`~/.claude/settings.json`) + yerel (`.claude/settings.json`) aynı event'i tanımlarsa hook iki kez çalışır (BigBrain'de çift ders-kontrol sorusu). Yeni global hook eklenince tüm projelerin yerel settings.json'unu tara, çakışan event'i kaldır; ikisini birden tutma.
- **L-0065** — SessionStart JSON çıktısı `"hookEventName": "SessionStart"` içermeli: `{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}`; yoksa "hookSpecificOutput is missing required field hookEventName". Stop hook farklı format kullanır: `{"decision":"block","reason":"..."}` — karıştırma.
- **L-0063** — Windows Store `python3` stub'u non-interactive hook'ta exit 49 verir; `command -v python3` yeterli değil (sonuçta WindowsApps görünüyorsa gerçek Python yok say). Tam yol kullan: `/c/Python314/python`; kontrol: `ls /c/Python314/python.exe`.
- **L-0026** — SessionStart `additionalContext` ~2KB'de sessizce kesilir. Hook'ta `cat` ile dosya basma; `grep` ile başlık/tablo satırı çek, çıktıyı Python içinde kırp (1800 karakter), pipe+head yok (L-0027); "detay gerekirse dosyayı oku" notu ekle.
- **L-0027** — `set -o pipefail` + `| head` kombinasyonu hook betiğinde SIGPIPE (exit 141) ile exit≠0 verir ve betiği emit_json'dan önce öldürür. Kırpmayı Python tek süreçte yap (1800 karakter); shell'de boru + `head` kullanma. Shell zorunluysa: tam çıktıyı `$OUT`'a yaz, AYRI komutla `head -c 1800 "$OUT" > "$OUT.tmp"; mv "$OUT.tmp" "$OUT"`, `trap 'rm -f "$OUT" "$OUT.tmp"' EXIT`. Tetik: SessionStart/Stop hook betiği yazma.
- **L-0083** — Rapor/dokümana örnek shell komutu (`rd /s /q`, `rm -rf`, `git reset --hard`) PowerShell here-string ile yazılırsa stop-hook gerçek komut sanıp bloklar. Örnek komut içeren metni Write aracıyla yaz; "komutu çalıştır + çıktıyı dosyaya yönlendir"i tek adımda birleştirme.
- **L-0050** — CLAUDE.md'ye içerik ekledikten sonra script kalıntısı kontrolü zorunlu: `Select-String -Path CLAUDE.md -Pattern 'Add-Content|Get-Content|\$addition|@'''` boş dönmeli; doluysa satırı sil (BigBrain, arya-life-reborn'da görüldü).
- **L-0097** — Plugin/skill "installed" görünse de ön koşul eksikse hook/MCP sessizce çalışmaz (double-shot-latte → jq, typescript-lsp → global binary, episodic-memory → node_modules / 30sn MCP timeout, `npx skills add -s "a,b"` virgülü reddeder). Kurulumdan sonra fiilen doğrula: jq kurulu mu, LSP binary global mi, `claude mcp list` "Connected" mi; skill'leri tek tek `-s` ile ekle; Windows'ta stdio MCP için `cmd /c npx` sarmala veya `--transport http`.

## Hook mimarisi (Faz 1)
Kaynak: BSA-Starter `hooks/` (PreToolUse guard'lar) ve `.claude/hooks/` (SessionStart / Stop).

| Dosya | Event / matcher | Ne yapar |
|---|---|---|
| `hooks/pre-bash-guard.sh` | PreToolUse, `Bash` ve `PowerShell` | stdin hook JSON'undan `tool_input.command` ve `tool_name` çeker (jq → python3 → `/c/Python314/python` zinciri; L-0063). `rules.txt` satırlarını sırayla `grep -Eiq` ile dener; TOOL sütunu aracı sınırlar (BASH / POWERSHELL / ANY). Eşleşme → stderr `ENGELLENDI (L-XXXX): <mesaj>` + **exit 2 = engel**. Komut boş, rules.txt yok veya parse hatası → **fail-open (exit 0)**. |
| `hooks/rules.txt` | — | 4 sütun, gerçek TAB ayraçlı: `REGEX<TAB>L-no<TAB>mesaj<TAB>[TOOL]`; TOOL boşsa ANY; `#` satırı yorum. Yalnız komut-deterministik dersler: main'e push (L-0011), force-push / reset --hard / rm -rf / --no-verify / drop database (DESTRUCTIF), `.env` add (L-0014), worktrees ve .od/.tmp add (L-0020), sw.js add (L-0040), büyük binary add (L-0080), NEXT_PUBLIC SERVICE_ROLE (L-0003), gh repo delete (L-0028), `--body` çok satır (L-0068), PowerShell'de çift ampersan (L-0066), Bash'te PS cmdlet (L-0051), Add-Content CLAUDE.md (L-0050), Stop-Process claude (L-0084), flutterfire configure (L-0024), gh pr merge (L-0069). |
| `hooks/pre-write-guard.sh` | PreToolUse, `Write` ve `Edit` | `tool_input.file_path` (veya `path`) okur. (1) Secret dosyaları `.env`, `.env.*`, `*.pem`, `*.key`, `credentials`, `credentials.*`, `*.credentials` → exit 2 (L-0014). (2) `supabase/migrations/` altında aynı `NNNN` önekli FARKLI adlı dosya varsa → "ENGELLENDI (migration numara cakismasi)" exit 2; çözüm bir sonraki boş numara (`db push --include-all` sıra-dışı uygular). Fail-open. |
| `hooks/settings.snippet.json` | — | `~/.claude/settings.json` içindeki `hooks` nesnesine eklenecek iki PreToolUse bloğu: `bash C:/Users/BSA/.claude/hooks/pre-bash-guard.sh` (matcher `Bash|PowerShell`) ve `bash C:/Users/BSA/.claude/hooks/pre-write-guard.sh` (matcher `Write|Edit`). Betikler + rules.txt `~/.claude/hooks/` altına kopyalanır. |
| `hooks/test-guards.sh` | — | 30 test: her kural için MATCH (exit 2 beklenir) + NOMATCH (exit 0) sahte hook JSON'u; JSON'u python ile kurar (`/c/Python314/python` → python3 → python); migration çakışmasını geçici klasörde `0035_existing.sql` ile dener; sonda `=== SONUC: PASS=n FAIL=n ===` ve "TUM KURALLAR GECTI". |
| `.claude/hooks/session-start.sh` | SessionStart | `~/.claude/hooks/global-session-start.sh` varsa exit 0 (L-0062). BigBrain `lessons/INDEX.md`'den `## L-` başlıklarının son 12'sini + toplam ders sayısını ve `projects/INDEX.md` proje sayısını toplar, 1800 karakterde kırpar (Python içinde, pipe+head yok; L-0026, L-0027), jq → python3 → python → node zinciriyle `hookEventName: SessionStart` JSON'u basar (L-0065); hiçbiri yoksa görünür "BigBrain hafizasi YUKLENEMEDI" uyarısı (sessiz çökme YASAK). |
| `.claude/hooks/session-end.sh` | Stop | `~/.claude/hooks/global-session-end.sh` varsa exit 0. `"stop_hook_active": true` ise exit 0 (döngü koruması). İlk duruşta `{"decision":"block","reason":"DERS KONTROLU (BigBrain): ..."}` ile ders adayı değerlendirmesi ister: varsa `lessons/inbox/YYYY-AA-GG-kisa-slug.md` ('## Belirti' / '## Kok Neden' / '## Kural-Cozum'), INDEX.md'ye DOKUNMA; yoksa tek satır "Ders adayi yok". |

Kurulum ve doğrulama (aynı PR'da ayrı yazılan betikler; içerikleri bu skill'de tanımlanmaz):
- `bash hooks/install.sh` → guard betiklerini ve rules.txt'i `~/.claude/hooks/` altına kopyalar, `settings.snippet.json`'u `~/.claude/settings.json`'a merge eder.
- `bash hooks/bsa-doctor.sh` → ön koşul ve kurulum doğrulaması: jq / python / node varlığı, betik yolları, settings kaydı, çakışan yerel hook (L-0062), plugin ön koşulları (L-0097).

## Yeni kural ekleme
1. Ders deterministik mi? Komut string'inden regex ile kesin anlaşılıyorsa `rules.txt`; muhakeme gerekiyorsa bsa-denetci hafızasına (MEMORY.md) gider, hook'a değil.
2. `hooks/rules.txt`'e satır ekle: `REGEX<TAB>L-XXXX<TAB>mesaj. Dogru yol: <kisa><TAB>TOOL`. Ayraç gerçek TAB; mesaj Türkçe ama ASCII (stderr'de bozulmasın); L-no BigBrain INDEX'teki gerçek numara.
3. `hooks/test-guards.sh`'e en az iki satır: `runb "<ad> MATCH" 2 Bash "<eslesen komut>"` ve `runb "<ad> NOMATCH" 0 Bash "<eslesmeyen benzer komut>"`. Write/Edit kuralı için `runw`. PowerShell'e özel kuralda tool `PowerShell`, Bash'te NOMATCH karşılığını da ekle.
4. Çalıştır: `bash hooks/test-guards.sh` → `SONUC: PASS=<n> FAIL=0` ve "TUM KURALLAR GECTI". Yanlış pozitif için normal komutları NOMATCH olarak dene (`ls -la src`, `git push origin feat/x`, `git add src/index.ts`).
5. Kurulu kopyayı güncelle: `bash hooks/install.sh`; ardından `bash hooks/bsa-doctor.sh`.
6. Feature branch → PR (`gh pr create --repo BeyBaba/BSA-Starter --body-file <dosya>`; L-0061, L-0068) → squash merge. main'e direkt push YASAK.
7. Test veya dokümana yasaklı pattern'i literal yazıp doğrulamayı kirletme (L-0067); örnek komut içeren dosyayı Write aracıyla yaz (L-0083).

## v2.23'ten taşınan bloklar — BLOK 23 OTURUM SÜREKLİLİĞİ (v2.19)
⚠️ POWERSHELL KURALI: Windows PowerShell 5.1'de çift ampersan operatörü ÇALIŞMAZ. Çok adımlı komutlar asla onunla birleştirilmez; her komut ayrı satır (gerekiyorsa `;`) olarak verilir. Bu kural tüm talimat, doküman ve hook çıktıları için geçerlidir.

1. YENİ CLAUDE CODE SESSION BAŞLANGICI — her yeni terminal session'ında iki ayrı satır:
   ```
   cd C:\Users\BSA\Projects\BigBrain
   claude --dangerously-skip-permissions
   ```
   Bu sayede bypass permissions ve BigBrain hook'ları otomatik aktif olur. Açık session içinden tetiklenemez (L-0049).

2. CLAUDE CODE SESSION SONU RAPORU — Claude Code oturum sonunda tam olarak bu formatı üretir:
   ```
   === BigBrain SESSION OZET ===
   Repo: <calisilan repo>
   Yapilan: <1-3 cumle ozet>
   PR'lar: <PR linkleri>
   Inbox adaylari: <varsa slug listesi, yoksa "yok">
   Sonraki adim: <varsa bekleyen is, yoksa "yok">
   === OZET SONU ===
   ```
   Kullanıcı bu özeti Claude.ai'ya yapıştırınca bağlam anında kurulur.

3. CLAUDE.AI PROJE İZOLASYONU — her Claude.ai projesi kendi sohbet adasında izole; cross-project arama yapılamıyor. B3 madenciliği (Claude.ai ders tarama) her projenin kendi session'ında yapılmalı. Yeni proje açılırken BigBrain devir notunu knowledge olarak ekle (L-0048).

4. CLAUDE.MD SCRIPT KALINTISI KONTROLÜ — her CLAUDE.md düzenlemesinden sonra zorunlu:
   `Select-String -Path CLAUDE.md -Pattern 'Add-Content|Get-Content|\$addition'`
   Boş dönmeli. Doluysa satırı sil (L-0026 ve L-0044+ dersleriyle bağlantılı; L-0050).

## Rapora yazılacak
- "Uygulanan dersler": bu skill'deki ders numaralarından hangileri devreye girdi.
- `bash hooks/test-guards.sh` son satırı (`SONUC: PASS=.. FAIL=..`) ve `bash hooks/bsa-doctor.sh` sonucu (birebir çıktı).
- Eklenen/değişen rules.txt satırları (regex + L-no + TOOL) ve karşılık gelen MATCH/NOMATCH test adları.
- Çakışma taraması: hangi projelerin yerel `.claude/settings.json`'unda aynı event bulundu, ne yapıldı (L-0062).
- CLAUDE.md düzenlendiyse madde 4 kontrolünün boş döndüğü.
- Session sonunda "=== BigBrain SESSION OZET ===" bloğu (madde 2 formatıyla, birebir).
- Ders adayları: `lessons/inbox/<tarih>-<proje>-<slug>.md` dosya adları veya "yok"; Kullanılan skill/agent (bsa-hooks, varsa hookify, bsa-denetci → "Denetim").

Kaynak dersler: L-0003, L-0011, L-0014, L-0020, L-0024, L-0026, L-0027, L-0028, L-0040, L-0044, L-0048, L-0049, L-0050, L-0051, L-0061, L-0062, L-0063, L-0065, L-0066, L-0067, L-0068, L-0069, L-0080, L-0083, L-0084, L-0097
