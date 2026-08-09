# CLAUDE.md — BSA-Starter

## 0. GLOBAL KURALLAR (REFERANS — KOPYA DEGİL)
Bu dosya global kurallarin kopyasini ICERMEZ. Her session baslangicinda su adres okunur:
https://raw.githubusercontent.com/BeyBaba/BSA-Starter/main/GLOBAL_CLAUDE_MD.md

Kural: Bu dosyaya global kural METNI YAPISTIRILMAZ ve surum numarasi YAZILMAZ.
Global kural degisirse tek kaynak guncellenir; bu dosya degismez.

BSA_SCOPE = true

## 1. PROJE KİMLİĞİ
- Ad: BSA-Starter
- Repo: github.com/BeyBaba/BSA-Starter
- Yerel yol: C:\Users\BSA\Projects\BSA-Starter
- Amac: Yeni BSA projeleri icin baslangic sablonu. "Use this template" ile kullanilir;
  ilk push'tan sonra auto-claude-md.yml proje CLAUDE.md'sini otomatik uretir.
- Production URL: N/A (sablon repo, deploy edilmez)

## 2. TEKNOLOJİ STACK
- Bu repo bir sablon/dokumantasyon reposudur; kendisi calistirilmaz veya deploy edilmez.
- Sablon kullanilarak acilan projeler icin beklenen stack:
  Next.js 15 + TypeScript + Tailwind CSS + shadcn/ui + Supabase (PostgreSQL) + Vercel
- Workflow: .github/workflows/auto-claude-md.yml — stack tespiti + CLAUDE.md otomatik uretimi

## 3. KOMUTLAR
- Bu repo icin dev/build/test/deploy komutu yoktur (calistirilabilir kod icermez).
- Sablonu test etmek icin: yeni repo olustur, "Use this template" ile BSA-Starter sec,
  main'e push yap, Actions sekmesinde auto-claude-md.yml ciktisini izle.

## 4. PROJEYE ÖZEL KURALLAR
- CLAUDE.md bu referans modelini takip eder: global kural metni kopyalanmaz,
  surum numarasi bu dosyaya yazilmaz.
- GLOBAL_CLAUDE_MD.md degistiginde bu dosya degismez — bu tasarim geregi.
- bsa-starter/CLAUDE.md (alt klasor icindeki sablon cikti) ayri PR'da ele alinacaktir;
  bu PR kapsaminda degildir.

## 5. BİLİNEN TUZAKLAR
- L-0050: CLAUDE.md duzenlemesinden sonra PowerShell script kalintisi yapisiyor.
  Her duzenlemeden sonra BigBrain/lessons/INDEX.md'deki L-0050 kontrolunu calistir;
  bos donmeli, doluysa o satiri sil.
- L-0066: gh pr create PowerShell'de bash heredoc ve && iceren baslik calismiyor;
  @"..."@ here-string kullan, baslikta && kullanma.
- L-0061: gh pr create fork/template repoda upstream'e PR acabilir; --repo parametresi zorunlu.

## 6. DOKUNULMAZ DOSYALAR
- GLOBAL_CLAUDE_MD.md — tek kaynak; dogrudan duzenleme YASAK, BigBrain PR'i uzerinden guncellenir
- .github/workflows/auto-claude-md.yml — sablon workflow; degistirmeden once kullaniciya sor
- bsa-starter/ — sablon cikti klasoru; bu dosyanin kapsami disinda
