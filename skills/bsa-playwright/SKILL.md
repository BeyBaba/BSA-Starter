---
name: bsa-playwright
description: Playwright e2e/UI testi ve deploy sonrası doğrulama işlerinde (playwright.config, tests/**, *.spec.ts, global-setup, auth.json/storageState, CI bekleme, prod URL kontrolü) BigBrain derslerini ve "UI TESTİ ZORUNLU (v2.15)" + BLOK 6 tsc kuralını uygular. Her UI/davranış değişikliğinde ve push öncesinde çağır.
---
# bsa-playwright — UI testi, kanıt ve doğrulama kuralları

## Ne zaman
- `playwright.config.ts`, `tests/**`, `e2e/**`, `*.spec.ts`, `global-setup.ts`, `auth.json` dokunuluyor
- Herhangi bir UI/davranış değişikliği yapıldı ve "çalışıyor" denecek (UI TESTİ ZORUNLU)
- Push/PR öncesi tip kontrol + test koşusu; CI/deploy beklenirken
- Deploy sonrası production URL'de sürüm etiketi / sayfa doğrulaması
- Supabase auth gerektiren (login arkası) sayfaların testi yazılıyor

## Görev başı kontrol listesi
1. `npx tsc --noEmit` (pnpm projede `pnpm tsc --noEmit`) — 0 hata; push öncesi ZORUNLU (BLOK 6).
2. `grep -rn 'storageState\|auth.json' playwright.config.ts tests/` — auth dosya yolu TEK kaynak mı (L-0090).
3. `playwright.config.ts` başında dotenv var mı; `webServer` bloğu `url` ile mi (L-0047, L-0042, L-0046).
4. Yeni test öncesi `gh pr list` + `git branch -a` — aynı testi başka oturum yazmış olabilir (L-0092).
5. `grep -i 'playwright\|e2e' BigBrain/lessons/INDEX.md` — eşleşen dersleri rapora "Uygulanan dersler" yaz.

## Referans config (dersler işaretli)
```ts
import { config } from 'dotenv';
import path from 'path';
config({ path: '.env.local' });                                   // L-0047
const AUTH_FILE = path.join(__dirname, 'auth.json');              // L-0090: tek kaynak (kök)
export default defineConfig({
  globalSetup: './tests/global-setup.ts',                          // L-0039: tek seferlik login → AUTH_FILE
  use: { storageState: AUTH_FILE, headless: true },
  workers: 1,                                                      // Supabase auth rate-limit
  webServer: {                                                     // L-0042 + L-0046
    command: 'next start -p 3100',
    url: 'http://localhost:3100',                                  // port değil url: HTTP 200 bekler
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
```
```ts
// tests/global-setup.ts — L-0039 tek seferlik login, L-0090 aynı AUTH_FILE
import { chromium } from '@playwright/test';
import path from 'path';
export default async function globalSetup() {
  const authFile = path.join(__dirname, '..', 'auth.json');      // config ile AYNI yol
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto('http://localhost:3100/login');
  await page.fill('input[type=email]', process.env.TEST_ADMIN_EMAIL!);
  await page.fill('input[type=password]', process.env.TEST_ADMIN_PASSWORD!); // .env.local → dotenv (L-0047)
  await page.click('button[type=submit]');
  await page.waitForURL('**/dashboard');
  await page.context().storageState({ path: authFile });
  await browser.close();
}
```
Guard yazılacaksa `fs.existsSync(authFile)` AYNI `authFile` sabitini kullanır; yol farklıysa tüm suite skip olur (sahte yeşil).
Koşu: `pnpm playwright test --workers=1` (projede `pnpm test:e2e` varsa onu kullan). Ekran görüntüsü: `await page.screenshot({ path: 'test-results/<sayfa>.png', fullPage: true })`.
`auth.json`, `test-results/`, `playwright-report/` git DIŞI (.gitignore) — GİT HİJYENİ (v2.14).

## Kurallar (BigBrain dersleri)

### Auth ve ortam
- **L-0039** — Her testte yeniden `login()` çağırma; 15+ Supabase auth isteği rate-limit'e takılır (tek worker'da bile). `globalSetup` ile bir kez giriş yap, oturumu `auth.json`'a kaydet, `use: { storageState: 'auth.json' }` ile tüm testlerde kullan. Aynı helper'lı testlerin bir kısmı geçiyorsa kod değil rate-limit.
- **L-0090** — storageState/auth.json yol uyuşmazlığı (guard `tests/auth.json`, config kök `auth.json`) tüm auth-gated testleri `test.skip()` ile sessizce atlar → sahte yeşil. Yolu tek kaynaktan yönet (`path.join(__dirname,'..','auth.json')`); guard, config ve global-setup aynı yolu kullansın. "N skipped" = geçti DEĞİL; skip sayısını raporla.
- **L-0047** — Playwright `.env.local`'i otomatik yüklemez (Next sunucusu yüklese de test prosesi ayrı). Config'in en üstüne `import { config } from 'dotenv'; config({ path: '.env.local' });` — gerekirse `pnpm add -D dotenv`. Belirti: `TEST_ADMIN_PASSWORD` tanımsız.

### Sunucu yaşam döngüsü
- **L-0042** — Sunucuyu elle başlatma; `playwright.config.ts`'e `webServer` ekle: `{ command: 'next start -p 3100', url: 'http://localhost:3100', reuseExistingServer: !process.env.CI, timeout: 120000 }`. Test komutu sunucuyu otomatik başlatır ve durdurur; port çakışması biter.
- **L-0046** — `webServer.port` yalnız portun açık olduğunu kontrol eder; Next.js port açık ama compile bitmemiş olabilir → globalSetup timeout. `url` kullan: HTTP 200 dönene kadar bekler (`{ url: 'http://localhost:3000', reuseExistingServer: !process.env.CI, timeout: 120_000 }`).

### CI/deploy bekleme ve prod doğrulama
- **L-0037** — CI/deploy beklerken pasif durma: her 60 sn tek-shot status check (background loop değil — L-0019; `gh pr checks --watch` — L-0044), bu sırada paralel hazırlık (PR body, migration SQL, relay komutu). Durumu görünür tut: "X sn'dir bekliyorum, 60 sn sonra kontrol, bu sırada Y hazırladım." 15 deneme (15 dk) aşılırsa "manuel müdahale gerekebilir" bildir.
- **L-0091** — Prod doğrulamada curl/Invoke-WebRequest client-render'ı (Suspense arkası sürüm etiketi vb.) göremez; ~20 hızlı istek 403 "Vercel Security Checkpoint" tetikler. Client-render değeri tarayıcı/Playwright ile doğrula; HTTP aracı yalnız tek/az istekle 200 sağlık kontrolü için. Sürüm gibi değerleri server component'te render et ki HTML'de görünsün.

### Sık düşülen ilgili dersler (kısa)
- **L-0021** — UI değişikliğini "hot restart edip umma" değil programatik doğrula. **L-0020** — Playwright raporlarını/worktree'yi commit etme (hook `.claude/worktrees`, `.od/`, `.tmp/` için de yakalar). **L-0041** — Sabit `sleep N` bloke olur; direkt kontrol et.

## v2.23'ten taşınan bloklar
**UI TESTİ ZORUNLU (v2.15):** Her UI/davranış değişikliğinde headless Chromium (Playwright) ile testi çalıştır; mümkünse ekran görüntüsüyle doğrula. Görsel/test kanıtı olmadan "çalışıyor" DEME. Otonom merge yalnız build + typecheck + UI testi geçtikten sonra.

**BLOK 6 — BUILD/DEPLOY:** `npx tsc --noEmit` zorunlu (push öncesi, 0 hata). Önce otomatik dene, yapamazsan kullanıcıya komutu ver. Build + typecheck temiz olmadan push YOK.

**DÜRÜSTLÜK (özellik raporu):** her özellik için `✅ ÇALIŞIYOR — [test kanıtı]` / `⚠️ YAZILDI AMA AKTİF DEĞİL — [aktivasyon adımları]` / `❌ BU PLATFORMDA İMKANSIZ — [neden]`. Test edilip doğrulanmadan "bitti" yok.

## Rapora yazılacak
- `Uygulanan dersler: L-...` satırı.
- **Test** bölümü zorunlu içerik: `tsc --noEmit` sonucu (0 hata), `pnpm build` sonucu, Playwright özeti **passed / failed / skipped** sayılarıyla (skipped > 0 ise nedeni), ekran görüntüsü dosya yolları (`test-results/*.png`).
- DB'ye bağımlı test ertelendiyse "Varsayım: canlı doğrulama sonra" (L-0072 ile uyumlu).
- Prod doğrulama yapıldıysa yöntem (tarayıcı/Playwright, istek sayısı) ve görülen sürüm etiketi.

Kaynak dersler: L-0019, L-0020, L-0021, L-0037, L-0039, L-0041, L-0042, L-0044, L-0046, L-0047, L-0072, L-0090, L-0091, L-0092
