---
name: bsa-windows-shell
description: Windows ortamında Bash/PowerShell tool seçimi, gh/git komutları, hook script'leri, Python yol/encoding sorunları ve MCP/plugin doğrulama işlerinde tetiklenir — *.ps1/*.sh/hook dosyası, komut içeren diff veya "komut çalışmadı" hatası görülünce.
---
# bsa-windows-shell — Windows / PowerShell / Git Bash ortam tuzakları

## Ne zaman
- `*.ps1`, `*.sh`, `.claude/hooks/**`, `hooks/**`, `settings.json` hook tanımı, `session-start.sh` düzenleniyorsa
- `gh pr create` / `gh release create` / `git push` / `Copy-Item` / `Stop-Process` gibi komut koşulacaksa
- Windows-native Python (`C:\Python314\python.exe`) script'i yazılıyor veya Bash ile Python dosya paylaşıyorsa
- "command not found", "unknown argument", exit 49/141, `UnicodeEncodeError`, `FileNotFoundError` (klasör varken) görülürse
- Plugin/skill/MCP kurulumu veya "kuruldu ama çalışmıyor" şikayeti; Gmail MCP ile makbuz/ek okuma

## Görev başı kontrol listesi
1. Hangi tool? Unix/çapraz komut (git, pnpm, npx, curl, mv, cp) → Bash tool; PS cmdlet, registry, COM, D:/ağ sürücüsü → PowerShell tool (L-0051).
2. Komut PowerShell'e gidiyorsa `&&` var mı → ayrı satırlara böl (BLOK 23; hook da yakalar).
3. Çok satırlı metin (PR/release body) → önce dosyaya yaz, `--body-file` (L-0068).
4. Bekleme adımı var mı → sabit `sleep`/polling loop yerine tek-shot kontrol (L-0019/L-0041).
5. Rapor/dokümana örnek shell komutu yazılacaksa Write tool (L-0083).
6. Uzun yol / Türkçe karakter / `/tmp` paylaşımı var mı → kısa Windows yolu + utf-8 (L-0064/L-0078/L-0087).

## Kurallar (BigBrain dersleri)

### Tool seçimi: Bash tool vs PowerShell tool
- **L-0051** — Bash tool Windows'ta da POSIX bash'tir: PS cmdlet'leri (Move-Item, Get-Content, Select-String…) ve CMD sözdizimi (`timeout /t`, `pause`, `>nul`) çalışmaz; `mv`/`cp`, `sleep N`, `> /dev/null` kullan (`timeout` burada GNU coreutils). Windows-özgü iş (registry, winsound, COM) → PowerShell tool. (hook da yakalar)
- **L-0029** — `[System.IO.File]::...` .NET çağrıları PowerShell `cd`'sini takip etmez; ASLA göreli yol verme, `C:\...` tam yol ver veya `Get-Content`/`Set-Content` cmdlet'ini kullan.
- **L-0070** — `Join-Path`/`New-Item` erişilemeyen sürücüde (D:, G:, ağ) $null döner; `Copy-Item $src $null` mevcut dizindeki aynı adlı dosyayı EZER (BigBrain/CLAUDE.md 217 → 1 satır oldu). Önce `if (-not (Test-Path (Split-Path $dst -Qualifier))) { Write-Error "Sürücü yok"; exit 1 }`; `$dst` boşsa `continue`; sandbox'ta yalnız C: erişilebilir → kullanıcıya `! <komut>` ile kendi terminali öner.
- **L-0084** — `Get-Process -Name "*claude*"` / `Stop-Process -Name claude` Claude Code CLI'yı da öldürür; `Get-Process | Where-Object { $_.Path -like "*AnthropicClaude*" }` yol filtresi kullan. (hook da yakalar)

### gh / git komutları
- **L-0066** — PowerShell 5.1 `&&`, `<<`, heredoc desteklemez; `--title` içinde `&&` geçince pipeline operatörü sanılır. `"$(cat <<'EOF'...)"` kalıbını PowerShell'de ASLA kullanma; başlıkta `&&` yazma, farklı ifade seç. (hook `&&` için POWERSHELL'de yakalar)
- **L-0068** — `@"..."@` here-string + `--body $body` newline'da "unknown argument" verir; PR/release body DAİMA `--body-file <geçici .md>` (Write tool ile oluştur, PR açılınca sil). (hook `--body "` yakalar)
- **L-0030** — CLI parametresinde `\"` kaçışlı tırnak PowerShell string'ini kırar ("unknown shorthand flag"); metni sadeleştir veya `--body-file`. Hata alınca önce tırnak katmanlarına bak.
- **L-0079** — `git add/commit/push` ASLA background'da çalıştırma (`.git/index.lock` kalır, sonraki commit "File exists" ile bloklanır). Kilit kaldıysa `git status`, gerekirse `rm .git/index.lock`. Uzun push harness'te otomatik background'a düşebilir → `git status` "up to date" görmeden "bitti" deme.

### Doğru kalıp — PowerShell'de PR açma (L-0030/L-0066/L-0068 birleşik)
1. Write tool ile gövdeyi dosyaya yaz: `C:\Users\BSA\Projects\_prompts\pr-body.md` (Özet / Değişen Dosyalar / Test).
2. `gh pr create --repo <owner/repo> --title "feat: kısa Türkçe başlık" --body-file C:\Users\BSA\Projects\_prompts\pr-body.md` (`--repo` zorunlu, fork/template'te upstream'e açabilir — L-0061).
3. `Remove-Item C:\Users\BSA\Projects\_prompts\pr-body.md`
4. Her adım ayrı satır; başlıkta `&&` yok, kaçışlı tırnak yok.

### Bekleme ve arka plan
- **L-0019** — CI/deploy beklerken `until ... do sleep; done` background loop YASAK (zombie task); her turda 1 kez MCP `get_deployment`/`list_deployments`. Preview URL'i tahmin etme, MCP/webhook'tan gerçek URL al; READY ise undraft + merge.
- **L-0041** — Sabit `sleep 90` gibi uzun bekleme Claude Code'da engellenir; "şimdi kontrol et" yaklaşımı (tek-shot MCP status); merge + tag + release sırasında zaten yeterli süre geçer.

### Hook script'leri (SessionStart / stop-hook)
- **L-0026** — `additionalContext` ~2KB'de sessizce kesilir; hook'ta `cat` ile ham dosya basma, `grep` ile yalnız gereken satırlar (başlıklar, tablo satırları); toplam çıktı ≤1800 byte + "detay gerekirse dosyayı oku" notu.
- **L-0027** — `set -euo pipefail` + boru + `head -c 1800` = SIGPIPE (exit 141), script `emit_json`'dan önce ölür ("No stderr output"). Önce tam çıktıyı `$OUT`'a yaz; sonra ayrı komutla `head -c 1800 "$OUT" > "$OUT.tmp"` ve `mv "$OUT.tmp" "$OUT"`; `trap 'rm -f "$OUT" "$OUT.tmp"' EXIT`.
- **L-0063** — `python3` Windows Store stub'u (`WindowsApps/python3`) non-interactive hook'ta exit 49 verir; `command -v python3` yeterli değil. Hook'larda tam yol `/c/Python314/python`; kontrol `ls /c/Python314/python.exe`.
- **L-0064** — Git Bash `/tmp` = `C:/Users/BSA/AppData/Local/Temp`; Windows-native Python `/tmp/x` bulamaz. Paylaşılan geçici dosya için `C:/Users/BSA/AppData/Local/Temp/<dosya>` (Bash'te `TMPDIR="C:/Users/BSA/AppData/Local/Temp"`; Python'da `os.path.join(tempfile.gettempdir(), 'dosya')`).
- **L-0083** — Stop-hook, PowerShell here-string içindeki örnek komutu (`rd /s /q`, `rm -rf`, `git reset --hard`) gerçek komut sanıp bloklar; rapor/README/doküman içeriğini **Write tool** ile yaz (hook'tan geçmez); "örnek komutu çalıştır + çıktıyı dosyaya yönlendir"i tek adımda birleştirme.

### Python / yol / encoding
- **L-0077** — `DIR / name + ".txt"` → `(Path / str) + str` TypeError; uzantıyı string tarafında kapat: `DIR / (name + ".txt")` veya `DIR / f"{name}.txt"`.
- **L-0078** — Windows konsolu cp1254; Türkçe `print()` `UnicodeEncodeError: 'charmap'`. Script başına `import sys,io; sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")` veya dışarıdan `set PYTHONIOENCODING=utf-8`.
- **L-0087** — Scratchpad yolu ~230 karakter; MAX_PATH 260 aşılınca `FileNotFoundError` (klasör varken). Büyük çıktıyı kısa yola yaz (`C:/Users/BSA/AppData/Local/Temp/<dosya>` veya proje kökü), scratchpad'i küçük JSON'a bırak; yolları ileri slash ile; ters bölü gerekirse `re.sub`/Edit (Git Bash `sed` `\U`/`\A` kaçışını bozar); uzun kaynağı `Copy-Item -LiteralPath "\\?\C:\..."` ile kısa yola kopyala.
- **L-0015** — Async Python'da `requests.*`, `time.sleep()`, `Thread().start().join()` YASAK; `httpx.AsyncClient` pool, `asyncio.sleep()`, `critical_executor`/`storage_executor`; commit öncesi `python scripts/lint_async_blockers.py`; in-function import yok.

### Kullanıcıya komut/talimat verme
- **L-0031** — Uzun talimat chat'e yapıştırılmaz; `C:\Users\BSA\Projects\_prompts\<tarih>-<isim>.md` dosyasına kaydet, Claude Code'a tek satır: "şu dosyayı oku ve uygula". Dosya Downloads/_reports'tan _prompts'a taşınır.
- **L-0060** — Kullanıcıya verilen komut bloğu en fazla 8-10 satır; tek satır çalıştırılabilir, placeholder yok (L-0018 ile aynı kural).

## MCP / araç tuzakları
- **L-0097** — "Kuruldu ≠ çalışıyor": plugin `enabled` görünse de jq (double-shot-latte), global LSP binary (typescript-lsp), node_modules (episodic-memory) eksikse hook/MCP sessizce çalışmaz. Kurulum sonrası fiilen doğrula (`claude mcp list` "Connected", jq var mı). Windows'ta npx stdio MCP bağlanamıyorsa `--transport http` tercih et veya `cmd /c npx` sarmala; ilk `npm install`'ı önden yap (30 sn MCP timeout). `npx skills add -s "a,b"` virgüllü listeyi reddeder → her skill ayrı `-s`.
- **L-0085** — Gmail Stripe makbuz taraması: tutar yalnız HTML/plain gövdede (snippet dolgu karakterli). Önce konu bazlı envanter (`search_threads` sayfalama) → thread ID; `get_thread(PLAIN_TEXT)` gövde okumayı 4-5 paralel alt ajana böl (her ajan JSON yazar); servisi `acct_XXXX` ile eşle; makbuz yollamayanlarda failed-payment tutarı + not; TL/USD ayrı topla. Kişisel portal/invoice linkli raporu ASLA Artifact yapma → SendUserFile + "paylaşmayın".
- **L-0086** — Gmail MCP ek indiremez (`get_message` yalnız ad/mime/id). PDF ekler Claude-in-Chrome'da kullanıcının kendi oturumunda sayfa-içi `fetch` + inflate (`window.__pdfx`: stream inflate → ToUnicode CMap → Tj; `window.__queue` 3 paralel işçi), sonuç `get_page_text` ile okunur; innerHTML/blob:/localhost POST/js dönüşü ÇALIŞMAZ (~1000 karakterde kesilir, 45 sn timeout). İndirme yok, e-posta değişmez.

## v2.23'ten taşınan bloklar

### BLOK 23 — POWERSHELL KURALI
- Windows PowerShell 5.1'de `&&` operatörü ÇALIŞMAZ. Çok adımlı komutlar ASLA `&&` ile birleştirilmez; her komut ayrı satır (gerekiyorsa `;`, zincir için `if ($?)`). Tüm talimat, doküman ve hook çıktıları için geçerli. (hook POWERSHELL tool'da yakalar)
- Oturum başlatma iki ayrı satır: `cd C:\Users\BSA\Projects\BigBrain` sonra `claude --dangerously-skip-permissions`.

### GÜNCELLEME — CLAUDE.md
- "CLAUDE.md güncelle" denildiğinde içeriği `C:\Users\BSA\.claude\CLAUDE.md`'ye Write tool ile yaz; `Get-Content C:\Users\BSA\.claude\CLAUDE.md | Select-Object -First 3` ile doğrula.

### BLOK 23 madde 4 — CLAUDE.md script kalıntısı kontrolü (L-0050)
- Her CLAUDE.md düzenlemesinden sonra zorunlu: `Select-String -Path CLAUDE.md -Pattern 'Add-Content|Get-Content|\$addition'` → BOŞ dönmeli; doluysa o satırı sil. (Add-Content ile CLAUDE.md'ye yazmayı hook da yakalar.)
- L-0067 uyarısı: kontrol kalıbını CLAUDE.md içine literal yazma (doğrulama false-positive verir); bu skill dosyası CLAUDE.md değildir, kalıp burada durabilir.

## Rapora yazılacak
- `Uygulanan dersler: L-...` (bu listeden gerçekten uygulananlar).
- Kanıt: hangi tool'la çalıştırıldığı (Bash/PowerShell), `--body-file` kullanıldıysa dosya adı, hook çıktısı byte sayısı (≤1800), `git status` "up to date" çıktısı, `claude mcp list` "Connected" satırı.
- Hook tarafından bloklanan komut varsa hook mesajı + uygulanan alternatif.
- Bölümler: Sonuç / Yapılanlar / Test / Varsayımlar / Proaktif notlar / Ders adayları / Kullanılan skill/agent.
