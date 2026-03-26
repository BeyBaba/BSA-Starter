# CLAUDE.md — [PROJE_ADI]

Bu dosya Claude'un proje kurallarını otomatik okuduğu yapılandırma dosyasıdır.
Her session başında ve release öncesinde bu dosya okunur.
> Bu template repo'nun varsayılan CLAUDE.md'sidir. GitHub Actions ilk push'ta projeye özel versiyonu otomatik oluşturur.

---

## 📁 Proje Yapısı

```
[PROJE_ADI]/
├── src/               → Kaynak kod
└── CLAUDE.md          ← bu dosya
```

---

## 🔢 Versiyon Kuralları

| Modül | Bump Tipi | Açıklama |
|-------|-----------|----------|
| Tüm proje | **patch** | Bug fix |
| Tüm proje | **minor** | Yeni özellik |
| Tüm proje | **major** | Büyük değişiklik |

---

## 🚀 Release Kuralları

1. Sadece `main` branch'inden release çık.
2. `chore:` veya `release:` prefix'li commit → release tetikler.
3. Test geçmeden release yapma.

---

## 📝 Commit Mesajı Formatı

```
feat:     Yeni özellik
fix:      Bug düzeltme
chore:    Versiyon / config değişikliği
docs:     Sadece dokümantasyon
refactor: Kod yeniden düzenleme
security: Güvenlik yaması
```

---

## 📋 Release Öncesi Kontrol Listesi

- [ ] `main` branch'inde miyiz?
- [ ] Versiyon dosyası güncellendi mi?
- [ ] Testler geçiyor mu?
- [ ] `CHANGELOG.md` güncellendi mi?
