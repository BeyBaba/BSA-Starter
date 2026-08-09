# CLAUDE.md — <proje-adi>

## 0. GLOBAL KURALLAR (REFERANS - KOPYA DEGIL)
Bu dosya global kurallarin kopyasini icermez. Her session baslangicinda su adres okunur:
https://raw.githubusercontent.com/BeyBaba/BSA-Starter/main/GLOBAL_CLAUDE_MD.md

Kural: Bu dosyaya global kural metni yapistirilamaz ve surum numarasi yazilamaz.
Global kural degisirse tek kaynak guncellenir; bu dosya degismez.

BSA_SCOPE = true

## 1. PROJE KIMLIGI
- Ad: <proje-adi>
- Repo: <github-repo-url>
- Olusturulma: <tarih>
- Yerel yol: <yerel-yolu-buraya-ekle>
- Amac: <projenin-amacini-buraya-ekle>
- Production URL: <deploy-url-buraya-ekle>

## 2. TEKNOLOJI STACK
- Tespit edilen stack:
  - <stack-buraya-gelir>
- Versiyon dosyalari:
  - <versiyon-dosyasi-buraya-gelir>

## 3. KOMUTLAR
- <build-komutlari-buraya-gelir>

## 4. PROJEYE OZEL KURALLAR
- SADECE globalde olmayan veya globalden DAHA KATI kurallar buraya eklenir.

### Versiyon Bump Stratejisi
| Modul | Bump Tipi | Aciklama |
|-------|-----------|----------|
| <modul> | <tip> | <aciklama> |

### Release Kurallari
1. Sadece main branch'inden release cik.
2. Test gecmeden release yapma.
3. chore: veya release: prefix commit release tetikler.
4. GitHub Release artifact ekle (varsa).

### Kontrol Listesi
- [ ] main branch'inde miyiz?
- [ ] Tum modulllerde versiyon eslendi mi?
- [ ] CHANGELOG.md guncellendi mi?

## 5. BILINEN TUZAKLAR
- Bu projede yasanan hatalar BigBrain ders numaralariyla (L-XXXX) buraya eklenir.
- <ilk-hata-buraya-ekle>

## 6. DOKUNULMAZ DOSYALAR
- <degistirilmesi-yasak-dosya-listesi-buraya-ekle>
