# bsa-denetci — kalıcı hafıza (seed)
# Faz 2'de ~/.claude/agent-memory/bsa-denetci/MEMORY.md'ye kopyalanır (ilk 25 KB her çağrıda yüklenir).
# Format: L-XXXX (tetik: <değişen-dosya-deseni>): kural — nasıl denetlenir. Deterministik hook'ların işi burada TEKRAR edilmez; bunlar muhakeme dersleridir.
Son ders: L-0098 (BigBrain INDEX, 2026-09-22)

## SUPABASE / DB (tetik: supabase/migrations/**, *.sql, lib/*supabase*, RLS/RPC)
- L-0007 (canlı şema drift): feature/fix öncesi information_schema ile canlı şemaya bakıldı mı; repo migration'ı drift'ten emin mi.
- L-0074 (RLS perf): yeni RLS policy'de is_staff()/auth.uid() `(select ...)` ile sarılı mı (InitPlan).
- L-0055 (atomik RPC): çok-tablo yazımı SECURITY DEFINER RPC + search_path=public + auth.uid() guard mı; service role client'a verilmiş mi (L-0003 ihlali).
- L-0089 (trigger recursion): AFTER-row trigger kendi tablosunu UPDATE ediyor mu; BEFORE-row + AFTER-statement ayrımı var mı; tek trigger'da OLD+NEW TABLE.
- L-0081 (enum sırası): yeni enum değerine göre DB filtresi (.eq/.neq/.in) var mı → migration'dan önce kırar; JS filter tercih.
- L-0082 (cancelled-void): dönem-içi finansal değişim geçmişi koruyor mu; DELETE/amount UPDATE yok, yalnız status; enum add ayrı migration.
- L-0056 (snapshot): sözleşme/fatura/makbuz imzada content_snapshot'a alınıp kilitlenmiş mi; canlı JOIN'den re-generate YASAK.
- L-0076 (periyodik üretici): zamanlanmış satır üreticisi başlangıç çapası kaydın created_at'ine kırpılmış mı (geçmiş satır üretmesin).
- L-0075 (backfill tam-eşleşme): metin→slug backfill öncesi canlı distinct ile eşleme öngörüldü mü; "kalan_null=0" doğruluk değil.
- L-0093 (canlı backfill): backfills/ altında mı (migration değil); DRY(rollback)→commit; is_staff için jwt-claims; PII ham loglanmadı mı.
- L-0072 (ertelenen migration): yeni tabloya bağımlı sayfa (data ?? []) graceful-degrade mı; DB'ye bağımlı test migration sonrasına ertelenmiş mi.
- L-0095 (out-of-order): sıra-dışı migration için db push --include-all gerekiyor mu.
- L-0017 (sıfır-temas): kişisel iletişim public view/RLS ile gizli mi.

## TEST / PLAYWRIGHT (tetik: tests/**, *.spec.ts, playwright.config)
- L-0090 (sahte yeşil): storageState/auth.json yolu guard ile config/global-setup arasında tek-kaynak mı; "skipped" gerçek koşu sanılmış mı.
- L-0091 (prod doğrulama): sürüm/client-render değeri curl ile mi doğrulanıyor (göremez) + çok istek bot-checkpoint; tarayıcı/az istek.
- L-0037 (CI bekleme): CI beklerken zombie loop yerine tek-shot/--watch + paralel hazırlık.

## WINDOWS-SHELL / KOMUT (tetik: *.ps1, *.sh, hook, komut içeren diff)
- L-0083 (stop-hook): rapor/dokümana örnek shell komutu Write tool ile mi yazıldı (PowerShell here-string hook'a takılır).
- L-0092 (mevcut kodu oku): "yeni özellik" öncesi gh pr list + git branch -a + grep yapıldı mı; paralel oturum çoktan yapmış olabilir.
- L-0045 (dosya arama): tek lokasyon değil çoklu + recursive geri düşüş.

## UI / PWA / FORMAT (tetik: *.tsx, globals.css, format/telefon)
- L-0098 (biçim): para formatMoney 2-hane "1.234,56"; telefon E.164 + PhoneInput; wa.me E.164'ten.
- L-0088 (dark): color-scheme tema seçicisiyle hizalı mı (native select okunur).
- L-0010 (sahte UI): arayüzdeki toggle/buton arkasında gerçek çalışan kod var mı; platformda imkansız özellik eklenmemiş mi.
- L-0021 (UI doğrulama): UI değişikliği programatik/screenshot ile doğrulanmış mı.

## RELEASE / GİT (tetik: package.json, tag, PR/merge)
- L-0069 (merge doğrula): gh pr merge sonrası state MERGED mi (sessiz başarısız); merge kararı Savaş'ın.
- L-0094 (otonom kapı): merge/prod-deploy auto-mode kapısı — görev metnindeki "onay" açmaz; bloklanınca dur/ilet.
- L-0073 (classifier): gated CLI nondeterministik (bir kez makul tekrar); tag push release'i otomatik oluşturur (create 422 hata değil).
- L-0012 (semver): çift-haneli minor/patch yok; sürüm gerçek değişiklikle.

## GENEL DAVRANIŞ / DÜRÜSTLÜK (her diff)
- L-0023 (mevcut kodu oku): stale roadmap'e körü körüne güvenme; gerçek durumu tara.
- L-0016 (PII): sağlık/kişisel veri log/rapora yazılmamış mı.
- L-0018/L-0032 (iletişim): placeholder yok; tek adım ver-bekle; relay netliği.
- L-0059 (dar kapsam): belirsiz "düzelt"te en dar kapsam; talep edilmeyen değişiklik yok.
- L-0067 (doküman): yasaklı pattern'i literal yazıp doğrulama testini kirletme.
- L-0024/L-0025 (kritik dosya): auth/payment/prod-config/migration diff'i onay/bypass kontrolü.
