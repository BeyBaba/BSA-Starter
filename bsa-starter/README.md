# BSA Starter Template

BSA tüm projeleri için başlangıç şablonu.

## Özellikler

- ✅ Otomatik `CLAUDE.md` üretimi (GitHub Actions)
- ✅ Stack tespiti: Node.js, TypeScript, Electron, Python, Rust, Swift, Kotlin, Flutter, Go
- ✅ Her bilgisayarda `git clone` = CLAUDE.md hazır

## Nasıl Kullanılır

1. GitHub'da bu repo'yu aç → **"Use this template"** butonuna tıkla
2. Yeni repo adını ver → oluştur
3. Kodunu yaz, ilk `push`'u yap
4. GitHub Actions stack'i algılar → `CLAUDE.md`'yi otomatik oluşturur ve commit eder
5. `git pull` → CLAUDE.md hazır!

## Desteklenen Stack'ler

| Dosya | Teknoloji |
|-------|-----------|
| `package.json` + `tsconfig.json` | TypeScript / React |
| `package.json` + electron | Electron |
| `package.json` | Node.js |
| `pyproject.toml` / `setup.py` | Python |
| `Cargo.toml` | Rust |
| `Package.swift` | Swift / iOS |
| `build.gradle` | Kotlin / Android |
| `pubspec.yaml` | Flutter |
| `go.mod` | Go |
