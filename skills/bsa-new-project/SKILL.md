---
name: bsa-new-project
description: Yeni bir BSA projesi açılırken ("yeni proje", "Use this template", "stack öner") veya eski bir proje global kurallara göre taranırken ("global kurallara bak", "kuralları uygula", "eksikleri tara") tetiklenir; zorunlu stack, platform, deploy istisnaları, KVKK, ödeme/deneme ve super user kurallarını uygular.
---
# bsa-new-project — Yeni proje açılışı ve eski proje denetimi

## Ne zaman
- Kullanıcı "yeni proje", "proje aç", "Use this template", "stack öner", "platform seç" dediğinde.
- Kullanıcı "global kurallara bak", "kuralları uygula", "eksikleri tara" dediğinde (BÖLÜM C tetiklemesi → BLOK 0).
- Mevcut projede auth/payment/deploy kurulumu yapılırken (super user bypass, iyzico+Stripe, Vercel+Supabase).
- Repo `BSA_SCOPE = false` ise veya İSTİSNA KATEGORİLERİ'ne giriyorsa stack uyarısı ÜRETME (aşağıda).

## Görev başı kontrol listesi
1. `grep -i '<konu>' C:/Users/BSA/Projects/BigBrain/lessons/INDEX.md` → eşleşen dersleri "Uygulanan dersler" olarak not al.
2. Proje CLAUDE.md'sindeki `BSA_SCOPE` satırını oku; `false` ise tüm global kurallar geçersiz, upstream kuralları uygula.
3. Repoyu sınıfla: normal BSA uygulaması / KATEGORİ DIŞI / PLATFORM UYUMSUZ / BSA DIŞI.
4. Eski projeyse BLOK 0 (0a → 0e); yeni projeyse YENİ PROJE → BLOK 1 → BLOK 2 → BLOK 3 sırası.
5. Projenin yazıldığı kural sürümü ile v2.23'ü karşılaştır → RETROAKTİF KURAL UYARISI (kendiliğinden düzeltme yok).
6. Duplicate deploy kontrolü: Vercel'de (`vercel project ls` veya Vercel MCP list_projects) ve Supabase'de (`npx supabase projects list` veya Supabase MCP list_projects) aynı adla proje var mı.
7. Mevcut kodu oku: `gh pr list`, `git branch -a`, `grep -rn` (L-0092) — "yeni" sanılan iş çoktan yapılmış olabilir.

## Kurallar (BigBrain dersleri)
- **L-0001** — Vercel serverless'ta SQLite / lokal dosya DB / `execSync` çalışmaz (`/tmp` her cold start'ta sıfırlanır; veri kaybolur). Zorunlu: Vercel + Supabase (PostgreSQL). Kontrol: DB Supabase mi, `DATABASE_URL` Supabase connection string mi, Vercel env'e eklendi mi. (VoiceFlow, BlueDock, easyride)
- **L-0025** — Yeni projede auth/payment koduna `<super-user-email>` (gerçek adres: GLOBAL_CLAUDE_MD.v2.23.archive.md BLOK 18 ve proje kodundaki SUPER_USERS listesi; skill dosyasına yazılmaz) için lifetime/bypass kontrolü EKLENMELİ (iyzico/Stripe olsun olmasın); unutulursa super user trial/rate limit/ödeme ekranına takılır. (ADHD-Killer-Pro-Project, VoiceFlow, MarketRadar)

## v2.23'ten taşınan bloklar

### ZORUNLU STACK (BÖLÜM B)
- Frontend: Next.js 15 + TypeScript + Tailwind CSS + shadcn/ui
- Backend: Supabase (PostgreSQL) — ZORUNLU. Deploy: Vercel — ZORUNLU.
- Supabase org: <supabase-org-id> (gerçek değer: arşiv BÖLÜM B) | Region: eu-west-2
- SQLite + execSync YASAK. Vercel + SQLite YASAK. Vercel + lokal DB YASAK.
- Her proje ayrı Supabase projesi (ortak proje/şema paylaşımı yok). Duplicate deploy kontrolü yap: aynı adla ikinci Vercel veya Supabase projesi açma.
- PAKET YÖNETİMİ (v2.14): Vercel pnpm + frozen-lockfile kullanır. Paket eklerken `pnpm install` ile package.json + pnpm-lock.yaml'ı BİRLİKTE commit et. Sadece package-lock.json commit etme → build ERR_PNPM_OUTDATED_LOCKFILE ile patlar. npm kullanıldıysa sonra `pnpm install --lockfile-only` çalıştır.
- GİZLİ DOSYA: .env, credentials, API key ASLA commit edilmez; .gitignore zorunlu: node_modules/ .next/ .env .env.local dist/ build/ .DS_Store *.log coverage/

### YENİ PROJE
- github.com/BeyBaba/BSA-Starter → "Use this template" kullan. ASLA sıfırdan başlama.
- İlk push sonrası CLAUDE.md otomatik gelir: `.github/workflows/auto-claude-md.yml` stack'i tespit eder (package.json/tsconfig.json/electron/pyproject.toml/Cargo.toml/Package.swift/build.gradle/pubspec.yaml/go.mod), `chore: auto-generate CLAUDE.md [skip ci]` ile commit eder; `permissions: contents: write` zorunlu. `git pull` → CLAUDE.md hazır.
- Üretilen CLAUDE.md referans modelindedir: global kural METNİ kopyalanmaz, sürüm numarası yazılmaz; tek kaynak https://raw.githubusercontent.com/BeyBaba/BSA-Starter/main/GLOBAL_CLAUDE_MD.md ; `BSA_SCOPE = true` satırı korunur.
- `<yerel-yolu-buraya-ekle>`, `<projenin-amacini-buraya-ekle>`, `<deploy-url-buraya-ekle>` yer tutucularını gerçek değerle doldur (PLACEHOLDER YASAK).
- package.json `version` = 1.0.0 (BLOK 22; 0.x yalnız ilk 3 gün deneme aşamasında).
- GITHUB ACTIONS: workflow varsa manuel build komutu verme; yoksa "ekleyelim mi?" sor.

### BLOK 0 — ESKİ PROJE
- 0a: `git log --oneline -30`, `git branch -a`, `git status` → özet sun
- 0b: Yedek öner (tag / ZIP / ikisi / gerek yok). ZIP yolu: D:\BSA Proje Yedekler
- 0c: Kabul ederse yedek al. Tag 403 → token scope uyar.
- 0d: CLAUDE.md'yi global kurallarla karşılaştır → eksikleri listele → ONAY AL → uygula
- 0e: Durum raporu — her özelliği sınıfla:
  ✅ ÇALIŞIYOR — test edildi, aktif
  ⚠️ KOD VAR AMA AKTİF DEĞİL — aktivasyon adımlarını listele
  ❌ BU PLATFORMDA İMKANSIZ — kaldır veya native roadmap'e taşı
  Arada kalan kod bırakma. Ya aktif et, ya kaldır, ya roadmap'e taşı.

### BLOK 0.5 — SKİLL ÖNERİLERİ
`npx skills list` ile kontrol et: planning→/concise-planning, debug→/systematic-debugging, react→/react-best-practices,
supabase→/postgres-best-practices, güvenlik→/api-security-best-practices, git→/git-pushing, electron→/electron-development,
n8n→/n8n-workflow-patterns, voice→/voice-ai-development, llm→/llm-app-patterns, chrome-ext→/chrome-extension-developer, pwa→/progressive-web-app

### BLOK 1 — YENİ PROJE: PLATFORM
Mobil / Web / Masaüstü / Mobil+Web / Backend-API / CLI-Bot-Otomasyon — kullanıcıya seçtir. Platform kısıtı varsa (web vs native) EN BAŞTA söyle.

### BLOK 2 — FİKİR TOPLAMA + TEKNOLOJİ
Kullanıcı anlatır → Claude sorar → "tamam" denince stack öner → onay al. README.md oluştur.
Her istenen özelliği sınıfla:
  ✅ BU PLATFORMDA YAPILABİLİR — hemen dahil et
  ❌ NATİVE GEREKTİRİR — arayüze KOYMA, NATIVE_ROADMAP.md'ye yaz
(PWA'da yapılamayan Tor, BLE, WiFi Direct, OS-level screenshot block vb. ASLA arayüze eklenmez; sadece UI olan özellik YASAK.)

### BLOK 3 — DEPLOY
Vercel (önerilen) / Netlify / EAS / GitHub Pages / VPS
YASAK: Vercel+SQLite, Vercel+execSync, Vercel+lokal DB. ZORUNLU: Vercel+Supabase (PostgreSQL).

İSTİSNA KATEGORİLERİ (v2.20) — bu repolarda "Next.js+Supabase zorunlu" uyarısı ÜRETİLMEZ:
- KATEGORİ DIŞI: çalışır uygulama barındırmayan repolar (doküman, şablon, skill, arşiv) için stack kuralı GEÇERSİZ. Örnekler: BigBrain, BSA-Starter, ui-ux-pro-max-skill_06062006
- PLATFORM UYUMSUZ: masaüstü (Electron) ve native mobil (React Native/Expo) projelerde Next.js+Vercel GEÇERSİZ; Supabase opsiyonel. Örnekler: VoiceFlow (Electron), ADHD-Killer-Pro-Project (Expo/RN), open-design (Electron)
- BSA DIŞI: `BSA_SCOPE=false` işaretli upstream/açık kaynak repolarda TÜM global kurallar GEÇERSİZ; upstream proje kuralları geçerli. Örnek: omi

### BLOK 12 — KVKK
Aydınlatma metni, sağlık verisi koruma, hesap silme hakkı. (Sağlık/kişisel veri log ve rapora yazılmaz — L-0016.)

### BLOK 15 — DENEME SÜRESİ & ÖDEME
40 gün ücretsiz deneme, profilde kalan gün göstergesi.
Ödeme entegrasyonu: iyzico (Türkiye) + Stripe (global) — ikisi birlikte desteklenmeli.
`<super-user-email>` SUPER USER: deneme süresi YOK, otomatik LİFETİME üye. Super user kontrolü her projede auth/payment koduna EKLENMELİDİR.

### BLOK 18 — SUPER USER KURALI
- `<super-user-email>` hesabı SUPER USER'dir (gerçek adres: arşiv BLOK 18 ve proje kodundaki SUPER_USERS listesi).
- Rate limit, plan kısıtlaması, trial süresi, ödeme ekranı bu hesap için GEÇERLİ DEĞİLDİR.
- Super user girişinde otomatik LİFETİME plan atanır — ödeme adımı atlanır.
- Bu kural TÜM projelerde geçerlidir (iyzico veya Stripe entegrasyonu olsun olmasın).
- Yeni proje oluşturulurken auth/payment koduna super user bypass EKLENMELİDİR.
- Super user listesi: desktop-app/ui/home.html içinde SUPER_USERS array'inde tanımlı.
- auth/login ve payment KRİTİK DOSYA'dır: tek dosya bile olsa dokunmadan önce onay al.

### BLOK 19 — README
Her projede README.md zorunlu: proje açıklaması, kurulum, özellikler listesi, teknoloji stack'i.

### RETROAKTİF KURAL UYARISI (v2.14)
Yeni bir global kural (projenin yazıldığı sürümden yeni) eski projede sağlanmıyorsa KENDİLİĞİNDEN düzeltme YAPMA. Tek satır uyar ve onay iste:
"⚠️ Bu proje eski kural sürümüyle yazılmış; v2.14 şu maddeleri ekledi: [liste]. Uygulayayım mı?"
Kullanıcı onaylamadan dokunma. (BLOK 0d "ONAY AL" adımı bu kuralın uygulamasıdır.)

## BigBrain YENI-PROJE-AKISI.md özeti
1. Repo: BSA-Starter "Use this template" → Private → `gh repo clone BeyBaba/<proje-adi> C:\Users\BSA\Projects\<proje-adi>`. (B seçeneği boş repo: `gh repo create BeyBaba/<proje-adi> --private --clone --local-clone-path C:\Users\BSA\Projects\<proje-adi>` — global kural gereği tercih edilmez.)
2. Global hook'lar (`C:\Users\BSA\.claude\hooks\global-session-start.sh`, `global-session-end.sh`) global settings.json'da kayıtlı; proje içine ayrıca hook KOYMA (çift tetikleme, L-0062). Her projede otomatik: BigBrain dersleri yüklenir, session sonunda ders adayı kontrolü inbox'a yazar.
3. Proje CLAUDE.md: stack + projeye özel kurallar + global kural REFERANSI (metin kopyası ve sürüm numarası yok).
4. BSA stack dışı / BSA kuralları uygulanmayacak proje → CLAUDE.md en başına `# BSA_SCOPE = false`; hook dersleri basmaz, "Bu repo BSA kapsami disinda - global kurallar gecersiz" der.
5. Claude.ai'da yeni proje açılırsa Knowledge'a BigBrain devir notu: `C:\Users\BSA\Projects\BigBrain\` — lessons/INDEX.md (tüm dersler), projects/INDEX.md (proje arşivi), global kural `C:\Users\BSA\.claude\CLAUDE.md`.
6. İlk session (PowerShell'de çift ampersan çalışmaz, iki ayrı satır):
   ```
   cd C:\Users\BSA\Projects\<proje-adi>
   claude --dangerously-skip-permissions
   ```
7. İlk commit: conventional commit + Türkçe açıklama; package.json `version` 1.0.0.

## Rapora yazılacak
- Zorunlu bölümler: Sonuç / Yapılanlar / Test / Varsayımlar / Proaktif notlar / Ders adayları / Kullanılan skill-agent / Denetim (bsa-memory şablonu).
- "Uygulanan dersler": en az L-0001, L-0025 + grep ile bulunanlar.
- Repo sınıfı (normal / KATEGORİ DIŞI / PLATFORM UYUMSUZ / BSA DIŞI) ve gerekçesi; `BSA_SCOPE` değeri.
- 0e veya BLOK 2 sınıflama listesi (✅ / ⚠️ / ❌) tam metniyle; NATIVE_ROADMAP.md'ye yazılan maddeler.
- Super user bypass'ın eklendiği dosya:satır; iyzico + Stripe durumu; 40 gün deneme göstergesi.
- Duplicate deploy kontrolü sonucu (Vercel/Supabase proje adları, region eu-west-2).
- Retroaktif uyarı verildiyse metni ve kullanıcının kararı.
- Deploy linki (İNDİRME LİNKİ: web → deploy linki; ASLA linksiz "hazır" deme).

Kaynak dersler: L-0001, L-0016, L-0025, L-0062, L-0092
