# skills/ — Hafıza v3 alan bilgisi skill'leri (bsa-*)

Çekirdek GLOBAL (v3.0) yalnız her oturumda gereken kuralları taşır; alan bilgisi bu skill'lerde.
Görev BAŞINDA ilgili skill çağrılır (dosya deseni/iş türü tetikler), rapora "Uygulanan dersler: L-..." yazılır.
Kurulum: `bash hooks/install.sh` → `~/.claude/skills/<ad>/SKILL.md`. Kaynak tek yer burasıdır (L-0096).

| Skill | Tetikleyici | Ders grubu |
|---|---|---|
| `bsa-supabase` | `supabase/**`, `*.sql`, RLS/RPC/trigger/backfill, canlı şema | L-0002/0003/0007/0016/0017/0034/0035/0052/0053/0055/0056/0058/0072/0074/0076/0081/0082/0089/0093/0095 + BLOK 12-13 |
| `bsa-release` | `package.json` sürüm, tag/release, PR/merge, CI, Vercel deploy | L-0006/0008/0009/0012/0028/0036/0054/0057/0069/0073/0080/0094 + BLOK 4/5/6/22 |
| `bsa-pwa` | service worker, manifest, push/bildirim, offline, ses | L-0004/0005/0013/0033/0040 + BLOK 7/9/10/14/16/21 |
| `bsa-playwright` | `tests/**`, `*.spec.ts`, `playwright.config`, UI doğrulama, prod doğrulama | L-0037/0039/0042/0046/0047/0090/0091 + UI TESTİ ZORUNLU |
| `bsa-windows-shell` | `*.ps1`, `*.sh`, hook/komut içeren iş, MCP/araç tuzakları | L-0015/0019/0026/0027/0029/0030/0031/0041/0051/0060/0063/0064/0066/0068/0070/0077/0078/0079/0083/0084/0085/0086/0087/0097 + BLOK 23 PS kuralı |
| `bsa-ui-format` | `*.tsx`, `globals.css`, para/telefon biçimi, tema, i18n, Material You | L-0071/0088/0098 + BLOK 7/8/11/17/20/24 |
| `bsa-new-project` | yeni repo / eski proje devralma / platform-stack kararı / super user / KVKK | L-0001/0025 + BLOK 0/0.5/1/2/3/12/15/18/19 + istisna kategorileri |
| `bsa-hooks` | hook yazma/değiştirme, settings.json, oturum sürekliliği | L-0049/0062/0065 (+0026/0050/0063/0083) + BLOK 23 |
| `bsa-memory` | BigBrain okuma/yazma, ders adayı, CLAUDE.md referans modeli, rapor şablonu | L-0048/0096 (+0023/0092) + HAFIZA/DERS YAZ/KURAL SENK. |

Eşleme kaynağı: `_reports\bigbrain\2026-09-22-global-v3-eslestirme.md` (60 v2.23 birimi → hedef; kayıp 0).
bsa-vercel adayı `bsa-release` içinde (## Vercel), bsa-gmail adayı `bsa-windows-shell` içinde (## MCP / araç tuzakları) toplandı.
