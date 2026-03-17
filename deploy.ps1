# ==============================================================
#  REVER - Build Flutter Web + Deploy to Firebase Hosting
#  Usage: .\deploy.ps1
#  Options: -SkipBuild   (deploy already-compiled output only)
#           -SkipDeploy  (build only, skip Firebase deploy)
# ==============================================================
param(
    [switch]$SkipBuild,
    [switch]$SkipDeploy
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RootDir = $PSScriptRoot

# -- 1. Load .env ----------------------------------------------
$EnvFile = Join-Path $RootDir ".env"
if (-not (Test-Path $EnvFile)) {
    Write-Error ".env not found at $RootDir"
    exit 1
}

$env_vars = @{}
Get-Content $EnvFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line -split "=", 2
        if ($parts.Count -eq 2) {
            $env_vars[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
}

# -- 2. Validate required keys ---------------------------------
$required = @("GROQ_API_KEY", "SHOPIFY_STORE_DOMAIN", "SHOPIFY_STOREFRONT_PUBLIC_TOKEN")
foreach ($key in $required) {
    if (-not $env_vars.ContainsKey($key) -or $env_vars[$key] -eq "") {
        Write-Error "Missing key '$key' in .env"
        exit 1
    }
}

Write-Host "[OK] Keys validated" -ForegroundColor Green
Write-Host "     Store : $($env_vars['SHOPIFY_STORE_DOMAIN'])"
$tokenPreview = $env_vars['SHOPIFY_STOREFRONT_PUBLIC_TOKEN'].Substring(0, [Math]::Min(8, $env_vars['SHOPIFY_STOREFRONT_PUBLIC_TOKEN'].Length))
Write-Host "     Token : ${tokenPreview}..."
Write-Host ""

# -- 3. Run tests ----------------------------------------------
Write-Host "[TEST] Running test suite before deploy..." -ForegroundColor Cyan

$FlutterAppDir = Join-Path $RootDir "flutter_app"
$ChatbotDir = Join-Path $RootDir "rever-chatbot"

# Flutter unit tests (VM-compatible: models, services, config)
Write-Host "[TEST] Running Flutter unit tests..." -ForegroundColor Cyan
Push-Location $FlutterAppDir
& flutter test test/models/ test/services/ test/config/ test/widget_test.dart --reporter=compact
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Error "Flutter tests FAILED (exit code $LASTEXITCODE) — deploy aborted."
    exit 1
}
Pop-Location
Write-Host "[OK] Flutter tests passed" -ForegroundColor Green

# Node.js tests
Write-Host "[TEST] Running Node.js tests..." -ForegroundColor Cyan
Push-Location $ChatbotDir
& npm test
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Error "Node.js tests FAILED (exit code $LASTEXITCODE) — deploy aborted."
    exit 1
}
Pop-Location
Write-Host "[OK] Node.js tests passed" -ForegroundColor Green
Write-Host ""

# -- 4. Flutter build ------------------------------------------
if (-not $SkipBuild) {
    Write-Host "[BUILD] Building Flutter Web..." -ForegroundColor Cyan

    $FlutterApp = Join-Path $RootDir "flutter_app"
    Push-Location $FlutterApp

    & flutter build web --release `
        "--dart-define=GROQ_API_KEY=$($env_vars['GROQ_API_KEY'])" `
        "--dart-define=SHOPIFY_STORE_DOMAIN=$($env_vars['SHOPIFY_STORE_DOMAIN'])" `
        "--dart-define=SHOPIFY_STOREFRONT_TOKEN=$($env_vars['SHOPIFY_STOREFRONT_PUBLIC_TOKEN'])"

    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Error "Flutter build failed (exit code $LASTEXITCODE)"
        exit 1
    }

    Pop-Location
    Write-Host "[OK] Build complete -> flutter_app/build/web" -ForegroundColor Green
    Write-Host ""
}

# -- 5. Firebase deploy ----------------------------------------
if (-not $SkipDeploy) {
    Write-Host "[DEPLOY] Deploying to Firebase Hosting..." -ForegroundColor Cyan

    Push-Location $RootDir
    & firebase deploy --only hosting

    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Error "Firebase deploy failed (exit code $LASTEXITCODE)"
        exit 1
    }
    Pop-Location

    Write-Host ""
    Write-Host "[DONE] Deploy complete!" -ForegroundColor Green
    Write-Host "       URL: https://rever-c494a.web.app" -ForegroundColor Yellow
    Write-Host ""
}
