---
name: bsa-ui-format
description: UI/arayüz, tema, para-telefon biçimi, i18n ve responsive layout işlerinde tetiklenir — *.tsx bileşen, globals.css/tema, tr.json/en.json, format/telefon/para yardımcıları veya asistan FAB/TTS kodu değişince.
---
# bsa-ui-format — UI biçim, Material You, karanlık mod, i18n, responsive

## Ne zaman
- `*.tsx` / `*.jsx` bileşen, sayfa, layout; `globals.css`, `tailwind.config.*`, tema/`ThemeProvider`
- `lib/format*`, `formatMoney`, `parseMoney`, `PhoneInput`, `normalizeTrPhone`, `wa.me` linki üreten kod
- `locales/tr.json` / `en.json`, `useTranslation`; hardcoded UI metni görülürse
- Native `<select>`/dropdown, `color-scheme`, `.dark`/`data-theme` değişikliği
- AI asistan cevabı / FAB / TTS (`parseNavigate`, `speechSynthesis`) kodu
- PDF/makbuz/sözleşme/WhatsApp-e-posta metni gibi para veya telefon GÖSTEREN her yer

## Görev başı kontrol listesi
1. Skill çağır: UI işi → **frontend-design** + **web-design-guidelines**; React/Next.js kodu → **vercel-react-best-practices**; UI testi → **playwright-best-practices**.
2. `grep -rn 'formatMoney\|PhoneInput\|useTranslation\|color-scheme' src/` → mevcut tek-kaynak yardımcıları bul, YENİSİNİ YAZMA (MEVCUT KODU OKU).
3. Proje seed color'ı ve Material You token'ları (CSS variables) hangi dosyada → onları kullan, sabit hex yazma.
4. Değişiklik light/dark temada ve 375px / 768px / 1200px'de nasıl görünecek → kanıt planı (Playwright screenshot).
5. `grep -i 'ui\|tema\|format\|telefon' C:/Users/BSA/Projects/BigBrain/lessons/INDEX.md` → rapora "Uygulanan dersler".

## Kurallar (BigBrain dersleri)

### Biçim (para / telefon)
- **L-0098** — Para: `formatMoney(n,{symbol})` tr-TR, DAİMA 2 hane "1.234,56"; `money()` = ₺ önde; girişte `parseMoney` (number input "1.234,56" gösteremez). Telefon: `PhoneInput` (+90 sabit, 3-3-2-2 maske, value E.164) + `normalizeTrPhone` (`wa.me` için); yalnız geçerli 10 haneli TR mobile. Her sayfanın kendi format'ını yazması YASAK; `wa.me/05…` yanlış link.

### Tema / karanlık mod
- **L-0088** — Koyu temada native `<select>` option'ları beyaz üstüne beyaz: tema `.dark`/`data-theme` ile uygulanırken CSS `color-scheme` light kalıyor. `color-scheme`'i temayı UYGULAYAN seçicilerle birebir hizala (`.dark` / `[data-theme=dark]` → `color-scheme: dark`; system-dark; `select option` renkleri).

### AI asistan UX
- **L-0071** — Yönlendirmeli cevap: sunucu sistem promptu cevabın SON satırına tek-satır JSON ekler (`{"navigate":{path,label},"auto":bool}`); istemci `parseNavigate` ile ayıklar, JSON yoksa metin aynen (geriye uyumlu). Güvenlik: yalnız `^/` iç path, `//`/host reddet (injection). `auto=true` iptal edilebilir geri sayımla. FAB: pointer events + `setPointerCapture`, >6px tap-vs-drag eşiği, konum localStorage + viewport clamp + `resize`, varsayılan alt ofset 96px (alt aksiyon çubuklarıyla çakışmasın). TTS varsayılan AÇIK, ayar (app_settings) okunamazsa açık; ~600 karakterde kes + "Devamı ekranda"; yeni mesajda `speechSynthesis.cancel()`. Test: parse/kısaltma saf-fonksiyon birim; e2e'de asistan cevabını `page.route` ile mock'la.

### Doğrulama
- **L-0021** — UI değişikliğini "hot restart edip umma"; build sonrası çalıştır, snapshot + etkileşim + screenshot kanıtı al; her etkileşim öncesi re-snapshot (refs stale olur). Görsel/test kanıtı olmadan "çalışıyor" deme (UI TESTİ ZORUNLU: headless Chromium/Playwright).

### Sık görülen belirtiler → hangi ders
- Tutarlar yerden yere farklı (kuruşsuz / 2 hane), `number` input "1.234,56" gösteremiyor → L-0098 / BLOK 24.
- DB'de telefon "05…/5…/+90…" karışık, `wa.me/05…` linki açılmıyor → L-0098 (E.164 normalize).
- Koyu temada dropdown beyaz üstüne beyaz, native kontrol açık zeminle çiziliyor → L-0088.
- Asistan FAB alt aksiyon çubuğunu kapatıyor; asistan sayfayı tarif ediyor ama götürmüyor → L-0071.
- "Değişiklik yapıldı" denildi ama ekranda yok; snapshot ref'leri stale → L-0021.
- Bileşende hardcoded Türkçe metin, tek düz renk kart, 44px altı dokunma hedefi → BLOK 17 / 20 / 7.

## v2.23'ten taşınan bloklar

### BLOK 24 — UI BİÇİM STANDARTLARI (para & telefon)
- Para: TEK KAYNAK `formatMoney(n,{symbol})` → tr-TR, DAİMA 2 hane "1.234,56" (binlik ".", kuruş ","); ₺ önde. Girişte `parseMoney` ("1.234,56" ve "1234.56" kabul), sunucuya ham number gider. `maximumFractionDigits:0` YASAK.
- Telefon: UI'da sabit görünür "+90" öneki + 3-3-2-2 maske ("532 377 85 20"); ortak `PhoneInput` bileşeni. DB'ye E.164 yazılır (+905323778520; baştaki 0/90/+90 temizlenir, 10 haneye kırpılır). `wa.me` linki E.164'ten üretilir. Mevcut kayıtlar `formatTrPhone(normalize(...))` ile gösterilir; toplu dönüşüm onaylı tek update.
- Bu biçimler TÜM görünen yerlerde geçerli: dashboard, listeler, PDF/makbuz, sözleşme, WhatsApp/e-posta metni.

### BLOK 20 — MATERIAL YOU TASARIM SİSTEMİ (Material Design 3; her yeni ve mevcut projede)
- `npm install @material/material-color-utilities` (pnpm projede `pnpm add`); seed color'dan `generateScheme()` ile tam palet üret.
- Dark + Light scheme token'ları CSS variables olarak yazılır.
- Tonal surface katmanları: surface, surfaceVariant, surfaceContainer.
- Yumuşak renk geçişleri, pastel tonlar — tek düz renk YASAK. Primary yumuşak/pastel ton, canlı primary rengi değil.
- Kartlar: surfaceContainer rengi (koyu modda koyu ton, açık modda açık ton).
- Rounded corners 16-28px ZORUNLU. Elevation yerine tonal color ile derinlik.
- Kontrast oranı min 4.5:1 ZORUNLU.
- Bouncy effect; clickable button.
- Proje seed renkleri: GhostX → #2d7a4f (koyu yeşil/teal); ADHD Killer Pro → #6750A4 (Material You varsayılan mor/indigo); EasyRide → #1565C0 (koyu mavi); BİLSAV → #1e1e78 (marka rengi); VoiceFlow → #37474F (koyu gri/slate).

### BLOK 11 — KARANLIK MOD
- `useColorScheme`; Açık/Karanlık/Sistem seçeneği; tercih persist edilir; tüm ekranlarda tutarlı. `color-scheme` tema seçicisiyle hizalı (L-0088).

### BLOK 17 — i18n
- Tüm UI string'leri dil dosyasından (`tr.json` / `en.json`); hardcoded metin YASAK. `useTranslation` hook. Varsayılan dil Türkçe. Yeni dil = yeni JSON dosyası.

### BLOK 8 — WEB
- Breakpoint'ler: 480 / 768 / 1200px. `max-width` container. Web fallback.
- Responsive layout; 768px breakpoint'te sidebar tam ekran geçişi.

### BLOK 7 — MOBİL (layout kısmı)
- `rs()`/`rFont()` 375px referans ölçekleme; dokunma hedefi min 44px; viewport meta.
- Platform algıla → farklı UX: mobilde native gibi (tam ekran, gesture, bottom nav), webde web gibi (sidebar, hover, geniş layout).
- Haptic feedback: tüm butonlarda `navigator.vibrate()`.

### Skill hatırlatması
- UI işi → **frontend-design** + **web-design-guidelines**; React/Next.js → **vercel-react-best-practices**; UI testi → **playwright-best-practices**. Kullanılan skill'i ve somut katkısını raporun "Kullanılan skill/agent" bölümüne yaz ("kullanılmadı" ise onu yaz, sessiz geçme).

## Rapora yazılacak
- `Uygulanan dersler: L-0021, L-0071, L-0088, L-0098` (gerçekten uygulananlar).
- Kanıt: Playwright screenshot (light + dark; 375px ve 768px+), `<select>` koyu temada okunur ekran görüntüsü, para/telefon örnek çıktıları ("₺1.234,56"; "+90 532 377 85 20" → DB "+905323778520"), i18n grep'inde hardcoded metin 0.
- Bölümler: Sonuç / Yapılanlar / Test / Varsayımlar / Proaktif notlar / Ders adayları / Kullanılan skill/agent.

Kaynak dersler: L-0021, L-0071, L-0088, L-0098
