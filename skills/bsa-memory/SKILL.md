---
name: bsa-memory
description: BigBrain hafızasını okuma/yazma gerektiren her görevde tetiklenir: session başı ders okuma, görev sonu ders adayı (lessons/inbox), zorunlu rapor şablonu, kural senkronizasyonu, "CLAUDE.md güncelle" ve bsa-denetci çağrısı.
---
# bsa-memory — BigBrain hafızası: okuma, ders yazma, rapor, denetim

## Ne zaman
- Her session başı (hafıza okuma) ve her görev sonu (ders adayı + rapor + bsa-denetci).
- "CLAUDE.md güncelle", "global'e ekle", "kural değiştir", "bu dersi kaydet", "rapor yaz", "denetle" dendiğinde.
- Bir projede çözülen sorunun başka projeye taşınabileceği fark edildiğinde (PROJELER ARASI).
- Proje CLAUDE.md'sine global metin kopyalanmak veya sürüm numarası yazılmak üzereyse (referans modeli ihlali) — dur.

## Görev başı kontrol listesi
1. Global kuralı oku: https://raw.githubusercontent.com/BeyBaba/BSA-Starter/main/GLOBAL_CLAUDE_MD.md → "Global CLAUDE.md v2.23 aktif" bildir; lokal `C:\Users\BSA\.claude\CLAUDE.md` başlığıyla sürüm farkı varsa bildir (L-0096). Erişilemezse bildir, session'a devam et ama uyar.
2. BigBrain/projects/INDEX.md + BigBrain/lessons/INDEX.md oku. Erişilemezse tek satır "⚠️ Hafıza okunamadı, devam ediyorum" — ASLA bloklama.
3. Konu grep'i: `grep -i '<konu anahtar kelimesi>' C:/Users/BSA/Projects/BigBrain/lessons/INDEX.md` → eşleşen L-XXXX'leri "Uygulanan dersler" listesine al.
4. Mevcut kodu oku: `gh pr list`, `git branch -a`, `grep -rn <konu>`, `git log` (L-0023, L-0092) — "yeni özellik" = yok varsayımı YASAK.
5. Görev sonu sırası: ders adayı var mı → inbox; rapor → `_reports\<proje>\<tarih>-<isim>.md` + Drive kopyası; bsa-denetci → "Denetim"; session özeti (bsa-hooks BLOK 23 madde 2).

## Kurallar (BigBrain dersleri)
- **L-0048** — Claude.ai proje sohbetleri birbirinden izole; cross-project arama yapılamaz (conversation_search boş döner). Ders madenciliği her projenin kendi session'ında: projeyi aç, "bu projedeki sohbetlerden BigBrain'e eklenecek ders adayı var mı?" sor; yeni Claude.ai oturumuna BigBrain linkini knowledge olarak ekle.
- **L-0096** — Global CLAUDE.md'ye lokal ek yapma; `~/.claude/CLAUDE.md` yalnız kopyadır, "CLAUDE.md güncelle" uzak kopyayı ezince lokal ek silinir (lokal v2.17 / uzak v2.20 drift'i yaşandı). Kural değişikliği ÖNCE BSA-Starter `GLOBAL_CLAUDE_MD.md`'ye PR, sonra lokal senkron; session başında sürüm farkını bildir.
- **L-0023** — Stale roadmap/TODO'ya güvenme; feature/fix öncesi `grep -rn` ile gerçek durumu tespit et; her merge sonrası roadmap'i DONE ile güncelle (BlueDot).
- **L-0092** — "Yeni özellik" isteğinde önce `gh pr list` + `git branch -a` + `grep -rn` + `git log`; paralel otonom oturumlar işi çoktan yapmış olabilir (AryaLife PR #10 Teklif: üzerine yazıldı, çift 0024 migration çıktı).

## v2.23'ten taşınan bloklar

### HAFIZA TEK KAYNAĞI (v2.14)
Tüm projeler-arası hafıza tek repoda: BeyBaba/BigBrain (`C:\Users\BSA\Projects\BigBrain`). Her yeni session'da BigBrain/projects/INDEX.md + BigBrain/lessons/INDEX.md oku; geçmiş projelerden çıkarılmış dersleri (L-XXXX) dikkate al, aynı hatayı tekrarlama. Bu dosyalara erişilemezse tek satır bildir ("⚠️ Hafıza okunamadı, devam ediyorum") ve session'a devam et — ASLA bloklama. Ayrı Claude-Memory / Unified-Learning-System reposu tutma (eski hafıza repolarıydı, arşivlendi).

### DERS YAZ — GERİ YAZMA (v2.15; v3 inbox akışıyla)
Hafıza tek yönlü değil. Önemli bir bug/çözüm, tekrar eden hata ya da genelleştirilebilir karar çıktığında oturum sonunda ders yaz (kısa: belirti → kök neden → kural/çözüm). Aynı dersi iki kez yazma — varsa "Görüldüğü projeler"e projeyi ekle. TÜM projelerde geçerli; okuma otomatik (hook), yazma bu kuralla. v3'te L-XXXX numarası ve INDEX.md kaydı triyajda verilir; Claude Code yalnız inbox'a yazar (aşağıdaki akış).

### HAFIZA OKUMA (v2.23)
Yeni özelliğe başlamadan `grep -i '<konu anahtar kelimesi>' C:/Users/BSA/Projects/BigBrain/lessons/INDEX.md`; eşleşen dersleri rapora "Uygulanan dersler" olarak yaz. Detay için `grep -n '^## L-XXXX'` ile satırı bul, bloğu `sed -n` ile oku (INDEX ~80KB, 98 ders; tamamını basma — hook çıktısı 1800 byte, L-0026).

### GÜNCELLEME
"CLAUDE.md güncelle" denildiğinde içeriği `C:\Users\BSA\.claude\CLAUDE.md`'ye yaz; `Get-Content C:\Users\BSA\.claude\CLAUDE.md | Select-Object -First 3` ile doğrula (başlıkta "GLOBAL CLAUDE.MD KURALLARI — v2.23" görünmeli). Kaynak her zaman uzak GLOBAL_CLAUDE_MD.md; lokale ek YAPMA (L-0096). Ardından L-0050 script kalıntısı kontrolü: `Select-String -Path CLAUDE.md -Pattern 'Add-Content|Get-Content|\$addition'` boş dönmeli. (L-0067: bu satırdaki yasaklı kalıplar örnek/tarama deseni; bu SKILL.md dosyası CLAUDE.md değildir, guard taramasına girmez — kalıp burada durabilir.)

### PROJELER ARASI
Bir projede çözülen sorunu diğerine öner. Projeler: ADHD Killer, VoiceFlow, GhostX, BİLSAV PWA, EasyRide (+ projects/INDEX.md'deki güncel liste: arya-life-reborn, BlueDot, BlueDock, MarketRadar, Web-Cloner, open-design, omi vb.). Öneri sohbete yazıldıysa rapora "Proaktif notlar"a da yazılır.

### KURAL SENKRONİZASYONU
Herhangi bir projede kural değiştiğinde sor: "Bu kuralı tüm projeler için geçerli kılayım mı? Global CLAUDE.md'ye ekleyeyim mi?" Evet ise akış: BSA-Starter `GLOBAL_CLAUDE_MD.md`'ye PR (`--repo BeyBaba/BSA-Starter`; başlık sürümü bump + SÜRÜM GEÇMİŞİ satırı) → merge → lokal `~/.claude/CLAUDE.md` senkron ("CLAUDE.md güncelle"). Lokal/proje dosyasına doğrudan global kural ekleme YOK (L-0096). Global vs proje kuralı çakışırsa DUR → UYAR → SOR → kullanıcı karar verir.

### CLAUDE.md REFERANS MODELİ
Proje CLAUDE.md'sine global kural METNİ KOPYALANMAZ ve sürüm numarası YAZILMAZ. Yalnız referans bölümü:
"## 0. GLOBAL KURALLAR (REFERANS — KOPYA DEGİL) — Bu dosya global kurallarin kopyasini ICERMEZ. Her session baslangicinda su adres okunur: https://raw.githubusercontent.com/BeyBaba/BSA-Starter/main/GLOBAL_CLAUDE_MD.md" + `BSA_SCOPE = true`.
Global kural değişirse tek kaynak (BSA-Starter, BigBrain PR'ı üzerinden) güncellenir; proje dosyası değişmez. Proje CLAUDE.md'sine yalnız globalde olmayan veya daha katı kurallar, BİLİNEN TUZAKLAR (L-XXXX) ve DOKUNULMAZ DOSYALAR girer. Eski projede ihlal görürsen kendiliğinden düzeltme; RETROAKTİF KURAL UYARISI ile onay iste.

## Ders yazma akışı (inbox)
1. Tetik: session-end (Stop) hook'unun "DERS KONTROLU (BigBrain)" sorusu ya da görev sonu kendi değerlendirmen. Ölçüt: tekrar edebilir hata, kök neden, genelleştirilebilir karar; "bir hata 2. kez görülürse kalıcı ders".
2. MÜKERRER KONTROLÜ: `grep -i '<kök neden anahtarı>' C:/Users/BSA/Projects/BigBrain/lessons/INDEX.md`. Aynı kök neden varsa yeni ders YAZMA; rapora "L-XXXX 'Görüldüğü projeler'e <proje> eklenmeli" notu düş (triyajda işlenir).
3. Yoksa dosya: `BigBrain/lessons/inbox/<YYYY-AA-GG>-<proje>-<slug>.md` (Write aracıyla; here-string hook'a takılır, L-0083). Şablon:
   ```
   # <kısa başlık>
   ## Belirti
   ## Kök Neden
   ## Kural-Çözüm
   ## Görüldüğü projeler
   ```
   Kısa ve net; PII/secret yazma (L-0016, L-0014); yasaklı komutu literal yazıp doğrulamayı kirletme (L-0067).
4. `lessons/INDEX.md`'ye DOĞRUDAN YAZMA YOK — L-XXXX numarası triyajda kullanıcı onayıyla verilir (lessons/inbox = "ders adayları bekleme odası"). bsa-denetci de aynı inbox'a yazar (kendi MEMORY.md'sine ≤2 satır özet + inbox dosyası); o da INDEX'e dokunmaz.
5. Ders adayı yoksa hiçbir dosya yazma; tek satır "Ders adayı yok".
6. Rapora "Ders adayları" bölümünde dosya adlarını listele; session özetinde "Inbox adaylari: <slug listesi>".

## Rapor şablonu
Rapor yolu: `C:\Users\BSA\Projects\_reports\<proje>\<tarih>-<isim>.md`; kopyası Google Drive rapor klasörüne (örn. aryalife-raporlar). Claude.ai yalnız rapor dosyasını okur, sohbeti göremez — sohbette söylenip raporda olmayan öneri = EKSİK rapor. Zorunlu bölümler:
- **Sonuç** — tek paragraf; "bitti" yalnız test/kanıt varsa.
- **Yapılanlar** — dosya/PR/commit listesi; çoklu ajan kullanıldıysa hangi ajanın neyi yaptığı (BLOK 22 dosya sahipliği); "Uygulanan dersler" L-XXXX listesi.
- **Test** — tsc/build/Playwright + görsel/kanıt; ✅ ÇALIŞIYOR / ⚠️ YAZILDI AMA AKTİF DEĞİL / ❌ BU PLATFORMDA İMKANSIZ.
- **Varsayımlar** — "Varsayım:" satırları (otonom oturumda soru penceresi açmak yerine).
- **Proaktif notlar** — sohbete yazılan HER öneri (skill/plugin/MCP, yan sorun, paralel ajan fırsatı).
- **Ders adayları** — inbox dosya adları; yoksa "yok".
- **Kullanılan skill/agent** — 🧰 hangi skill/plugin/MCP, somut katkısı (örn. "context7: Next.js 15 cache API'si değişmişti"); hiçbiri yoksa "kullanılmadı" — sessiz geçme.
- **Denetim** — bsa-denetci çıktısı birebir (İHLAL / UYARI / TEMİZ + "Denetlenen dosya: N | İhlal: n | Uyarı: n").
Bug çözümünde DEBUG RAPOR FORMATI Sonuç'un altına 5 başlıkla eklenir:
  1. Bug neydi ve neden oluyordu
  2. Çözüm
  3. Kanıt (test / log / ekran görüntüsü)
  4. Test geçti; merge kararı Savaş'ın (PR URL) — v2.23'teki "kuralımız gereği merge ediyorum" v3.0 çekirdeğinde geçersiz; merge kararı Savaş'ın (bsa-release BLOK 5)
  5. Bu turda çözülenler (kısa özet liste)
Session sonunda ayrıca "=== BigBrain SESSION OZET ===" bloğu.

## bsa-denetci çağırma
- Zaman: görev/branch bittiğinde, PR açmadan (veya merge'den) önce; diff hazır olmalı (`git diff main...HEAD --stat`).
- Çağrı: `bsa-denetci` subagent'ı (salt-okuma: Read/Grep/Glob + `git diff`, `git status`, `gh pr view`). Dosya değiştirmez, commit/push yapmaz; yalnız rapor + inbox ders adayı.
- Çıktı biçimi: `İHLAL (L-XXXX): <dosya>:<satır> — <ne yanlış> — <düzeltme>` / `UYARI (L-XXXX): <dosya> — <riskli ama kesin değil>` / `TEMİZ`; sonda sayım satırı.
- İHLAL varsa düzelt ve tekrar çağır; UYARI'ları rapora taşı. Sonuç rapora "Denetim" bölümüne birebir girer.

## Rapora yazılacak
- Yukarıdaki şablonun TÜM bölümleri (eksik bölüm = eksik rapor) ve Drive kopyasının yolu.
- Hafıza okundu mu / "⚠️ Hafıza okunamadı" verildi mi; global sürüm (v2.23) ve lokal drift durumu.
- Kural senkronizasyon sorusu soruldu mu, cevabı ve açılan BSA-Starter PR linki.
- Referans modeli ihlali (proje CLAUDE.md'de global metin/sürüm) tespit edildiyse uyarı metni ve kullanıcı kararı.
- Mükerrer ders kontrolü sonucu (eşleşen L-XXXX veya "yeni aday").

Kaynak dersler: L-0014, L-0016, L-0023, L-0026, L-0048, L-0050, L-0067, L-0083, L-0092, L-0096
