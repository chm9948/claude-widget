# claude-widget 경량 설치 스크립트 (관리자 권한 불필요)
#
# 설치:
#   powershell -ExecutionPolicy Bypass -Command "iex (irm 'https://raw.githubusercontent.com/chm9948/claude-widget/main/setup.ps1')"
#
# 제거:
#   powershell -ExecutionPolicy Bypass -Command "$ClaudeWidgetUninstall=$true; iex (irm 'https://raw.githubusercontent.com/chm9948/claude-widget/main/setup.ps1')"

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$appName    = 'ClaudeWidget'
$installDir = Join-Path $env:LOCALAPPDATA $appName
$exePath    = Join-Path $installDir 'claude-widget.exe'
$exeUrl     = 'https://github.com/chm9948/claude-widget/raw/main/claude-widget.exe'
$startMenu  = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$lnkPath    = Join-Path $startMenu 'Claude Widget.lnk'
$runKey     = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

# 실행 중인 인스턴스 종료 (덮어쓰기/제거 가능하도록)
Get-Process -Name 'claude-widget' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600

# ── 제거 모드 ────────────────────────────────────────────────
if ($ClaudeWidgetUninstall) {
    if (Test-Path $lnkPath)    { Remove-Item $lnkPath -Force }
    Remove-ItemProperty -Path $runKey -Name $appName -ErrorAction SilentlyContinue
    if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force }
    Write-Host ''
    Write-Host '  제거 완료. (설치 폴더 / 시작메뉴 바로가기 / 자동실행 등록 삭제)' -ForegroundColor Green
    return
}

# ── 설치 모드 ────────────────────────────────────────────────
Write-Host ''
Write-Host '  Claude Widget 설치 중...' -ForegroundColor Cyan

New-Item -ItemType Directory -Path $installDir -Force | Out-Null

# 최신 exe 다운로드 (Invoke-WebRequest 로 받으면 외부출처 표시가 안 붙음)
Invoke-WebRequest -Uri $exeUrl -OutFile $exePath -UseBasicParsing
Unblock-File $exePath   # 혹시 모를 차단 표시 제거 → SmartScreen 경고 방지

# 시작 메뉴 바로가기 생성
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnkPath)
$sc.TargetPath       = $exePath
$sc.WorkingDirectory = $installDir
$sc.IconLocation     = $exePath
$sc.Description       = 'Claude Code 사용량 위젯'
$sc.Save()

# 실행
Start-Process $exePath

Write-Host ''
Write-Host '  설치 완료!' -ForegroundColor Green
Write-Host "    위치     : $exePath"
Write-Host '    시작메뉴 : Claude Widget'
Write-Host '    자동실행 : 트레이 아이콘 우클릭 메뉴에서 켜기/끄기'
Write-Host '    제거     : README 의 제거 명령 참고'
Write-Host ''
