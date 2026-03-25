#Requires -Version 5.0
# Push ShanHaiJingMod to your GitHub (needs: GitHub CLI + gh auth login once)
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $RepoRoot '.git'))) {
    Write-Host 'ERROR: .git not found. Run from ShanHaiJingMod\tools\' -ForegroundColor Red
    exit 1
}

$gh = Join-Path $env:ProgramFiles 'GitHub CLI\gh.exe'
if (-not (Test-Path -LiteralPath $gh)) {
    Write-Host "GitHub CLI not found: $gh" -ForegroundColor Red
    Write-Host 'Install: winget install GitHub.cli --source winget'
    exit 1
}

Set-Location -LiteralPath $RepoRoot
Write-Host "Repository: $RepoRoot" -ForegroundColor Cyan

# gh auth status prints to stderr when not logged in; avoid red NativeCommandError noise
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
$null = & $gh auth status 2>&1
$ghAuthOk = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = $prevEap

if (-not $ghAuthOk) {
    Write-Host ''
    Write-Host '=== Step 1: log in to GitHub (one time) ===' -ForegroundColor Yellow
    Write-Host '(尚未登录 GitHub 命令行，下面会打开登录流程；属正常情况，不是脚本坏了。)' -ForegroundColor DarkGray
    Write-Host 'Choose: GitHub.com, HTTPS, then Login with a web browser.'
    Write-Host 'After that, run this script again.'
    Write-Host ''
    & $gh auth login
    exit 0
}

git remote get-url origin 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host 'Remote origin already set. Pushing to main...' -ForegroundColor Green
    git push -u origin main
    exit $LASTEXITCODE
}

$defaultName = 'ShanHaiJingMod'
Write-Host ''
Write-Host '=== Step 2: create GitHub repo and push ===' -ForegroundColor Yellow
Write-Host "Default repo name: $defaultName"
# Use only ASCII in Read-Host prompt to avoid PowerShell 5.x parser issues
$RepoName = Read-Host 'Repo name (press Enter for default)'
if ([string]::IsNullOrWhiteSpace($RepoName)) {
    $RepoName = $defaultName
}

Write-Host "Running: gh repo create $RepoName --public --source=. --remote=origin --push" -ForegroundColor Cyan
& $gh repo create $RepoName --public --source='.' --remote='origin' --push
if ($LASTEXITCODE -eq 0) {
    Write-Host ''
    Write-Host 'Done. Open your repository in the browser.' -ForegroundColor Green
}
