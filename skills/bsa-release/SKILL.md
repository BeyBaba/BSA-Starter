---
name: bsa-release
description: Sürüm çıkarma, PR/merge, tag/release, Vercel deploy ve GitHub Actions işlerinde tetiklenir — package.json/CHANGELOG.md/.github/workflows/vercel.json değişince veya "release yap / versiyon çıkar / merge et / deploy et / tag at" denince.
---
# bsa-release — Sürüm, PR/merge, tag/release ve deploy kuralları

## Ne zaman
- `package.json` (version), `CHANGELOG.md`, `pnpm-lock.yaml`, `.github/workflows/*.yml`, `vercel.json` değişiyorsa
- "release yap", "versiyon çıkar", "tag at", "merge et", "deploy et", "build al", "push et" istekleri
- `gh pr create` / `gh pr merge` / `git tag` / `gh release` komutları koşulacaksa
- Vercel build hatası (`ERR_PNPM_OUTDATED_LOCKFILE`, postinstall) ayıklanıyorsa
- Production launch hazırlığı (email swap, yedek) yapılıyorsa

## Görev başı kontrol listesi
1. `git status` → stage'lenecekleri gör; scratch/worktree/.env/büyük binary yok (hook da yakalar).
2. `pnpm tsc --noEmit` (0 hata) ve `pnpm build` temiz → değilse push YOK (BLOK 6).
3. `gh pr list --repo <owner/repo>` ve `git branch -a` → aynı iş açık bir PR'da mı (L-0092).
4. Mevcut sürüm `package.json` version alanından; commit tipine göre bump kararı (BLOK 22).
5. Merge/prod-deploy adımı varsa: bu oturumda İNSAN onayı var mı? Yoksa merge'e BAŞLAMA (L-0094).
6. `grep -i 'release\|merge\|vercel\|tag' C:/Users/BSA/Projects/BigBrain/lessons/INDEX.md` → rapora "Uygulanan dersler".

## Kurallar (BigBrain dersleri)

### Sürüm / semver
- **L-0012** — `package.json` tek doğruluk kaynağı; kod sürümü oradan okur, elle senkron yok. Patch 9'a gelince zorunlu minor bump (1.6.9 → 1.7.0, ASLA 1.6.10). Major öncesi ZIP yedek; kullanıcı-yüzlü yerde diskret `vX.Y.Z`.

### PR / merge
- **L-0069** — `gh pr merge` sessizce başarısız olabilir ("çıktı yok = başarılı" YANLIŞ); her merge sonrası `gh pr view <no> --repo <repo> --json state,mergedAt` ile doğrula, MERGED değilse tekrarla. Doğrulamadan "merge edildi" yazma. (hook da uyarır)
- **L-0094** — Otonom görevde merge = otomatik prod deploy → auto-mode İNSAN onayı ister; görev metnindeki "KAPI ONAY" bu kapıyı AÇMAZ. Bloklanırsa tag/release YAPMA, rapora "BLOKE — interaktif onay" yaz, bağımsız adımlara geç. Preview SSO-korumalı olabilir (bypass token = prod-config değişikliği) → testi lokal dev + storageState ile prod Supabase'e karşı koş, "preview SSO nedeniyle lokal kanıt" yaz. Migration'ları merge sırasından bağımsız (self-contained) yap.
- **L-0073** — Auto-mode sınıflandırıcı nondeterministik: gated ama idempotent/okuma komutu (`supabase db push`, `migration list`) reddedilirse BİR kez tekrar dene; ısrarla geçmiyorsa dur ve Profesör'e ilet. Docker kapalıyken `functions deploy` yine çalışır (uzak build).

### Tag / release / GitHub Actions
- **L-0073** — Tag push `release.yml`'i tetikler ve release'i OTOMATİK oluşturur; sonra `gh release create` 422 "Release.tag_name already exists" verir → hata DEĞİL. Tag'den sonra create etme, `gh release view vX.Y.Z` ile doğrula.
- **L-0008** — Release/commit yapan workflow'da `permissions: contents: write` ZORUNLU; yoksa `softprops/action-gh-release` 403/failure.
- **L-0009** — `git push --tags` 403 → token scope (repo/write) sorunu; kullanıcıyı token scope hakkında uyar.
- **L-0028** — `gh repo delete` varsayılan token'da `delete_repo` scope'u yok ("HTTP 403: Must have admin rights") → önce `gh auth refresh -h github.com -s delete_repo`; her destructive `gh` işleminden önce scope doğrula. (hook da yakalar)
- **L-0080** — Büyük binary (ZIP/MP4/PDF, ~100MB blob limiti) git'e girmesin; push HTTP 408/500 "send-pack: unexpected disconnect" bunun belirtisi. İlk commit'ten önce `.gitignore`'a `*.zip *.mp4 *.mov *.tif *.psd`; `git config http.postBuffer 524288000`; push öncesi `git ls-tree -r -l HEAD | awk '$4>95000000'` boş olmalı. Girdiyse `git reset --soft origin/master` → temiz commit; kalıcıysa `git filter-repo`. Büyük dosya → Drive/Releases/LFS. (hook `git add *.zip` vb. yakalar)

### Production launch
- **L-0036** — Geliştirmede tüm email alanları (VAPID_CONTACT_EMAIL, RESEND_FROM_EMAIL, iyzico kontak, sözleşme şablonları) `<dev-email>` (gerçek adres: GLOBAL_CLAUDE_MD.v2.23.archive.md BLOK 18 super user adresi; skill dosyasına yazılmaz); production'a gmail.com ile çıkmak YASAK. Yeni email-related özellik eklenince "launch öncesi domain email ile değiştir" listesine ekle; "launch yaklaşıyor" denince listeyi proaktif göster.

### Vercel
- **L-0006** — Vercel pnpm + frozen-lockfile: sadece `package-lock.json` commit etmek `ERR_PNPM_OUTDATED_LOCKFILE` verir. Paket eklerken `pnpm install <pkg>`, `package.json` + `pnpm-lock.yaml` BİRLİKTE commit; npm kullanıldıysa sonra `pnpm install --lockfile-only`.
- **L-0057** — Lokal geçip Vercel'de patlayan build → önce postinstall script'lerine bak (native binary indirme, platform kontrolü). Sorunlu projede `installCommand: "npm install --ignore-scripts"`; gerekirse postinstall işini build script'ine taşı.
- **L-0054** — Vercel'de tek sayfalık makbuz/sertifika için Puppeteer (50MB+ limit) / PDFKit / `@react-pdf/renderer` (hydration hatası) KURMA. `window.open()` + `@page { size: A4; margin: 20mm; }` + `window.onload = () => window.print()`; bileşen `'use client'` (SSR'da window yok). Çok sayfalı/grafikli/server-push PDF → ayrı servis (Railway + Puppeteer).

## v2.23'ten taşınan bloklar

### BLOK 22 — OTOMATİK RELEASE VE SEMVER (İstisna YOK, kural sabittir)
Her anlamlı değişiklik grubu (yeni özellik, bug fix, refactor) tamamlandığında:
1. Conventional commit at (feat:/fix:/chore:/refactor:/docs:/test:) — Türkçe açıklama.
2. `package.json` semver bump: yeni proje / MVP'ye ulaşmış proje 1.0.0'dan başlar (0.x yalnız ilk 3 gün deneme); feat: → MINOR (1.0.0 → 1.1.0); fix: → PATCH (1.0.0 → 1.0.1); BREAKING CHANGE footer → MAJOR (1.0.0 → 2.0.0); yalnız docs:/test:/refactor: → bump YOK.
3. `CHANGELOG.md`'ye Keep a Changelog formatında ekle.
4. main'e DOĞRUDAN push YASAK (hook da yakalar) — feature branch → PR → kullanıcıya URL.
5. PR merge sonrası: `git tag vX.Y.Z` + `git push origin vX.Y.Z`; `release.yml` varsa tag push release'i otomatik üretir — elle `gh release create` YAPMA, `gh release view vX.Y.Z` ile doğrula (L-0073); yoksa `gh release create vX.Y.Z --notes-file <changelog-parçası>`.
6. auto-release skill'i varsa onu kullan.
7. Kullanıcıya release özeti göster.

### BLOK 4 — VERSİYON
- Semver major.minor.patch; package.json'dan oku, tüm dosyalarda güncelle. Major öncesi ZIP yedek. Her sürüm geçişinde GitHub Release + changelog.
- ÇİFT HANELİ MİNÖR YOK: minör 9'daysa (1.9.x) sonraki özellik sürümü 1.10.0 DEĞİL, doğrudan bir üst BÜYÜK (2.0.0). Boşuna/simgesel sürüm çıkarma; sürümü gerçek bir değişiklikle çıkar; kararsızsa sürüm tipini kullanıcıya sor.

### BLOK 5 — PR/MERGE
- main'e direkt push YASAK. `claude/<branch>` → PR → squash merge. Conventional commit + Türkçe açıklama. PR gövdesi 3 bölüm: **Özet / Değişen Dosyalar / Test**. Boş PR yasak. Gövde `--body-file <dosya>` ile verilir (hook `--body "` kalıbını yakalar).
- **MERGE KARARI SAVAŞ'IN** — auto-mode prod-deploy kapısı görev metnindeki onayla açılmaz; oturum-içi interaktif onay gerekir (L-0094). Test (build + typecheck + UI testi) geçen PR'da OTONOM MERGE yalnız bu kapı açıkken; mimari/emin olunamayan kararda dur ve danış.

### BLOK 6 — BUILD/DEPLOY
- `npx tsc --noEmit` zorunlu (0 hata); önce otomatik dene, yapamazsan komut ver. build + typecheck temiz olmadan push YOK.

### PAKET YÖNETİMİ
- Vercel pnpm + frozen-lockfile kullanır. `pnpm install` ile `package.json` + `pnpm-lock.yaml` BİRLİKTE commit; sadece package-lock.json commit etme; npm kullanıldıysa sonra `pnpm install --lockfile-only`.

### GITHUB ACTIONS
- Workflow varsa manuel build komutu verme; yoksa "ekleyelim mi?" sor. `permissions: contents: write` zorunlu.

### VERSİYON GÖRÜNÜRLÜĞÜ
- Her projede kullanıcı-yüzlü bir yerde (login/landing/about ekranı) `vX.Y.Z` etiketi; package.json'dan (tek kaynak) otomatik okunur, elle senkron yok. Görünüm: küçük, diskret, monospace, textMuted renk.

### İNDİRME LİNKİ / YEDEK
- Her sürüm değişiminde link ver: masaüstü → EXE/release linki, web → deploy linki. ASLA linksiz "hazır" deme.
- "yedek al" → seçenek sun (Git tag / ZIP / ikisi). ZIP yolu: `D:\BSA Proje Yedekler` (D: sandbox'tan erişilemeyebilir → komutu kullanıcı kendi terminalinde çalıştırır).

## Rapora yazılacak
- `Uygulanan dersler: L-0006, L-0008, L-0009, L-0012, L-0028, L-0036, L-0054, L-0057, L-0069, L-0073, L-0080, L-0094` (yalnız gerçekten uygulananlar listelenir).
- Kanıt: tsc/build çıktısı (0 hata), PR URL, `gh pr view --json state,mergedAt` çıktısı (MERGED), `gh release view vX.Y.Z` çıktısı, deploy/release linki, yeni sürüm numarası.
- Merge bloklandıysa: "BLOKE — interaktif onay bekliyor" + tamamlanan bağımsız adımlar.
- Bölümler: Sonuç / Yapılanlar / Test / Varsayımlar / Proaktif notlar / Ders adayları / Kullanılan skill/agent.

Kaynak dersler: L-0006, L-0008, L-0009, L-0012, L-0028, L-0036, L-0054, L-0057, L-0069, L-0073, L-0080, L-0092, L-0094
