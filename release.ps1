# Dynamic Image Composer Release Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Dynamic Image Composer Release" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get the last tag
Write-Host "Fetching latest tag..." -ForegroundColor Yellow
$lastTag = git describe --tags --abbrev=0 2>$null

if (-not $lastTag) {
    Write-Host "No previous tags found. Starting from v1.0.0" -ForegroundColor Yellow
    $lastTag = "v1.0.0"
    $nextTag = "v1.0.0"
} else {
    Write-Host "Last tag: " -NoNewline -ForegroundColor Green
    Write-Host $lastTag -ForegroundColor White
    Write-Host ""
    
    # Parse version and increment patch
    $version = $lastTag -replace '^v', ''
    $parts = $version.Split('.')
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]
    $patch++
    
    $nextTag = "v$major.$minor.$patch"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Stage 1: Commit Changes" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Show git status
git status --short

Write-Host ""
$commitMsg = Read-Host "Enter commit message [Release $nextTag]"

if ([string]::IsNullOrWhiteSpace($commitMsg)) {
    $commitMsg = "Release $nextTag"
}

Write-Host ""
Write-Host "Staging all changes..." -ForegroundColor Yellow
git add .

Write-Host "Committing with message: $commitMsg" -ForegroundColor Yellow
git commit -m $commitMsg

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Error: Commit failed or nothing to commit!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Stage 2: Create Tag" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Suggested next tag: " -NoNewline -ForegroundColor Green
Write-Host $nextTag -ForegroundColor White
$tagVersion = Read-Host "Enter tag version [$nextTag]"

if ([string]::IsNullOrWhiteSpace($tagVersion)) {
    $tagVersion = $nextTag
}

# Ensure tag starts with 'v'
if (-not $tagVersion.StartsWith('v')) {
    $tagVersion = "v$tagVersion"
}

Write-Host ""
Write-Host "Creating tag: $tagVersion" -ForegroundColor Yellow
git tag $tagVersion

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Error: Failed to create tag!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Stage 3: Push to Remote" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Pushing commits..." -ForegroundColor Yellow
git push origin main

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Error: Failed to push commits!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Pushing tag: $tagVersion" -ForegroundColor Yellow
git push origin $tagVersion

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Error: Failed to push tag!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Release Complete! 🎉" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tag created: " -NoNewline
Write-Host $tagVersion -ForegroundColor Green
Write-Host "Packagist will auto-update in a few minutes." -ForegroundColor Yellow
Write-Host ""
Write-Host "View release: " -NoNewline
Write-Host "https://github.com/badrshs/laravel-dynamic-image-composer/releases/tag/$tagVersion" -ForegroundColor Blue
Write-Host "View package: " -NoNewline
Write-Host "https://packagist.org/packages/badrshs/laravel-dynamic-image-composer" -ForegroundColor Blue
Write-Host ""
