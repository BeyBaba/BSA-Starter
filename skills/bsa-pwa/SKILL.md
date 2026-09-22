---
name: bsa-pwa
description: PWA işlerinde (service worker/Serwist, manifest, güncelleme bildirimi, cache versiyonlama, Web Push/Notification, izin akışı, ses/AudioContext, offline, platform algılama, iOS Safari) BigBrain derslerini ve v2.23 BLOK 7/9/10/14/16/21 kurallarını uygular. sw.*, manifest.json, serwist/next-pwa config, push/notification/audio/offline kodu dokunulurken çağır.
---
# bsa-pwa — PWA, bildirim, ses, offline kuralları

## Ne zaman
- `public/sw.js`, `app/sw.ts`, `serwist`/`next-pwa` config, `manifest.json`, `app/manifest.ts` dokunuluyor
- Web Push / Notification izni, `IosInstallPrompt`, izin onboarding modali yazılıyor
- `AudioContext`, `playSound()`, ses toggle'ı ekleniyor
- `navigator.onLine`, offline banner, mesaj kuyruğu/senkron kodu değişiyor
- Sürüm çıkışı: güncelleme modali, `CACHE_NAME`, push politikası; mobil/desktop platform algılama UX'i

## Görev başı kontrol listesi
1. `git status` — `public/sw.js` "Modified" görünüyorsa stage ETME (L-0040; `git add sw.js` hook da yakalar).
2. `grep -rn 'requestPermission\|Notification.requestPermission\|getUserMedia\|geolocation' src app` — izin isteği onboarding modali dışında bir yerde mi (L-0033).
3. `grep -rn 'new AudioContext\|AudioContext(' ` — gesture dışı başlatma var mı (L-0005).
4. `package.json` sürümü ile SW/`CACHE_NAME` sürümü eşit mi; güncelleme modali her sayfada mı (L-0013, BLOK 21).
5. `grep -i 'pwa\|push\|service worker\|ios' BigBrain/lessons/INDEX.md` — eşleşen dersleri rapora yaz.

## Kurallar (BigBrain dersleri)

### iOS ve izinler
- **L-0004** — iOS Safari'de Web Push/Notification API yalnızca PWA "Ana Ekrana Ekle" sonrası tanımlı; izin isteği kullanıcı dokunuşuyla tetiklenmeli. Önce `IosInstallPrompt` akışı, sonra permission flow. Standalone değilken izin isteme.
- **L-0033** — Tüm tarayıcı izinleri (bildirim/konum/kamera) ilk açılışta TEK "izin onboarding modali"nde: stepper + "Hepsini Kabul Et". Yeni izin gerektiren feature → modala en sona step ekle; başka yerde `requestPermission()` çağırma (iOS'ta reddedilen izin geri alınamaz). iOS'ta önce `IosInstallPrompt`, sonra modal.
- **L-0005** — `AudioContext` kullanıcı gesture'ı olmadan başlatılamaz (iOS'ta ses kesilir). İlk dokunuşta oluştur/`resume()` et; otomatik başlatma yok.

### Service worker ve güncelleme
- **L-0013** — SW yeni versiyon tespitinde toast/banner → `skipWaiting()` + `clients.claim()` + reload. `CACHE_NAME='app-v{versiyon}'`, eski cache otomatik temizlenir; `sw.js`'teki versiyon `package.json` ile eşitlenir (tek kaynak, elle senkron yok).
- **L-0040** — Serwist/next-pwa'nın ürettiği `public/sw.js` build artefaktıdır; commit/stage etme, `.gitignore`'a ekle (Vercel kendi build'inde üretir). Elle yazılmış özel `sw.js` varsa CLAUDE.md'ye açıkça yaz.

### İlgili (kısa)
- **L-0010** — PWA'da platformda imkansız özellik (Tor, BLE, WiFi Direct, OS-level screenshot block) arayüze konmaz; toggle/buton arkasında gerçek kod olmalı. **L-0088** — Koyu temada native `<select>` için `color-scheme`'i tema seçicisiyle hizala. **L-0021** — UI değişikliğini ekran görüntüsüyle doğrula (bsa-playwright).

## v2.23'ten taşınan bloklar
**BLOK 16 — PWA**
- skipWaiting aktif, eski cache temizleme, güncelleme bildirimi, cache versiyonlama.
- iOS Safari: `apple-mobile-web-app-*` meta tag'leri, `apple-touch-icon`.
- iOS PUSH/NOTIFICATION (v2.14): Web Push yalnız "Ana Ekrana Ekle" sonrası; izin isteği kullanıcı dokunuşuyla; önce IosInstallPrompt, sonra permission flow.
- Android Chrome + Desktop: standalone mode. İkonlar PNG/SVG 192x192 ve 512x512. `manifest.json` zorunlu. "Ana Ekrana Ekle" tüm platformlarda çalışmalı.

**BLOK 21 — PWA GÜNCELLEME BİLDİRİMİ (her PWA'da ZORUNLU)**
- SW yeni versiyon tespit edince toast/banner; mesaj: "🆕 Yeni güncelleme mevcut! Yenilemek için tıkla".
- Tıklanınca: `skipWaiting()` + `clients.claim()` + `window.location.reload()`.
- Cache versiyonlama: `CACHE_NAME = 'app-v{versiyon}'`; yeni deploy = eski cache otomatik temizlenir.
- Bildirim dismiss edilemez, her sayfada görünür (fixed, üstte/altta), arka plan karartılır, yalnız "Güncelle" butonu aktif (modal stili).
- PUSH POLİTİKASI (v2.15): kapalıyken gönderilen "yeni sürüm" push'u yalnız ORTA/BÜYÜK (minor/major) sürümde; KÜÇÜK (patch) sürümde push GÖNDERME — patch yalnız açılıştaki modalla duyurulur (her patch'te push bildirimleri komple kapattırır).
- Görünür güncelleme modali HER sürümde, bildirim izninden BAĞIMSIZ gösterilir.

**BLOK 14 — BİLDİRİM:** Web Notification API (native: expo-notifications); kullanıcı tarafından kapatılabilir.

**BLOK 9 — SES:** `playSound()` her etkileşimde; kapatılabilir toggle (persist). AudioContext L-0005'e göre gesture'da başlar.

**BLOK 10 — OFFLİNE:** `navigator.onLine` kontrolü; offline uyarı banner; mesaj/yazma kuyruğu; online olunca otomatik senkronize.

**BLOK 7 — MOBİL (PWA/platform kısmı):** `rs()`/`rFont()` 375px referans; dokunma hedefi min 44px; viewport meta. Platform algıla → farklı UX: mobilde native gibi (tam ekran, gesture, bottom nav), webde web gibi (sidebar, hover, geniş layout). Haptic feedback: tüm butonlarda `navigator.vibrate()`.

## Manifest / meta kontrol listesi (BLOK 16)
- `manifest.json`: `name`, `short_name`, `start_url`, `display: "standalone"`, `theme_color`, `background_color`, `icons` 192x192 + 512x512 (PNG/SVG, `purpose: "any maskable"`).
- `<head>`: `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">`, `apple-mobile-web-app-capable`, `apple-mobile-web-app-status-bar-style`, `apple-mobile-web-app-title`, `<link rel="apple-touch-icon">`.
- Standalone tespiti: `window.matchMedia('(display-mode: standalone)').matches` veya `navigator.standalone` (iOS) → izin/push akışı yalnız bu durumda (L-0004).
- Platform tespiti: `navigator.userAgent` iOS/Android + `(pointer: coarse)` → mobil UX; aksi web UX (BLOK 7).

## Uygulama iskeleti (özet)
```ts
// Güncelleme modali (BLOK 21 / L-0013) — Serwist: window.serwist / next-pwa: wb
reg.addEventListener('updatefound', () => {
  const sw = reg.installing; sw?.addEventListener('statechange', () => {
    if (sw.state !== 'installed') return;
    if (navigator.serviceWorker.controller) showUpdateModal();      // dismiss yok, her sayfada
  });
});
// "Güncelle": reg.waiting?.postMessage({ type: 'SKIP_WAITING' }); controllerchange → window.location.reload()
// Ses (L-0005 / BLOK 9): ctx ??= new AudioContext(); await ctx.resume();  // yalnız onClick/onTouchStart içinde
// Haptic (BLOK 7): navigator.vibrate?.(10)
```
Sürüm push kararı: `semver.diff(prev, next)` → `minor`/`major` ise push, `patch` ise yalnız modal.

## Rapora yazılacak
- `Uygulanan dersler: L-...` satırı.
- Kanıt: güncelleme modalinin ekran görüntüsü (Playwright, `test-results/update-modal.png`), `CACHE_NAME`/`package.json` sürüm eşitliği (`grep` çıktısı), `git status`'ta `sw.js` stage'lenmediği, izin isteği yerlerinin listesi (tek modal).
- Platform kısıtı varsa özellik raporu: `❌ BU PLATFORMDA İMKANSIZ — [neden]` / `⚠️ YAZILDI AMA AKTİF DEĞİL — [aktivasyon adımı: örn. Ana Ekrana Ekle]`.
- Sürüm çıkışında push gönderilip gönderilmediği ve gerekçesi (patch/minor/major).

Kaynak dersler: L-0004, L-0005, L-0010, L-0013, L-0021, L-0033, L-0040, L-0088
