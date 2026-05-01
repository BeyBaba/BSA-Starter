GLOBAL CLAUDE.MD KURALLARI — v2.13

=== BÖLÜM A — HER ZAMAN GEÇERLİ (tetikleme gerektirmez) ===

SESSION BAŞLANGIÇ: Her yeni session'da "Global CLAUDE.md v2.13 aktif" bildir.

EVRENSEL KURAL ÇEKME: Her yeni session'da bu dosyayı oku:
https://raw.githubusercontent.com/BeyBaba/BSA-Starter/main/GLOBAL_CLAUDE_MD.md
Erişilemezse kullanıcıya bildir, session'a devam et ama uyar.

GÜNCELLEME: "CLAUDE.md güncelle" denildiğinde içeriği C:\Users\BSA\.claude\CLAUDE.md'ye yaz, Get-Content ... | Select-Object -First 3 ile doğrula.

TOKEN GÜVENLİK: Token ASLA chat'e/dosyaya yazılmaz. Gerekirse terminalde çalıştırılacak komut ver.

GİZLİ DOSYA: .env, credentials, API key ASLA commit edilmez. .gitignore zorunlu:
node_modules/ .next/ .env .env.local dist/ build/ .DS_Store *.log coverage/

GITHUB ACTIONS: Workflow varsa manuel build komutu verme. Yoksa "ekleyelim mi?" sor. permissions: contents: write zorunlu.

İLETİŞİM: Kullanıcı hızlı/kısa yazar, sesli mesaj olabilir, TR-EN karışık. Emin değilsen sor, tahmin etme.

EKRAN GÖRÜNTÜSÜ: Gördüğünü özetle → teyit al → sonra aksiyon.

KOD GÜVENLİK: 3+ dosya değişikliğinde liste göster, onay al.
KRİTİK DOSYA ONAYI: Şu dosyalara tek dosya bile olsa dokunmadan önce onay al:
auth/login flow, DB şeması/migration, payment/ödeme, secret management, CI/CD pipeline, production config.

PROJELER ARASI: Bir projede çözülen sorunu diğerine öner. Projeler: ADHD Killer, VoiceFlow, GhostX, BİLSAV PWA, EasyRide.

PLACEHOLDER YASAK: ASLA {VERSION} gibi placeholder bırakma, gerçek değer yaz. İstisna: shell variable (${PROJE_ADI}).

İNDİRME LİNKİ: Her versiyon değişiminde masaüstü→EXE/release linki, web→deploy linki ver. ASLA linksiz "hazır" deme.

YEDEK: "yedek al" denildiğinde seçenek sun (Git tag/ZIP/ikisi). ZIP yolu: D:\BSA Proje Yedekler

OTONOM GİT AKIŞI: Kodlama görevlerinde her adım için ayrı onay bekleme.
Akış: branch → commit → push → PR → semver bump → Türkçe commit mesajı → CI yeşil → merge.
Tek zorunluluk: build + typecheck temiz olmadan push YOK.

PR ZORUNLULUĞU: main branch'e direkt push YASAK. Her zaman PR üzerinden squash merge.

DESTRUCTİVE İŞLEM ONAYI: Şunlar için MUTLAKA açık kullanıcı onayı al:
force-push, reset --hard, branch silme, rm -rf, DB drop, üretim verisi değişikliği, sürüm geri alma, --no-verify.

DÜRÜSTLÜK ÖNCELİKLİ GELİŞTİRME:
- PWA'da teknik olarak YAPILAMAYAN özellik (Tor, BLE, WiFi Direct, OS-level screenshot block vb.) ASLA arayüze eklenmez.
- Her özellik eklendiğinde "Bu gerçekten çalışıyor mu?" sorusuna kanıtla (test/log/ekran görüntüsü).
- Kod yazıldı ama aktif edilmediyse: "DİKKAT: Bu modül yazıldı ama aktif değil, aktivasyon için şu adımlar lazım..."
- ASLA "bitti" deme, özellik test edilip doğrulanmadıysa.
- Platform kısıtı varsa (web vs native) EN BAŞTA söyle.
- Arayüzde toggle/buton/gösterge varsa, arkasında gerçek çalışan kod OLMALIDIR. Sadece UI olan özellik YASAKTIR.
- Özellik tamamlandığında rapor formatı:
  ✅ ÇALIŞIYOR: [özellik adı] — [test kanıtı]
  ⚠️ YAZILDI AMA AKTİF DEĞİL: [özellik adı] — [aktivasyon adımları]
  ❌ BU PLATFORMDA İMKANSIZ: [özellik adı] — [neden + hangi platformda yapılabilir]

VERSİYON GÖRÜNÜRLÜĞܺÜ Her projede kullanıcı-yüzlü bir yerde (login/landing/about ekranı) vX.Y.Z etiketi göster.
Versiyon tek doğruluk kaynağından (package.json veya eşdeğer) otomatik okunsun — elle senkron tutma yok.
Görünüm: küçük, diskret, monospace, textMuted renk.

KURAL SENKRONİZASYONU: Herhangi bir projede kural değiştiğinde:
"Bu kuralı tüm projeler için geçerli kılayım mı? Global CLAUDE.md'ye ekleyeyim mi?" diye sor.

ÇAKIŞMA YÖNETİMİ: Global vs proje kuralı çakışırsa DUR → UYAR → SOR → kullanıcı karar verir.

=== BÖLÜM B — TEKNOLOJİ STACK KURALLARI ===

ZORUNLU STACK:
- Frontend: Next.js 15 + TypeScript + Tailwind CSS + shadcn/ui
- Backend: Supabase (PostgreSQL) — ZORUNLU
- Deploy: Vercel — ZORUNLU
- Supabase org: giddtvgowtnloabwsvin | Region: eu-west-2
- SQLite + execSync YASAK. Vercel + SQLite YASAK. Vercel + lokal DB YASAK.
- Her proje ayrı Supabase projesi. Duplicate deploy kontrolü yap.

ÇALIŞMA MODU:
- Her işlemde izin isteme, direkt yap.
- Dosya oluştur, düzenle, sil — onay bekleme.
- Bash komutları çalıştır — onay bekleme.
- Sadece DESTRUCTİVE işlemlerde (yukarıdaki liste) sor.

YENİ PROJE:
- github.com/BeyBaba/BSA-Starter → "Use this template" kullan. ASLA sıfırdan başlama.
- İlk push sonrası CLAUDE.md otomatik gelir.

=== BÖLÜM C — TETİKLEMELİ (kullanıcı istediğinde) ===
Tetikleme: "global kurallara bak", "kuralları uygula", "eksikleri tara" vb.

BLOK 0 — ESKİ PROJE
0a: git log --oneline -30, git branch -a, git status → özet sun
0b: Yedek öner (tag/ZIP/ikisi/gerek yok)
0c: Kabul ederse yedek al. Tag 403→token scope uyar.
0d: CLAUDE.md'yi global kurallarla karşılaştır → eksikleri listele → ONAY AL → uygula
0e: Durum raporu — her özelliği sınıfla:
  ✅ ÇALIŞIYOR — test edildi, aktif
  ⚠️ KOD VAR AMA AKTİF DEĞİL — aktivasyon adımlarını listele
  ❌ BU PLATFORMDA İMKANSIZ — kaldır veya native roadmap'e taşı
  Arada kalan kod bırakma. Ya aktif et, ya kaldır, ya roadmap'e taşı.

BLOK 0.5 — SKİLL ÖNERİLERİ
npx skills list ile kontrol et:
planning→/concise-planning, debug→/systematic-debugging, react→/react-best-practices
supabase→/postgres-best-practices, güvenlik→/api-security-best-practices
git→/git-pushing, electron→/electron-development, n8n→/n8n-workflow-patterns
voice→/voice-ai-development, llm→/llm-app-patterns, chrome-ext→/chrome-extension-developer
pwa→/progressive-web-app

BLOK 1 — YENİ PROJE: PLATFORM
Mobil/Web/Masaüstü/Mobil+Web/Backend-API/CLI-Bot-Otomasyon

BLOK 2 — FİKİR TOPLAMA + TEKNOLOJİ
Kullanıcı anlatır → Claude sorar → "tamam" denince stack öner → onay al. README.md oluştur.
Her istenen özelliği sınıfla:
  ✅ BU PLATFORMDA YAPILABİLİR — hemen dahil et
  ❌ NATİVE GEREKTİRİR — arayüze KOYMA, NATIVE_ROADMAP.md'ye yaz

BLOK 3 — DEPLOY
Vercel(önerilen)/Netlify/EAS/GitHub Pages/VPS
YASAK: Vercel+SQLite, Vercel+execSync, Vercel+lokal DB
ZORUNLU: Vercel+Supabase(PostgreSQL)

BLOK 4 — VERSİYON
Semantic versioning (major.minor.patch). package.json'dan oku, tüm dosyalarda güncelle. Major öncesi ZIP yedek.
GitHub Releases: her versiyon geçişinde release oluştur, changelog yaz.

BLOK 5 — PR/MERGE
main'e direkt push YASAK. claude/branch → PR → squash merge.
Conventional commit (feat:/fix:/chore:/docs:) + Türkçe açıklama.
3 bölüm: Özet / Değişen Dosyalar / Test. Boş PR yasak.

BLOK 6 — BUILD/DEPLOY
npx tsc --noEmit zorunlu. Önce otomatik dene, yapamazsan komut ver.

BLOK 7 — MOBİL
rs()/rFont() 375px ref, dokunma hedefi min 44px, viewport meta, zoom engelleme.
Platform algıla → farklı UX: mobilde native gibi (tam ekran, gesture, bottom nav), webde web gibi (sidebar, hover, geniş layout).
Haptic feedback: tüm butonlarda navigator.vibrate().

BLOK 8 — WEB
Breakpoints: 480/768/1200px. max-width container. web fallback.
Responsive layout, 768px breakpoint, sidebar tam ekran geçişi.

BLOK 9 — SES
playSound() her etkileşimde, kapatılabilir toggle.

BLOK 10 — OFFLİNE
navigator.onLine kontrolü, offline uyarı banner, mesaj kuyruğu, online olunca senkronize.

BLOK 11 — KARANLIK MOD
useColorScheme, Açık/Karanlık/Sistem seçeneği, persist, tüm ekranlarda tutarlı.

BLOK 12 — KVKK
Aydınlatma metni, sağlık verisi koruma, hesap silme hakkı.

BLOK 13 — SUPABASE
Her tabloda RLS aktif. Yeni tablo = RLS zorunlu.

BLOK 14 — BİLDİRİM
Web Notification API / Native expo-notifications, kapatılabilir.

BLOK 15 — DENEME SÜRESİ & ÖDEME
40 gün ücretsiz deneme, profilde kalan gün göstergesi.
Ödeme entegrasyonu: iyzico (Türkiye) + Stripe (global) — ikisi birlikte desteklenmeli.
savasarac@gmail.com SUPER USER: deneme süresi YOK, otomatik LİFETİME üye.
Super user kontrolü her projede auth/payment koduna EKLENMELIDIR.

BLOK 16 — PWA
skipWaiting aktif, eski cache temizleme, güncelleme bildirimi, cache versiyonlama.
iOS Safari: apple-mobile-web-app meta tag'leri, apple-touch-icon.
Android Chrome + Desktop: standalone mode.
İkonlar: PNG/SVG 192x192 ve 512x512. manifest.json zorunlu.
"Ana Ekrana Ekle" tüm platformlarda çalışmalı.

BLOK 17 — i18n
Tüm UI string'leri dil dosyasından (tr.json / en.json). Hardcoded metin yasak.
useTranslation hook. Varsayılan: Türkçe. Yeni dil = yeni JSON dosyası.

BLOK 18 — SUPER USER KURALI
savasarac@gmail.com hesabı SUPER USER'dir.
Rate limit, plan kısıtlaması, trial süresi, ödeme ekranı bu hesap için GEÇERLİ DEĞİLDİR.
Super user girişinde otomatik LİFETİME plan atanır — ödeme adımı atlanır.
Bu kural TÜM projelerde geçerlidir (iyzico veya Stripe entegrasyonu olsun olmasın).
Yeni proje oluşturulurken auth/payment koduna super user bypass EKLENMELIDIR.
Super user listesi: desktop-app/ui/home.html içinde SUPER_USERS array'inde tanımlı.

BLOK 19 — README
Her projede README.md zorunlu: proje açıklaması, kurulum, özellikler listesi, teknoloji stack'i.

BLOK 20 — MATERIAL YOU TASARIM SİSTEMİ
Her yeni proje ve mevcut projelerde Material Design 3 uygulanır:
- npm install @material/material-color-utilities
- Seed color'dan generateScheme() ile tam palet üret
- Dark + Light scheme token'larını CSS variables olarak yaz
- Tonally surface'ler: surface, surfaceVariant, surfaceContainer katmanları
- Yumuşak renk geçişleri, pastel tonlar — tek düz renk YASAK
- Primary: yumuşak/pastel ton, canlı primary rengi değil
- Kartlar: surfaceContainer rengi (koyu modda koyu ton, açık modda açık ton)
- Rounded corners: 16-28px ZORUNLU
- Elevation yerine tonal color ile derinlik
- Kontrast oranı min 4.5:1 ZORUNLU
- Her proje için seed color:
  GhostX → #2d7a4f (koyu yeşil/teal)
  ADHD Killer Pro → #6750A4 (Material You varsayılan mor/indigo)
  EasyRide → #1565C0 (koyu mavi)
  BİLSAV → #1e1e78 (marka rengi)
  VoiceFlow → #37474F (koyu gri/slate)

  $addition = @'

BLOK 21 — PWA GÜNCELLEME BİLDİRİMİ
Her PWA projesinde service worker güncelleme bildirimi ZORUNLU:
- Service worker yeni versiyon tespit edince kullanıcıya toast/banner göster
- Mesaj: "🆕 Yeni güncelleme mevcut! Yenilemek için tıkla"
- Tıklanınca: skipWaiting() + clients.claim() + window.location.reload()
- Cache versiyonlama: CACHE_NAME = 'app-v{versiyon}' formatı
- Yeni deploy = eski cache otomatik temizlenir
- Güncelleme bildirimi dismiss edilemez — kullanıcı MUTLAKA güncellemeli
- Güncelleme bildirimi her sayfada görünür (fixed, üstte veya altta)
- Arka plan karartılır, sadece "Güncelle" butonu aktif (modal stili)
'@

Add-Content -Path "$env:USERPROFILE\.claude\CLAUDE.md" -Value $addition -Encoding UTF8
Get-Content "$env:USERPROFILE\.claude\CLAUDE.md" | Select-Object -Last 5
