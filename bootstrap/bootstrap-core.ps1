# BSA Bootstrap (cekirdek) v6.2
# v6.2 (v6.1 saha testinden):
#  - ExecutionPolicy: basta CurrentUser RemoteSigned (Restricted iken npm claude.ps1 shim'i PowerShell'de HIC calismiyordu).
#  - Claude Code kontrolu "Get-Command var" degil CALISTIRMA testi: claude --version cikis 0 + "Claude Code" (adim 6 + ozet).
#  - claude login kontrolu .credentials.json yerine "claude auth status" JSON -> loggedIn (parse edilemezse "bilinmiyor").
#  - Login turu: claude / gh girissizse "auth login" AYRI PowerShell penceresinde baslatilir; onayi kullanici tarayicida verir,
#    betik asla kimlik bilgisi girmez.
# v6.1 (v6 testinden): doctor tek sefer (install.sh zaten calistiriyor), cikis kodu dogru yorum, UTF-8 konsol,
#   Store sahte python kisayollari kaldirilir + Python tespiti sahteyi saymaz, Git\bin User PATH'e KALICI eklenir.
# v5'ten farklar:
#  - Start-Transcript YOK: kendi log fonksiyonu (L). Her satir hem ekrana hem dosyaya; exe ciktilari (choco, git, bash) da loga duser.
#  - "| Out-Null" YOK: komut ciktilari Run ile loga yazilir; cikis kodu != 0 ise ekranda uyari.
#  - Claude Desktop tespiti MSIX uyumlu (Get-AppxPackage) - v5 kurulu uygulamayi "EKSIK" sayiyordu.
#  - Login turu: gh zaten girisliyse atlar; Desktop'i Start menu kaydindan acar.
#  - Onceki log .onceki olarak saklanir.
# Admin'e yukseltme .bat icinde. Makine-bagimsiz: sabit kullanici yolu yok.

$ErrorActionPreference = "Continue"
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8; $OutputEncoding = [Text.Encoding]::UTF8 } catch {}
$dl  = Join-Path $env:USERPROFILE "Downloads"
$log = Join-Path $dl "bootstrap-log.txt"
New-Item -ItemType Directory -Force -Path $dl | Out-Null
if (Test-Path $log) { Copy-Item $log ($log + ".onceki") -Force }
Set-Content -Path $log -Encoding UTF8 -Value ("BSA bootstrap v6.2 | " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " | " + $env:COMPUTERNAME + "\" + $env:USERNAME + " | PS " + $PSVersionTable.PSVersion)

function L($msg, $color = "Gray") {
  Write-Host $msg -ForegroundColor $color
  Add-Content -Path $log -Value $msg -Encoding UTF8
}
function LogOnly($msg) { Add-Content -Path $log -Value $msg -Encoding UTF8 }
function Run($label, [scriptblock]$sb) {
  LogOnly ("    >> " + $label)
  $global:LASTEXITCODE = 0
  try { & $sb 2>&1 | ForEach-Object { LogOnly ("       " + $_) } }
  catch { L ("    [HATA] " + $label + ": " + $_.Exception.Message) "Red" }
  if ($global:LASTEXITCODE -ne 0) { L ("    [!] " + $label + " -> cikis kodu " + $global:LASTEXITCODE + " (ayrinti logda)") "Yellow" }
}
function Have($c) { [bool](Get-Command $c -ErrorAction SilentlyContinue) }
function Refresh {
  $m = [Environment]::GetEnvironmentVariable("Path", "Machine"); $u = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = $m + ";" + $u + ";C:\Program Files\nodejs;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;C:\Program Files\GitHub CLI;" + $env:ProgramData + "\chocolatey\bin"
}
function Wg($wid, $ad) {
  L ("    " + $ad + " kuruluyor... (1-3 dk, pencereyi KAPATMA)") "Yellow"
  Run ("winget " + $wid) { winget install --id $wid -e --silent --accept-source-agreements --accept-package-agreements }
  Refresh
}
# Claude Code: Get-Command "var" deyip ExecutionPolicy yuzunden calismayabilir -> gercek calistirma testi
function ClaudeOk {
  if (-not (Have claude)) { return $false }
  try {
    $global:LASTEXITCODE = 0
    $v = [string]((& claude --version 2>&1 | ForEach-Object { [string]$_ }) -join " ")
    return (($global:LASTEXITCODE -eq 0) -and ($v -match "Claude Code"))
  } catch { return $false }
}
# claude auth status JSON -> loggedIn. $true / $false / $null (= bilinmiyor)
function ClaudeLoggedIn {
  if (-not (ClaudeOk)) { return $null }
  try {
    $raw = (& claude auth status 2>$null | ForEach-Object { [string]$_ }) -join "`n"
    $j = $raw | ConvertFrom-Json
    if ($null -ne $j.loggedIn) { return [bool]$j.loggedIn }
  } catch {}
  return $null
}
# git-bash tam yolu (git.exe'nin iki ust klasoru\bin\bash.exe; ucrt64/mingw64 duzenleri icin bir ust daha); bulunamazsa $null
function GitBash {
  $g = Get-Command git -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $g) { return $null }
  $d = Split-Path $g.Source
  foreach ($root in @((Split-Path $d), (Split-Path (Split-Path $d)))) {
    if ($root) { $b = Join-Path $root "bin\bash.exe"; if (Test-Path $b) { return $b } }
  }
  return $null
}
# Interaktif login'i AYRI pencerede baslatir; kimlik bilgisini kullanici tarayicida verir
function AyriPencere($cmd) { Start-Process powershell -ArgumentList '-NoExit', '-Command', $cmd }
function NodeMajor { if (Have node) { try { return [int](((node --version) -replace "v", "").Split(".")[0]) } catch { return 0 } }; return 0 }
# Gercek Python: WindowsApps altindaki Store sahte kisayolunu SAYMAZ (sahte, kurulumu atlatiyordu)
function RealPy { Get-Command python -All -ErrorAction SilentlyContinue | Where-Object { $_.Source -notmatch "\\WindowsApps\\" } | Select-Object -First 1 }
function PyVer { $p = RealPy; if ($p) { try { return [string](& $p.Source --version 2>&1) } catch { return "" } }; return "" }
function StoreAliasSil {
  $wa = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps"
  foreach ($n in @("python.exe", "python3.exe")) { $f = Join-Path $wa $n; if (Test-Path $f) { Remove-Item $f -Force -ErrorAction SilentlyContinue; L ("    Store sahte kisayolu kaldirildi: " + $n) "DarkYellow" } }
}
function GitBinKalici {
  $g = Get-Command git -ErrorAction SilentlyContinue; if (-not $g) { return }
  $gb = Join-Path (Split-Path (Split-Path $g.Source)) "bin"
  if (-not (Test-Path (Join-Path $gb "bash.exe"))) { L ("    [!] bash.exe bulunamadi: " + $gb) "Yellow"; return }
  $u = [Environment]::GetEnvironmentVariable("Path", "User"); if (-not $u) { $u = "" }
  if (($u -split ";") -notcontains $gb) { [Environment]::SetEnvironmentVariable("Path", ($u.TrimEnd(";") + ";" + $gb), "User"); $global:PathDegisti = $true; L ("    Git bin User PATH'e KALICI eklendi: " + $gb) "Green" }
  else { L ("    Git bin User PATH'te: " + $gb) }
  Refresh
}

# --- Claude Desktop (MSIX veya klasik exe) ---
function DesktopPkg { Get-AppxPackage -Name "Claude" -ErrorAction SilentlyContinue | Select-Object -First 1 }
function DesktopVar {
  if (DesktopPkg) { return $true }
  foreach ($p in @((Join-Path $env:LOCALAPPDATA "AnthropicClaude\claude.exe"), (Join-Path $env:LOCALAPPDATA "Programs\Claude\Claude.exe"))) { if (Test-Path $p) { return $true } }
  return $false
}
function DesktopAc {
  $app = Get-StartApps -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "Claude" } | Select-Object -First 1
  if ($app) { Start-Process "explorer.exe" ("shell:AppsFolder\" + $app.AppID); return $true }
  return $false
}

Clear-Host
L "==================================================" "Cyan"
L "   BSA KURULUM v6.2 (cekirdek + Desktop + login)" "Cyan"
L "==================================================" "Cyan"
$proj = Join-Path $env:USERPROFILE "Projects"

# ExecutionPolicy: Restricted/Undefined iken npm'in claude.ps1 shim'i PowerShell'de calismaz
L "[0/9] PowerShell ExecutionPolicy (CurrentUser)" "White"
try {
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
  L ("    CurrentUser=RemoteSigned ayarlandi; etkin: " + (Get-ExecutionPolicy)) "Green"
} catch {
  L ("    [!] Set-ExecutionPolicy basarisiz (GPO olabilir): " + $_.Exception.Message) "Yellow"
  L ("    etkin politika: " + (Get-ExecutionPolicy) + " | CurrentUser: " + (Get-ExecutionPolicy -Scope CurrentUser)) "Yellow"
}
Refresh
if (-not (Have winget)) { L "[DUR] winget yok. App Installer (Microsoft Store) kur, tekrar calistir." "Red"; Read-Host "ENTER ile kapat"; return }

L "[1/9] Git (+ bash kalici PATH)" "White"
if (Have git) { L ("    var: " + (git --version)) } else { Wg "Git.Git" "Git" }
GitBinKalici

L "[2/9] Node.js (min v20)" "White"
if (Have node) {
  $nm = NodeMajor
  if ($nm -ge 20) { L ("    var: " + (node --version) + " (OK, >=20)") }
  else {
    L ("    [!] ESKI: " + (node --version) + " < v20 - guncelleniyor...") "Yellow"
    Run "winget upgrade Node" { winget upgrade --id OpenJS.NodeJS.LTS -e --silent --accept-source-agreements --accept-package-agreements }
    Refresh
  }
} else { Wg "OpenJS.NodeJS.LTS" "Node.js" }

L "[3/9] Python" "White"
if (-not (RealPy)) { Wg "Python.Python.3.12" "Python" }
if (RealPy) {
  $pv = PyVer
  L ("    var: " + $pv + "  (" + (RealPy).Source + ")")
  if ($pv -match "3\.14") { L "    [not] 3.14 cok yeni; fetch MCP tam-kurulumda 3.12 venv isteyebilir." "DarkYellow" }
  StoreAliasSil
} else { L "    [!] Python kurulamadi - ayrinti logda" "Red" }

L "[4/9] GitHub CLI (gh)" "White"
if (Have gh) { L ("    var: " + ((gh --version) | Select-Object -First 1)) } else { Wg "GitHub.cli" "GitHub CLI" }

L "[5/9] jq" "White"
if (Have jq) { L ("    var: " + (jq --version)) } else { Wg "jqlang.jq" "jq" }

L "[6/9] Claude Code (CLI)" "White"
if (ClaudeOk) { L ("    var (calisiyor): " + ((& claude --version 2>&1 | ForEach-Object { [string]$_ }) -join " ")) }
elseif (Have claude) { L "    [!] claude PATH'te var ama CALISMIYOR (ExecutionPolicy / bozuk shim?) - adim 0 ciktisina bak" "Yellow" }
elseif (Have npm) { L "    npm ile kuruluyor..." "Yellow"; Run "npm i -g claude-code" { npm install -g @anthropic-ai/claude-code }; Refresh }
else { L "    [!] npm yok (Node yeni kuruldu, PATH henuz oturumda yok) - bat'i bir kez daha calistir" "Yellow" }

L "[7/9] Claude Desktop (GUI)" "White"
if (DesktopVar) {
  $p = DesktopPkg
  if ($p) { L ("    var: MSIX " + $p.Version) } else { L "    var: (klasik exe)" }
} else {
  if (-not (Have choco)) {
    L "    choco yok - once choco kuruluyor..." "Yellow"
    Run "choco kurulum" { Set-ExecutionPolicy Bypass -Scope Process -Force; [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object Net.WebClient).DownloadString("https://community.chocolatey.org/install.ps1")) }
    Refresh
  }
  if (Have choco) {
    L "    Claude Desktop kuruluyor (choco)..." "Yellow"
    Run "choco install claude" { choco install claude -y --no-progress }
    if (-not (DesktopVar)) {
      L "    choco 'kurulu' diyor ama uygulama yok - zorla yeniden kuruluyor..." "Yellow"
      Run "choco install claude --force" { choco install claude -y --no-progress --force }
    }
  }
  if (DesktopVar) { L "    kuruldu" "Green" } else { L "    [!] kurulamadi - ayrinti logda" "Red" }
}

L "[8/9] Repolar (BigBrain + BSA-Starter)" "White"
New-Item -ItemType Directory -Force -Path $proj | Out-Null
if (Have git) {
  foreach ($r in @("BigBrain", "BSA-Starter")) {
    $d = Join-Path $proj $r
    if (Test-Path (Join-Path $d ".git")) { L ("    guncelleniyor: " + $r) "Yellow"; Run ("git pull " + $r) { git -C $d pull --ff-only } }
    else { L ("    indiriliyor: " + $r) "Yellow"; Run ("git clone " + $r) { git clone ("https://github.com/BeyBaba/" + $r) $d } }
  }
} else { L "    [!] git PATH'te yok" "Yellow" }

L "[9/9] BSA altyapi (seed dahil) + doctor" "White"
$inst = Join-Path $proj "BSA-Starter\hooks\install.sh"
$doc  = Join-Path $proj "BSA-Starter\hooks\bsa-doctor.sh"
function Renkli($s) {
  $c = "Gray"; if ($s -match "^\s*FAIL") { $c = "Red" } elseif ($s -match "^\s*WARN") { $c = "DarkYellow" } elseif ($s -match "^\s*PASS") { $c = "DarkGray" } elseif ($s -match "===") { $c = "Cyan" }
  L ("    " + $s) $c
}
# v6.2: PATH'teki ilk "bash" WSL (System32\bash.exe) olabilir -> git-bash TAM yolu kullanilir
$gbash = GitBash
if (-not $gbash) { L "    [!] git-bash (Git\bin\bash.exe) bulunamadi" "Yellow" }
elseif (Test-Path $inst) {
  # install.sh sonunda doctor'i KENDISI calistirir -> ayrica cagirmiyoruz (v6'da iki kez calisiyordu)
  L ("    install.sh + doctor calisiyor (~1 dk)... bash: " + $gbash) "Yellow"
  $global:LASTEXITCODE = 0
  $out = @(& $gbash $inst --seed-memory 2>&1 | ForEach-Object { [string]$_ })
  $ic = $global:LASTEXITCODE
  $out | ForEach-Object { Renkli $_ }
  $docVar = [bool]($out | Where-Object { $_ -match "=== bsa doctor ===" })
  if (-not $docVar -and (Test-Path $doc)) { L "    --- bsa doctor ---" "Cyan"; & $gbash $doc 2>&1 | ForEach-Object { Renkli ([string]$_) } }
  $sonuc = $out | Where-Object { $_ -match "SONUC: PASS=" } | Select-Object -Last 1
  if ($ic -eq 0) { L "    altyapi kuruldu, doctor temiz" "Green" }
  elseif ($sonuc -match "FAIL=[1-9]") { L ("    altyapi kuruldu; doctor FAIL bulgusu var (kurulum hatasi DEGIL): " + $sonuc.Trim()) "Yellow" }
  else { L ("    [!] install.sh cikis kodu " + $ic + " - yukaridaki satirlara bak") "Red" }
} else { L ("    [!] install.sh yok: " + $inst) "Yellow" }

L ""
L "==================================================" "Green"
L "   KURULUM OZETI" "Green"
L "==================================================" "Green"
foreach ($c in @("git", "node", "npm", "gh", "jq")) { if (Have $c) { L ("  OK    " + $c) "Green" } else { L ("  EKSIK " + $c) "Red" } }
if (GitBash) { L ("  OK    git-bash (" + (GitBash) + ")") "Green" } else { L "  EKSIK git-bash" "Red" }
if (ClaudeOk) { L "  OK    claude (calistirma testi)" "Green" }
elseif (Have claude) { L "  EKSIK/ENGELLI claude (PATH'te var, calismiyor)" "Red" }
else { L "  EKSIK claude" "Red" }
if (RealPy) { L "  OK    python (gercek)" "Green" } else { L "  EKSIK python (gercek)" "Red" }
if (DesktopVar) { L "  OK    Claude Desktop" "Green" } else { L "  EKSIK Claude Desktop" "Red" }

L ""
L "==================================================" "Cyan"
L "   LOGIN TURU" "Cyan"
L "==================================================" "Cyan"
if (DesktopVar) {
  if (DesktopAc) { L "-> Claude Desktop acildi: pencerede hesabinla giris yap." "White" }
  else { L "-> Claude Desktop kurulu ama Start menu kaydi bulunamadi: Baslat menusunden 'Claude' ac." "Yellow" }
} else {
  L "-> Claude Desktop yok; indirme sayfasi aciliyor..." "Yellow"
  Start-Process "https://claude.ai/download"
}

$ghOk = $false
if (Have gh) { gh auth status *> $null; $ghOk = ($LASTEXITCODE -eq 0) }
$clOk = ClaudeLoggedIn

if ($ghOk) { L "-> gh: zaten giris yapilmis, atlandi." "Green" }
elseif (Have gh) {
  L "-> gh: girissiz - 'gh auth login' AYRI pencerede baslatildi; oradaki adimlari izle, onayi tarayicida ver." "White"
  AyriPencere "gh auth login"
} else { L "-> gh: kurulu degil, login atlandi." "Yellow" }

if ($clOk -eq $true) { L "-> claude: 'claude auth status' loggedIn=true, atlandi." "Green" }
elseif ($clOk -eq $false) {
  L "-> claude: girissiz (loggedIn=false) - 'claude auth login' AYRI pencerede baslatildi; onayi tarayicida ver." "White"
  AyriPencere "claude auth login"
} else {
  L "-> claude: giris durumu BILINMIYOR ('claude auth status' okunamadi / claude calismiyor)." "Yellow"
  L "   claude calisir hale gelince YENI bir PowerShell'de:  claude auth login" "Yellow"
}

L ""
L "NOT: doctor'da 'denetci-memory' FAIL gorursen repo seed'i bayattir (seed tazeleme PR'i merge edilince cozulur)." "DarkYellow"
if ($global:PathDegisti) { L "NOT: PATH degisti (Git bin) - Claude Code / terminalleri YENIDEN ac." "DarkYellow" }
L ("Log: " + $log) "Gray"
LogOnly ("BITTI " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Read-Host "Bu pencereyi kapatmak icin ENTER"
