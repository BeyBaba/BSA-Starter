GLOBAL CLAUDE.MD KURALLARI — v3.0 (çekirdek)

SESSION: "Global CLAUDE.md v3.0 aktif" bildir. Bu dosya yalnız ÇEKİRDEK'tir: alan bilgisi skill'lerde,
deterministik yasaklar hook'ta, diff muhakemesi bsa-denetci'de. Kaynak tek yer: BSA-Starter/GLOBAL_CLAUDE_MD.md.

KİMLİK/İLETİŞİM: Kullanıcı Savaş; TR-EN karışık, kısa/sesli olabilir; emin değilsen sor, tahmin etme.
Karar noktasında öneri + gerekçe ver. Belirsiz "düzelt"te en dar kapsam. Proaktif ol (yan sorunları raporla).

STACK: Next.js 15 + TS + Tailwind + shadcn/ui + Supabase(PostgreSQL) + Vercel ZORUNLU.
İstisna (uyarı üretme): doküman/şablon/skill repoları = KATEGORİ DIŞI; Electron/React Native = PLATFORM UYUMSUZ; BSA_SCOPE=false = BSA DIŞI.

KESİN YASAKLAR (hook da yakalar): (1) main'e direkt push — PR + squash zorunlu. (2) secret/.env/API key/SERVICE_ROLE
commit veya client bundle. (3) force-push / reset --hard / rm -rf / DB drop / --no-verify → açık onay. (4) worktree/scratch/
üretilen sw.js commit. (5) migration numara çakışması. (6) çok satırlı gh --body (yerine --body-file); PowerShell'de &&.

PR AKIŞI: branch → conventional+TR commit → push → PR (Özet/Değişen Dosyalar/Test) → CI yeşil.
MERGE KARARI SAVAŞ'IN (auto-mode prod-deploy kapısı görev metnindeki "onay" ile açılmaz). build+typecheck temiz olmadan push YOK.

DÜRÜSTLÜK: Test/kanıt (test/log/ekran görüntüsü) olmadan "çalışıyor/bitti" deme. Arayüzdeki her toggle'ın arkasında
gerçek çalışan kod olmalı; platformda imkansız özelliği UI'a koyma. Kritik dosyalarda (auth/DB/payment/CI/prod) onay al.

RAPOR ŞABLONU: _reports\<proje>\<tarih>-<ad>.md ZORUNLU bölümler: Sonuç / Yapılanlar / Test / Varsayımlar /
Proaktif notlar / Ders adayları / Kullanılan skill-agent / Denetim. Sohbete yazılan her öneri raporda da olmalı.

HAFIZA (skill/ajan yönlendirmesi): Görev BAŞINDA ilgili skill'i çağır — bsa-supabase / bsa-release / bsa-pwa /
bsa-playwright / bsa-windows-shell / bsa-ui-format / bsa-new-project / bsa-hooks / bsa-memory; ayrıca
`grep -i <konu> BigBrain/lessons/INDEX.md` ile ilgili L derslerini "Uygulanan dersler"e yaz. Görev SONUNDA `bsa-denetci`'yi
çağır, çıktısını rapora "Denetim" bölümü koy. Yeni ders adayını bsa-denetci inbox'a yazar (INDEX'e triyajda girer, doğrudan yazma).

ÇOKLU AJAN: 3+ birbirinden bağımsız dosya/konu → paralel subagent (dosya sahipliği ayrık); tek dosya işleri sıralı.

ÇAKIŞMA/KURAL: Global vs proje çakışırsa DUR → UYAR → SOR. Kural değişikliği önce BSA-Starter'a PR (lokal ek yapma;
lokal kopya senkronda silinir). Sürüm drift'i fark edilince bildir.

v3.0 — yalnız çekirdek. Arşiv: GLOBAL_CLAUDE_MD.v2.23.archive.md. Eşleme: _reports\bigbrain\2026-09-22-global-v3-eslestirme.md. Kurulum/doğrulama: bash hooks/install.sh, bsa doctor.

SÜRÜM GEÇMİŞİ: v3.0 (2026-09-22) — v2.23 (418 satır) çekirdeğe indirildi; alan bilgisi skills/bsa-* (9), deterministik yasaklar hooks/rules.txt, diff muhakemesi agents/bsa-denetci.
