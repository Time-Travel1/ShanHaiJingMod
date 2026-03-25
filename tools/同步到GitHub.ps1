#Requires -Version 5.0
# 山海经 MOD：首次把本地 Git 推到你的 GitHub（需已安装 GitHub CLI，且完成一次 gh auth login）
$ErrorActionPreference = "Stop"
# 本脚本在 tools\ 下，仓库根为上一级目录
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
    Write-Host "未在上一级找到 .git，请从 ShanHaiJingMod 仓库内运行 tools\同步到GitHub.ps1" -ForegroundColor Red
    exit 1
}

$gh = "${env:ProgramFiles}\GitHub CLI\gh.exe"
if (-not (Test-Path $gh)) {
    Write-Host "未找到 GitHub CLI：$gh" -ForegroundColor Red
    Write-Host "请用 winget 安装：winget install GitHub.cli --source winget"
    exit 1
}

Set-Location $RepoRoot
Write-Host "仓库目录: $RepoRoot" -ForegroundColor Cyan

& $gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "========== 第一步：登录 GitHub（只需做一次）==========" -ForegroundColor Yellow
    Write-Host "下面会启动交互：选 GitHub.com → HTTPS → 用浏览器登录（或粘贴令牌）。"
    Write-Host "完成后请重新运行本脚本。"
    Write-Host ""
    & $gh auth login
    exit 0
}

$remote = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "已存在远程 origin: $remote" -ForegroundColor Green
    Write-Host "正在 push 到 main ..."
    git push -u origin main
    exit $LASTEXITCODE
}

$defaultName = "ShanHaiJingMod"
Write-Host ""
Write-Host "========== 第二步：在 GitHub 上创建仓库并推送 ==========" -ForegroundColor Yellow
Write-Host "将创建公开仓库，默认名称: $defaultName（若重名请改仓库名）"
# 注意：双引号内不能写 [xxx] 形式，否则 PowerShell 会当成通配符字符类导致解析错误
$RepoName = Read-Host "仓库名（直接回车则使用 $defaultName）"
if ([string]::IsNullOrWhiteSpace($RepoName)) { $RepoName = $defaultName }

Write-Host "执行: gh repo create $RepoName --public --source=. --remote=origin --push" -ForegroundColor Cyan
& $gh repo create $RepoName --public --source=. --remote=origin --push
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "完成。在浏览器打开你的仓库页面即可。" -ForegroundColor Green
}
