param(
    [string]$Branch = ""
)

$ErrorActionPreference = "Stop"

function Write-Banner($text) {
    $line = "=" * 50
    Write-Host "`n$line" -ForegroundColor Cyan
    Write-Host "  $text" -ForegroundColor White
    Write-Host "$line`n" -ForegroundColor Cyan
}

function Get-NextVersion([string]$lastTag, [string]$bumpType) {
    if (-not $lastTag -or $lastTag -match "fatal") {
        return "v1.0.0"
    }

    $version = $lastTag -replace '^v', ''
    $parts = $version -split '\.'

    $major = [int]$parts[0]
    $minor = if ($parts.Count -gt 1) { [int]$parts[1] } else { 0 }
    $patch = if ($parts.Count -gt 2) { [int]$parts[2] } else { 0 }

    switch ($bumpType) {
        "1" { $patch++ }                               # patch
        "2" { $minor++; $patch = 0 }                   # minor
        "3" { $major++; $minor = 0; $patch = 0 }       # major
        default { $patch++ }                            # default to patch
    }

    return "v$major.$minor.$patch"
}

# -- Detect current branch ----------------------
if ([string]::IsNullOrWhiteSpace($Branch)) {
    $Branch = git branch --show-current 2>$null
    if ([string]::IsNullOrWhiteSpace($Branch)) {
        Write-Host "  Could not detect current branch. Use -Branch to specify one." -ForegroundColor Red
        exit 1
    }
}

# -- Validate remote -----------------------------
$remote = (git remote 2>$null | Select-Object -First 1)
if ([string]::IsNullOrWhiteSpace($remote)) {
    Write-Host "  No git remote configured. Add one with:" -ForegroundColor Red
    Write-Host "    git remote add origin <url>" -ForegroundColor Yellow
    exit 1
}

# -- Header ---------------------------------------
Write-Banner "Content Publisher Release"

# -- Detect last tag (highest version, not nearest commit) --
$lastTag = $null
try {
    $lastTag = (git tag --sort=-v:refname 2>&1) | Where-Object { $_ -match '^v?\d+\.\d+' } | Select-Object -First 1
} catch {}

Write-Host "  Remote:        " -NoNewline; Write-Host $remote -ForegroundColor Cyan
Write-Host "  Branch:        " -NoNewline; Write-Host $Branch -ForegroundColor Cyan
if ($lastTag) {
    Write-Host "  Last tag:      " -NoNewline; Write-Host $lastTag -ForegroundColor Yellow
} else {
    Write-Host "  No previous tags found." -ForegroundColor DarkGray
}
Write-Host ""

# -- Choose bump type --------------------------------
Write-Banner "Version Bump"

Write-Host "  [1] Patch   [2] Minor   [3] Major" -ForegroundColor DarkGray
$bumpType = Read-Host "  Release type"

$nextTag = Get-NextVersion $lastTag $bumpType
Write-Host "  Next version:  " -NoNewline; Write-Host $nextTag -ForegroundColor Green
Write-Host ""

# -- Stage 1: Commit if needed ----------------------
Write-Banner "Stage 1: Commit Changes"

$status = git status --short
if (-not $status) {
    Write-Host "  Working tree clean -- skipping commit." -ForegroundColor DarkGray
} else {
    Write-Host "  Changed files:" -ForegroundColor DarkGray
    $status | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
    Write-Host ""

    $commitMsg = Read-Host "  Commit message (Enter to skip)"
    if (-not [string]::IsNullOrWhiteSpace($commitMsg)) {
        git add .
        git commit -m $commitMsg
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Commit failed." -ForegroundColor Red
            exit 1
        }
        Write-Host "  Committed." -ForegroundColor Green
    } else {
        Write-Host "  Skipping commit." -ForegroundColor DarkGray
    }
}

# -- Stage 2: Tag -----------------------------------
Write-Banner "Stage 2: Create Tag"

$inputTag = Read-Host "  Tag version [$nextTag]"
if ([string]::IsNullOrWhiteSpace($inputTag)) {
    $inputTag = $nextTag
}
if ($inputTag -notmatch '^v') {
    $inputTag = "v$inputTag"
}

# Validate semver-ish format
if ($inputTag -notmatch '^v\d+\.\d+\.\d+$') {
    Write-Host "  Warning: '$inputTag' doesn't look like semver (vX.Y.Z). Continue? [y/N] " -ForegroundColor Yellow -NoNewline
    $confirm = Read-Host
    if ($confirm -ne 'y') {
        Write-Host "  Aborted." -ForegroundColor Red
        exit 1
    }
}

# Check tag doesn't already exist
$existingTags = git tag --list $inputTag
if ($existingTags) {
    Write-Host "  Tag '$inputTag' already exists!" -ForegroundColor Red
    exit 1
}

git tag $inputTag
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Failed to create tag." -ForegroundColor Red
    exit 1
}
Write-Host "  Tag created: $inputTag" -ForegroundColor Green

# -- Stage 3: Push ----------------------------------
Write-Banner "Stage 3: Push to Remote"

Write-Host "  Pushing commits to $remote/$Branch..." -ForegroundColor DarkGray
git push $remote $Branch
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Failed to push commits." -ForegroundColor Red
    exit 1
}

Write-Host "  Pushing tag $inputTag..." -ForegroundColor DarkGray
git push $remote $inputTag
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Failed to push tag." -ForegroundColor Red
    exit 1
}

# -- Done -------------------------------------------
Write-Banner "Release Complete!"

Write-Host "  Tag:     $inputTag" -ForegroundColor Green
Write-Host "  Branch:  $Branch" -ForegroundColor Green
Write-Host ""
Write-Host "  Packagist will auto-update shortly." -ForegroundColor DarkGray
Write-Host ""
