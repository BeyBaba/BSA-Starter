GLOBAL CLAUDE.MD KURALLARI — v2.23

=== BÖLÜM A — HER ZAMAN GEÇERLİ (tetikleme gerektirmez) ===

SESSION BAŞLANGIÇ: Her yeni session'da "Global CLAUDE.md v2.23 aktif" bildir.

ZORUNLU SKİLL/MCP SETİ (v2.22): Aşağıdaki araçlar her session'da kurulu ve AKTİF olmalı. Hepsi
user scope'ta kuruludur (2026-09-21). Session başında `claude plugin list` + `claude mcp list` +
`npx skills list` ile kontrol et; eksik varsa aşağıdaki komutla SESSİZCE yeniden kur, kullanıcıya sorma.

MCP:
- context7 → kütüphane API'si yazmadan önce güncel doküman. `claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp`
- memory / sequential-thinking / filesystem → `claude mcp add --scope user <ad> -- cmd /c npx -y @modelcontextprotocol/server-<ad>` (Windows: stdio MCP'ler cmd /c npx ile sarılır; uzak HTTP varsa --transport http tercih et)

PLUGIN (claude plugin install <ad>@<marketplace> --scope user):
- superpowers@superpowers-marketplace → brainstorming, writing-plans, TDD, systematic-debugging, verification-before-completion, dispatching-parallel-agents, subagent-driven-development, using-git-worktrees
- episodic-memory@superpowers-marketplace → geçmiş session'larda semantik arama (SessionStart hook otomatik indeksler)
- double-shot-latte@superpowers-marketplace → gereksiz "devam edeyim mi?" duraklamalarını kaldırır (jq gerekir, kurulu)
- feature-dev@claude-plugins-official → /feature-dev: code-explorer → code-architect → code-reviewer agent akışı
- code-review@claude-plugins-official → /code-review: paralel uzman agent'larla PR incelemesi, güven skoru
- pr-review-toolkit@claude-plugins-official → /review-pr: test/sessiz hata/tip tasarımı/yorum reviewer agent'ları
- security-guidance@claude-plugins-official → düzenleme sırasında güvenlik pattern uyarısı, commit öncesi secret taraması (hook)
- hookify@claude-plugins-official → /hookify: konuşmadaki kuralları gerçek hook'a çevirir
- claude-code-setup@claude-plugins-official → projeyi tarayıp hook/skill/subagent önerir
- typescript-lsp@claude-plugins-official → TS kod zekası (global typescript-language-server gerekir, kurulu)
Marketplace'ler: claude-plugins-official (varsayılan), obra/superpowers-marketplace (`claude plugin marketplace add obra/superpowers-marketplace`)

SKILL (npx -y skills add <repo> -s <skill> -a claude-code -g -y --copy; ~/.claude/skills altına kopyalanır):
- frontend-design (claude.ai skill, kurulu) → her UI/arayüz işinde
- supabase/agent-skills → supabase, supabase-postgres-best-practices (BLOK 13 ile birebir)
- vercel-labs/agent-skills → vercel-react-best-practices, vercel-composition-patterns, web-design-guidelines
- currents-dev/playwright-best-practices-skill → playwright-best-practices (UI TESTİ ZORUNLU kuralı için)

KULLANIM ZORUNLULUĞU: UI işi → frontend-design + web-design-guidelines; React/Next.js kodu → vercel-react-best-practices;
Supabase/SQL → supabase-postgres-best-practices + CANLI ŞEMA; Playwright → playwright-best-practices;
yeni özellik → superpowers brainstorming → writing-plans → /feature-dev veya subagent-driven-development;
PR → /code-review + /review-pr; bug → systematic-debugging; bitiş → verification-before-completion.

SKİLL KULLANIM BİLDİRİMİ (v2.22): Her görev raporunun sonunda "🧰 Kullanılan skill/plugin" bölümü ZORUNLU:
hangi skill/plugin/MCP kullanıldı ve somut olarak ne kattı (örn. "context7: Next.js 15 cache API'si
değişmişti, eski imzayı kullanmaktan kurtardı"). Hiçbiri kullanılmadıysa "kullanılmadı" yaz — sessiz geçme.

PROAKTİFLİK (v2.22): Kullanıcı "proaktif ol" der ve bunun unutulmasından şikayetçidir.
Her görevde, istenen işi bitirdikten sonra: (1) işe yarayacak skill/plugin/MCP'yi kendiliğinden öner,
(2) fark edilen yan sorunları (bağlanmayan MCP, sürüm drift'i, eksik test) sorulmadan raporla,
(3) çoklu ajan (paralel subagent / worktree) kullanılabilecek işi kendin öner ve uygula.
Sormadan öneri getirmek kural; öneriyi uygulamak için onay yeterli.

RAPOR ŞABLONU (v2.23): Claude Code her görev sonunda rapor dosyasına ZORUNLU bölümler yazar:
Proaktif notlar, Ders adayları (inbox dosya adları), Kullanılan skill/agent. Sohbete yazılan öneri
raporda da olmalı; Claude.ai yalnız rapor dosyasını okur (sohbeti göremez).

ÇOKLU AJAN (v2.23): 3+ birbirinden bağımsız dosya/konu içeren görevde paralel subagent kullan
(BLOK 22 dosya sahipliği kuralıyla); tek dosyaya dokunan işler sıralı. Rapora hangi ajanın neyi yaptığını yaz.

HAFIZA OKUMA (v2.23): Yeni özelliğe başlamadan `grep -i '<konu anahtar kelimesi>'
C:/Users/BSA/Projects/BigBrain/lessons/INDEX.md` çalıştır; eşleşen dersleri rapora "Uygulanan dersler" olarak yaz.

EVRENSEL KURAL ÇEKME: Her yeni session'da bu dosyayı oku:
https://raw.githubusercontent.com/BeyBaba/BSA-Starter/main/GLOBAL_CLAUDE_MD.md
Erişilemezse kullanıcıya bildir, session'a devam et ama uyar.

HAFIZA TEK KAYNAĞI (v2.14): Tüm projeler-arası hafıza tek repoda: BeyBaba/BigBrain.
Her yeni session'da BigBrain/projects/INDEX.md + BigBrain/lessons/INDEX.md oku;
geçmiş projelerden çıkarılmış dersleri (L-XXXX) dikkate al ve aynı hatayı tekrarlama.
Bu dosyalara erişilemezse tek satır bildir ("⚠️ Hafıza okunamadı, devam ediyorum") ve
session'a devam et — ASLA bloklama. Ayrı Claude-Memory / Unified-Learning-System reposu tutma (bunlar eski hafıza repolarıydı — arşivlendi).

DERS YAZ — GERİ YAZMA (v2.15): Hafıza tek yönlü değil. Önemli bir bug/çözüm, tekrar eden bir
hata ya da genelleştirilebilir bir karar çıktığında oturum sonunda BigBrain/lessons'a yeni
bir L-XXXX kaydı ekle ve lessons/INDEX.md'yi güncelle (kısa: belirti → kök neden → kural/çözüm).
Aynı dersi iki kez yazma — varsa güncelle. Bu adım TÜM projelerde geçerlidir; okuma otomatik
(hook), yazma bu kuralla sağlanır.

RETROAKTİF KURAL UYARISI (v2.14): Yeni bir global kural (yazıldığı sürümden eski) bir
projede sağlanmıyorsa KENDİLİĞİNDEN düzeltme YAPMA. Tek satır uyar ve onay iste:
"⚠️ Bu proje eski kural sürümüyle yazılmış; v2.14 şu maddeleri ekledi: [liste]. Uygulayayım mı?"
Kullanıcı onaylamadan dokunma.

GÜNCELLEME: "CLAUDE.md güncelle" denildiğinde içeriği C:\Users\BSA\.claude\CLAUDE.md'ye yaz, Get-Content ... | Select-Object -First 3 ile doğrula.

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

OTONOM MERGE (v2.15): Testten (build + typecheck + UI testi) geçen PR'ı kullanıcıya
sormadan squash merge et. Yalnızca emin olunamayan / mimari kararlarda dur ve danış.

UI TESTİ ZORUNLU (v2.15): Her UI/davranış değişikliğinde headless Chromium (Playwright) ile
testi çalıştır; mümkünse ekran görüntüsüyle doğrula. Görsel/test kanıtı olmadan "çalışıyor" deme.

PR ZORUNLULUĞU: main branch'e direkt push YASAK. Her zaman PR üzerinden squash merge.

GİT HİJYENİ (v2.14): `git add` öncesi her zaman `git status` ile neyin stage'lendiğini kontrol et.
Agent scratch/worktree klasörlerini (.claude/worktrees/, .od/, .tmp/, Playwright raporları) ASLA
commit etme; yanlışlıkla eklendiyse `git rm --cached` ile çıkar.

MEVCUT KODU OKU (v2.14): Yeni feature/fix'e başlamadan önce `grep -rn` ile ilgili kodu tara,
gerçek durumu tespit et. Stale roadmap/TODO'ya körü körüne güvenme — "zaten yapılmış" işi
tekrar yapma. Her merge sonrası roadmap'i güncel tut.

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

DEBUG RAPOR FORMATI (v2.15): Bir bug çözüldüğünde şu başlıklarla raporla:
  - Bug neydi ve neden oluyordu
  - Çözüm
  - Kanıt (test/log/ekran görüntüsü)
  - Test geçti, kuralımız gereği merge ediyorum (OTONOM MERGE'e göre)
  - Bu turda çözülenler (kısa özet liste)

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
- PAKET YÖNETİMİ (v2.14): Vercel pnpm + frozen-lockfile kullanır. Paket eklerken `pnpm install`
  ile package.json + pnpm-lock.yaml'ı BİRLİKTE commit et. Sadece package-lock.json commit etme →
  build ERR_PNPM_OUTDATED_LOCKFILE ile patlar. npm kullanıldıysa sonra `pnpm install --lockfile-only` çalıştır.

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

İSTİSNA KATEGORİLERİ (v2.20):
Aşağıdaki kategorilerdeki repolar "Next.js+Supabase zorunlu" kuralından MUAFTIR.
Bu repolarda stack uyumsuzluğu uyarısı ÜRETILMEZ.

  KATEGORİ DIŞI: Çalışır uygulama barındırmayan repolar (doküman, şablon, skill, arşiv)
  için stack kuralı GEÇERSİZDİR.
  Örnekler: BigBrain, BSA-Starter, ui-ux-pro-max-skill_06062006

  PLATFORM UYUMSUZ: Masaüstü (Electron) ve native mobil (React Native/Expo) projeler
  için Next.js+Vercel GEÇERSİZDİR; Supabase opsiyoneldir.
  Örnekler: VoiceFlow (Electron), ADHD-Killer-Pro-Project (Expo/RN), open-design (Electron)

  BSA DIŞI: BSA_SCOPE=false işaretli upstream/açık kaynak repolar için
  tüm global kurallar GEÇERSİZDİR; upstream proje kuralları geçerlidir.
  Örnek: omi

BLOK 4 — VERSİYON
Semantic versioning (major.minor.patch). package.json'dan oku, tüm dosyalarda güncelle. Major öncesi ZIP yedek.
GitHub Releases: her versiyon geçişinde release oluştur, changelog yaz.
ÇİFT HANELİ MİNÖR YOK (v2.15): Minör 9'a geldiyse (örn. 1.9.x) sonraki özellik sürümü
1.10.0 DEĞİL, doğrudan bir üst BÜYÜK olur (örn. 2.0.0). Boşuna/simgesel sürüm çıkarma —
sürümü gerçek bir değişiklikle çıkar. Kararsız kaldığında sürüm tipini kullanıcıya sor.

BLOK 5 — PR/MERGE
main'e direkt push YASAK. claude/branch → PR → squash merge.
Conventional commit (feat:/fix:/chore:/docs:) + Türkçe açıklama.
3 bölüm: Özet / Değişen Dosyalar / Test. Boş PR yasak.

BLOK 6 — BUILD/DEPLOY
npx tsc --noEmit zorunlu. Önce otomatik dene, yapamazsan komut ver.

BLOK 7 — MOBİL
rs()/rFont() 375px ref, dokunma hedefi min 44px, viewport meta.
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
RLS + UPSERT (v2.14): PostgREST'in doğrudan upsert'i (on_conflict + resolution=merge-duplicates)
RLS WITH CHECK'e takılıp 401 verir. İstemci yazmalarını SECURITY DEFINER RPC ile yap; istemci
anon anahtarını kullanır, tabloya doğrudan değil RPC üzerinden yazar.
SERVICE ROLE KEY (v2.14): SUPABASE_SERVICE_ROLE_KEY yalnızca server-side; ASLA NEXT_PUBLIC_*
altında veya client bundle'da değil, ASLA commit edilmez — aksi halde RLS tümüyle bypass edilir.
CANLI ŞEMA (v2.14): Yeni feature/fix öncesi `select column_name from information_schema.columns
where table_name='X'` ile CANLI DB şemasına bak; repo migration'ları canlı şemadan drift etmiş
olabilir. Production DB'yi elle değiştirme — sadece migration dosyaları üzerinden.

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
iOS PUSH/NOTIFICATION (v2.14): iOS Safari'de Web Push/Notification yalnızca PWA "Ana Ekrana Ekle"
sonrası çalışır; izin isteği bir kullanıcı dokunuşuyla tetiklenmeli. Önce IosInstallPrompt akışını
göster, sonra permission flow'u çalıştır.
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
Her yeni proje ve mevcut projelerde Material U Design 3 uygulanır:
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
- Bouncy effect
- Clickable button
  GhostX → #2d7a4f (koyu yeşil/teal)
  ADHD Killer Pro → #6750A4 (Material You varsayılan mor/indigo)
  EasyRide → #1565C0 (koyu mavi)
  BİLSAV → #1e1e78 (marka rengi)
  VoiceFlow → #37474F (koyu gri/slate)


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
- PUSH POLİTİKASI (v2.15): Kapalıyken gönderilen "yeni sürüm" push'u yalnızca ORTA/BÜYÜK
  (minor/major) sürümlerde atılır. KÜÇÜK (patch) sürümlerde push GÖNDERME — patch yalnızca
  açılıştaki görünür güncelleme modaliyle duyurulur. Sebep: sık deploy'da her patch'te push
  kullanıcıyı bunaltır ve bildirimleri komple kapattırır (asıl bildirimler de kaybolur).
- Görünür güncelleme modali HER sürümde, bildirim izninden BAĞIMSIZ gösterilir.


BLOK 22 — OTOMATİK RELEASE VE SEMVER KURALI (v2.17)
Her anlamlı değişiklik grubu (yeni özellik, bug fix, refactor) tamamlandığında:
1. Conventional commit at (feat:/fix:/chore:/refactor:/docs:/test:)
2. package.json versiyonunu semver'e göre yükselt:
   - Başlangıç kuralı: Her yeni proje veya MVP'ye ulaşmış proje 1.0.0'dan başlar.
     0.x sürümleri yalnızca ilk 3 gün deneme aşamasında geçici kabul.
   - feat: -> MINOR bump (1.0.0 -> 1.1.0)
   - fix: -> PATCH bump (1.0.0 -> 1.0.1)
   - BREAKING CHANGE: footer -> MAJOR bump (1.0.0 -> 2.0.0)
   - Sadece docs:/test:/refactor: -> versiyon bump YOK
3. CHANGELOG.md'ye Keep a Changelog formatında ekle
4. main'e DOĞRUDAN push YASAK — feature branch -> PR -> kullanıcıya URL
5. PR merge sonrası: git tag vX.Y.Z, push, gh release create
6. auto-release skill'i varsa onu kullan
7. Kullanıcıya release özeti göster
İstisna YOK. Kural sabittir.


BLOK 23 — CLAUDE AI / CLAUDE CODE OTURUM SÜREKLİLİĞİ (v2.19)

⚠️ POWERSHELL KURALI: Windows PowerShell 5.1'de `&&` operatörü ÇALIŞMAZ.
Çok adımlı komutlar asla `&&` ile birleştirilmez; her komut ayrı satır
(veya gerekiyorsa `;`) olarak verilir. Bu kural tüm talimat, doküman ve
hook çıktıları için geçerlidir.

Claude.ai ve Claude Code arasinda baglam surekliligi:

1. YENİ CLAUDE CODE SESSION BAŞLANGİCI:
   Her yeni terminal session'inda iki adim:
   cd C:\Users\BSA\Projects\BigBrain
   claude --dangerously-skip-permissions
   Bu sayede bypass permissions ve BigBrain hook'lari otomatik aktif olur.

2. CLAUDE CODE SESSION SONU RAPORU (Claude Code bu formati oturum sonunda uretir):
   === BigBrain SESSION OZET ===
   Repo: <calisilan repo>
   Yapilan: <1-3 cumle ozet>
   PR'lar: <PR linkleri>
   Inbox adaylari: <varsa slug listesi, yoksa "yok">
   Sonraki adim: <varsa bekleyen is, yoksa "yok">
   === OZET SONU ===
   Kullanici bu ozeti Claude.ai'ya yapistirinca baglam aninda kurulur.

3. CLAUDE.AI PROJE İZOLASYONU:
   Her Claude.ai projesi kendi sohbet adasinda izole. Cross-project arama yapilamiyor.
   B3 madenciligi (Claude.ai ders tarama) her projenin kendi session'inda yapilmali.
   Yeni proje acilirken BigBrain devir notunu knowledge olarak ekle.

4. CLAUDE.MD SCRIPT KALINTISI KONTROLÜ:
   Her CLAUDE.md duzenlemesinden sonra zorunlu kontrol:
   Select-String -Path CLAUDE.md -Pattern 'Add-Content|Get-Content|\$addition'
   Bos donmeli. Doluysa satiri sil (L-0026 ve L-0044+ dersleriyle baglantili).


BLOK 24 — UI BİÇİM STANDARTLARI (para & telefon) (BigBrain L-0098)
- Para: TEK KAYNAK formatMoney(n,{symbol}) → tr-TR, DAİMA 2 hane "1.234,56" (binlik ".", kuruş ","); ₺ önde.
  Girişte parseMoney ("1.234,56" ve "1234.56" kabul), sunucuya ham number gider. maximumFractionDigits:0 YASAK.
- Telefon: UI'da sabit görünür "+90" öneki + 3-3-2-2 maske ("532 377 85 20"); ortak PhoneInput bileşeni.
  DB'ye E.164 yazılır (+905323778520; baştaki 0/90/+90 temizlenir, 10 haneye kırpılır). wa.me linki E.164'ten üretilir.
  Mevcut kayıtlar görüntülenirken formatTrPhone(normalize(...)) ile gösterilir; toplu dönüşüm onaylı tek update.
- Bu biçimler TÜM görünen yerlerde geçerli (dashboard, listeler, PDF/makbuz, sözleşme, WhatsApp/e-posta metni).


=== SÜRÜM GEÇMİŞİ ===

v2.23 — BÖLÜM A: RAPOR ŞABLONU (zorunlu rapor bölümleri) + ÇOKLU AJAN (3+ bağımsız → paralel subagent) + HAFIZA OKUMA (INDEX grep) eklendi; BLOK 24 UI biçim standardı (para/telefon) BigBrain mirror'ıyla birleştirildi.
v2.22 — ZORUNLU SKİLL/MCP SETİ tam listeye genişletildi (10 plugin + 6 skill + 4 MCP, kurulum komutları, kullanım eşlemesi); SKİLL KULLANIM BİLDİRİMİ zorunlu bölüm eklendi.
v2.21 — ZORUNLU SKİLL/MCP SETİ (frontend-design + context7 + superpowers, session başı kontrol) ve PROAKTİFLİK kuralı eklendi; Windows MCP transport notu.
v2.20 — BLOK 3 İstisna Kategorileri eklendi: KATEGORİ DIŞI (doküman/şablon/skill repoları), PLATFORM UYUMSUZ (Electron/React Native), BSA DIŞI (BSA_SCOPE=false); bu repolarda "Next.js+Supabase zorunlu" uyarısı üretilmez.
v2.19 — BLOK 23: PowerShell && düzeltmesi; oturum başlatma komutu iki ayrı satıra bölündü, && yasağı kalıcı kural olarak eklendi.
