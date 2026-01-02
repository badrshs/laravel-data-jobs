# Laravel Data Jobs - Publish to GitHub Script
# Run this script to prepare and push your package to GitHub

Write-Host "`n=== Laravel Data Jobs - GitHub Publishing ===" -ForegroundColor Cyan
Write-Host ""

# Check if git is initialized
if (-not (Test-Path ".git")) {
    Write-Host "Initializing Git repository..." -ForegroundColor Yellow
    git init
    Write-Host "[OK] Git initialized" -ForegroundColor Green
} else {
    Write-Host "[OK] Git already initialized" -ForegroundColor Green
}

# Check for uncommitted changes
$status = git status --porcelain
if ($status) {
    Write-Host "`nUncommitted changes detected. Committing..." -ForegroundColor Yellow
    git add .
    git commit -m "Prepare package for Packagist publication - v1.0.0"
    Write-Host "[OK] Changes committed" -ForegroundColor Green
} else {
    Write-Host "[OK] No uncommitted changes" -ForegroundColor Green
}

# Check if remote exists
$remote = git remote get-url origin 2>$null
if (-not $remote) {
    Write-Host "`n" -NoNewline
    Write-Host "[!] GitHub remote not configured" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please create a repository on GitHub first:"
    Write-Host "  1. Go to: https://github.com/new" -ForegroundColor Cyan
    Write-Host "  2. Name: laravel-data-jobs" -ForegroundColor Cyan
    Write-Host "  3. Make it PUBLIC" -ForegroundColor Red
    Write-Host "  4. Don't add README or license (we have them)" -ForegroundColor Cyan
    Write-Host ""
    
    $createRepo = Read-Host "Have you created the GitHub repository? (y/n)"
    
    if ($createRepo -eq 'y') {
        Write-Host "`nAdding remote..." -ForegroundColor Yellow
        git remote add origin https://github.com/badrshs/laravel-data-jobs.git
        Write-Host "[OK] Remote added" -ForegroundColor Green
    } else {
        Write-Host "`nPlease create the repository first, then run this script again." -ForegroundColor Red
        exit
    }
} else {
    Write-Host "[OK] Remote already configured: $remote" -ForegroundColor Green
}

# Push to GitHub
Write-Host "`nPushing to GitHub..." -ForegroundColor Yellow
try {
    git branch -M main
    git push -u origin main 2>&1 | Out-Null
    Write-Host "[OK] Pushed to GitHub" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to push. You may need to authenticate." -ForegroundColor Red
    Write-Host "Run manually: git push -u origin main" -ForegroundColor Yellow
}

# Create and push tag
Write-Host "`nCreating version tag v1.0.0..." -ForegroundColor Yellow
try {
    git tag -a v1.0.0 -m "Version 1.0.0 - Initial release"
    git push origin v1.0.0 2>&1 | Out-Null
    Write-Host "[OK] Version tag created and pushed" -ForegroundColor Green
} catch {
    Write-Host "[!] Tag may already exist or push failed" -ForegroundColor Yellow
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Submit to Packagist:" -ForegroundColor White
Write-Host "   https://packagist.org/packages/submit" -ForegroundColor Cyan
Write-Host "   Enter: https://github.com/badrshs/laravel-data-jobs" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. After submission, set up auto-update webhook:" -ForegroundColor White
Write-Host "   Packagist: Copy webhook URL from your package page" -ForegroundColor Cyan
Write-Host "   GitHub: Settings -> Webhooks -> Add webhook" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Your package will be available as:" -ForegroundColor White
Write-Host "   composer require badrshs/laravel-data-jobs" -ForegroundColor Green
Write-Host ""
Write-Host "[OK] Package is ready for publication!" -ForegroundColor Green
Write-Host ""
