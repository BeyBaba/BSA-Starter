# bootstrap/ — Çıplak Windows makinesini BSA çekirdek ortamına getirme

## Yeni makine (çıplak)

1. Repoyu ZIP olarak indir (ya da yalnız bu iki dosyayı): `bootstrap\bootstrap-core.bat` + `bootstrap\bootstrap-core.ps1` (aynı klasörde dursunlar).
2. `bootstrap-core.bat` dosyasına **çift tıkla** → yönetici izni ister (UAC), onayla.
3. Bitince log: `%USERPROFILE%\Downloads\bootstrap-log.txt` (önceki koşu `bootstrap-log.txt.onceki`).

Tek satırlık alternatif — **yönetici** PowerShell'de:

```
irm https://raw.githubusercontent.com/BeyBaba/BSA-Starter/main/bootstrap/bootstrap-core.ps1 | iex
```

### Ne yapar (v6.2)
| Adım | İş |
|---|---|
| 0/9 | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` (Restricted iken npm `claude.ps1` shim'i PowerShell'de çalışmaz) |
| 1/9 | Git + Git\bin kalıcı User PATH (git-bash) |
| 2/9 | Node.js ≥ 20 |
| 3/9 | Gerçek Python (WindowsApps Store sahtesi sayılmaz, sahte kısayollar kaldırılır) |
| 4/9 – 5/9 | GitHub CLI, jq |
| 6/9 | Claude Code CLI — kontrol **çalıştırma testi** (`claude --version` çıkış 0 + "Claude Code") |
| 7/9 | Claude Desktop (MSIX `Get-AppxPackage` tespiti, yoksa choco) |
| 8/9 | `%USERPROFILE%\Projects\` altına BigBrain + BSA-Starter clone/pull |
| 9/9 | `bash hooks/install.sh --seed-memory` (+ doctor) |
| Login turu | `claude auth status` → `loggedIn`; girişsizse `claude auth login` / `gh auth login` **ayrı PowerShell penceresinde** başlatılır. Onayı tarayıcıda sen verirsin; betik kimlik bilgisi girmez. |

Makine-bağımsız: sabit kullanıcı yolu yoktur (`$env:USERPROFILE`). Betik ASCII tutulur (PS 5.1 BOM'suz UTF-8'i yanlış okur); `.bat` CRLF'dir (`.gitattributes`).
