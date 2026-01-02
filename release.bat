@echo off
setlocal enabledelayedexpansion

echo ========================================
echo    Dynamic Image Composer Release
echo ========================================
echo.

REM Get the last tag
echo Fetching latest tag...
git describe --tags --abbrev=0 > temp_tag.txt 2>&1
set /p LAST_TAG=<temp_tag.txt
del temp_tag.txt

REM Check if tag retrieval failed
echo %LAST_TAG% | find "fatal" >nul
if %errorlevel% equ 0 (
    echo No previous tags found. Starting from v1.0.0
    set LAST_TAG=v1.0.0
    set NEXT_TAG=v1.0.0
) else (
    echo Last tag: !LAST_TAG!
    echo.

    REM Extract version numbers (remove 'v' prefix)
    set VERSION=!LAST_TAG:v=!

    REM Split version into parts
    for /f "tokens=1,2,3 delims=." %%a in ("!VERSION!") do (
        set MAJOR=%%a
        set MINOR=%%b
        set PATCH=%%c
    )

    REM Increment patch version
    set /a PATCH+=1
    set NEXT_TAG=v!MAJOR!.!MINOR!.!PATCH!
)

echo.
echo ========================================
echo Stage 1: Commit Changes
echo ========================================
echo.

REM Show git status
git status --short

echo.
set /p COMMIT_MSG="Enter commit message: "

if "%COMMIT_MSG%"=="" (
    echo Error: Commit message cannot be empty!
    pause
    exit /b 1
)

echo.
echo Staging all changes...
git add .

echo Committing with message: %COMMIT_MSG%
git commit -m "%COMMIT_MSG%"

if errorlevel 1 (
    echo.
    echo Error: Commit failed or nothing to commit!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Stage 2: Create Tag
echo ========================================
echo.

echo Suggested next tag: %NEXT_TAG%
set /p TAG_VERSION="Enter tag version [%NEXT_TAG%]: "

if "%TAG_VERSION%"=="" (
    set TAG_VERSION=%NEXT_TAG%
)

REM Ensure tag starts with 'v'
if not "!TAG_VERSION:~0,1!"=="v" (
    set TAG_VERSION=v!TAG_VERSION!
)

echo.
echo Creating tag: %TAG_VERSION%
git tag %TAG_VERSION%

if errorlevel 1 (
    echo.
    echo Error: Failed to create tag!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Stage 3: Push to Remote
echo ========================================
echo.

echo Pushing commits...
git push origin main

if errorlevel 1 (
    echo.
    echo Error: Failed to push commits!
    pause
    exit /b 1
)

echo.
echo Pushing tag: %TAG_VERSION%
git push origin %TAG_VERSION%

if errorlevel 1 (
    echo.
    echo Error: Failed to push tag!
    pause
    exit /b 1
)

echo.
echo ========================================
echo    Release Complete! 🎉
echo ========================================
echo.
echo Tag created: %TAG_VERSION%
echo Packagist will auto-update in a few minutes.
echo.
echo View release: https://github.com/badrshs/laravel-dynamic-image-composer/releases/tag/%TAG_VERSION%
echo View package: https://packagist.org/packages/badrshs/laravel-dynamic-image-composer
echo.

pause
