GLOBAL CLAUDE.MD KURALLARI — v2.11

=== BÖLÜM A — HER ZAMAN GEÇERLİ (tetikleme gerektirmez) ===

SESSION BAŞLANGIÇ: Her yeni session'da "Global CLAUDE.md v2.11 aktif" bildir.

GÜNCELLEME: "CLAUDE.md güncelle" denildiğinde içeriği /home/user/.claude/CLAUDE.md'ye yaz (Windows path'i DEĞİL), head -1 ile doğrula.

TOKEN GÜVENLİK: Token ASLA chat'e/dosyaya yazılmaz. Gerekirse terminalde çalıştırılacak komut ver.

GİZLİ DOSYA: .env, credentials, API key ASLA commit edilmez. .gitignore zorunlu: node_modules/ .next/ .env .env.local dist/ build/ .DS_Store *.log coverage/

GITHUB ACTIONS: Workflow varsa manuel build komutu verme. Yoksa "ekleyelim mi?" sor. permissions: contents: write zorunlu.

İLETİŞİM: Kullanıcı hızlı/kısa yazar, sesli mesaj olabilir, TR-EN karışık. Emin değilsen sor, tahmin etme.

EKRAN GÖRÜNTÜSÜ: Gördüğünü özetle → teyit al → sonra aksiyon.

KOD GÜVENLİK: 3+ dosya değişikliğinde liste göster, onay al. Kritik dosya (config/auth/db/payment) tek bile olsa onay al.

PROJELER ARASI: Bir projede çözülen sorunu diğerine öner. Projeler: ADHD Killer, VoiceFlow, GhostX, BİLSAV PWA, EasyRide.

PLACEHOLDER YASAK: ASLA {VERSION} gibi placeholder bırakma, gerçek değer yaz. İstisna: shell variable (${PROJE_ADI}).

İNDİRME LİNKİ: Her versiyon değişiminde masaüstü→EXE/release linki, web→deploy linki ver. ASLA linksiz "hazır" deme.

YEDEK: "yedek al" denildiğinde seçenek sun (Git tag/ZIP/ikisi). ZIP yolu: /mnt/g/Drive'ım/AAA_Projeler/Aa Projeler Backup/

=== BÖLÜM B — TETİKLEMELİ (kullanıcı istediğinde) ===
Tetikleme: "global kurallara bak", "kuralları uygula", "eksikleri tara" vb.
Projede CLAUDE.md varsa → Blok 0 / Yoksa → Blok 1

BLOK 0 — ESKİ PROJE
0a: git log --oneline -30, git branch -a, git status → özet sun (feat/fix/docs/chore)
0b: Yedek öner (tag/ZIP/ikisi/gerek yok)
0c: Kabul ederse yedek al. Tag 403→token scope uyar.
0d: CLAUDE.md'yi global kurallarla karşılaştır→eksikleri listele→ONAY AL→uygula
0e: Durum raporu: özellikler, eksikler, diğer projelerdeki çözümler, bug/crash→"hangisiyle devam?" sor, seçene kadar DURMA

BLOK 0.5 — SKİLL ÖNERİLERİ
npx skills list ile kontrol et. Antigravity skill'leri:
planning→/concise-planning, debug→/systematic-debugging, react→/react-best-practices
supabase→/postgres-best-practices, güvenlik→/api-security-best-practices
git→/git-pushing, electron→/electron-development, n8n→/n8n-workflow-patterns
voice→/voice-ai-development, llm→/llm-app-patterns, chrome-ext→/chrome-extension-developer
pwa→/progressive-web-app

BLOK 1 — YENİ PROJE: PLATFORM
Mobil/Web/Masaüstü/Mobil+Web/Backend-API/CLI-Bot-Otomasyon

BLOK 2 — FİKİR TOPLAMA + TEKNOLOJİ
Kullanıcı anlatır→Claude sorar→"tamam" denince stack öner→onay al. README.md oluştur.

BLOK 3 — DEPLOY
Vercel(önerilen)/Netlify/EAS/GitHub Pages/VPS
YASAK: Vercel+SQLite, Vercel+execSync, Vercel+lokal DB → ZORUNLU: Vercel+Supabase(PostgreSQL)
Supabase org: giddtvgowtnloabwsvin, bölge: eu-west-2. Her proje ayrı Supabase projesi.
Duplicate deploy kontrolü yap.

BLOK 4 — VERSİYON
Semantic versioning. package.json'dan oku, tüm dosyalarda güncelle. Major öncesi ZIP yedek.

BLOK 5 — PR/MERGE
main'e direkt push YASAK. claude/branch→PR→merge. Conventional commit başlık. 3 bölüm: Özet/Dosyalar/Test. Boş PR yasak. Proje kuralı "sormadan merge yapma" diyorsa SOR.

BLOK 6 — BUILD/DEPLOY
Önce otomatik dene, yapamazsan komut ver. Actions varsa manuel komut verme. npx tsc --noEmit zorunlu.

BLOK 7 — MOBİL: rs()/rFont() 375px ref, dokunma 44px, viewport meta, platform algıla→farklı UX
BLOK 8 — WEB: Breakpoints 480/768/1200px, max-width container, web fallback
BLOK 9 — SES: playSound() her etkileşimde, kapatılabilir
BLOK 10 — OFFLİNE: AsyncStorage/MMKV, offline queue, bağlantı banner
BLOK 11 — KARANLIK MOD: useColorScheme, Açık/Karanlık/Sistem, persist
BLOK 12 — KVKK: Aydınlatma, sağlık verisi koruma, hesap silme hakkı
BLOK 13 — SUPABASE: Her tabloda RLS aktif, yeni tablo=RLS zorunlu
BLOK 14 — BİLDİRİM: Web Notification API / Native expo-notifications, kapatılabilir
BLOK 15 — DENEME SÜRESİ: 40 gün ücretsiz, iyzico ödeme, profilde kalan gün
BLOK 16 — ÇAKIŞMA: Global vs proje kuralı çakışırsa DUR→UYAR→SOR→kullanıcı karar verir
BLOK 17 — PWA: skipWaiting, cache temizleme, güncelleme bildirimi, iOS/Android/Desktop manifest, ikonlar 192+512
BLOK 18 — i18n: Tüm string'ler dil dosyasından (tr.json/en.json), hardcoded yasak, varsayılan TR
