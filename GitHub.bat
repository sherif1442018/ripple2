@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "REMOTE_URL=https://github.com/sherif1442018/ripple-final.git"
set "BRANCH=main"
set "COMMIT_MSG=Prepare GitHub upload"

where git >nul 2>nul
if errorlevel 1 (
  echo Git is not installed or not in PATH.
  echo Install Git from: https://git-scm.com/download/win
  echo Then run this file again.
  pause
  exit /b 1
)

if not exist .git (
  echo Initializing Git repository...
  git init
)

if not exist .gitignore (
  echo Creating .gitignore...
  copy NUL .gitignore >nul
)

call :ensure_ignored ".env"
call :ensure_ignored ".env.local"
call :ensure_ignored ".env.*"
call :ensure_ignored "node_modules"
call :ensure_ignored ".next"
call :ensure_ignored "out"
call :ensure_ignored "dist"
call :ensure_ignored "build"
call :ensure_ignored "*.log"
call :ensure_ignored "npm-debug.log*"
call :ensure_ignored "*.pem"
call :ensure_ignored "*.bak"
call :ensure_ignored "*.sqlite"
call :ensure_ignored "*.zip"
call :ensure_ignored "*.rar"
call :ensure_ignored "*.7z"

rem Use a clean main branch.
git checkout -B %BRANCH% >nul 2>&1

rem Stage files.
git add .

rem Commit only if there are staged changes.
git diff --cached --quiet
if errorlevel 1 (
  git commit -m "%COMMIT_MSG%"
) else (
  echo No changes to commit.
)

rem Add remote only if it's missing.
git remote get-url origin >nul 2>nul
if errorlevel 1 (
  git remote add origin "%REMOTE_URL%"
)

rem Optional: update remote URL if you want to change target.
rem git remote set-url origin "%REMOTE_URL%"

echo.
echo =====================================
echo Uploading to GitHub...
echo Repo: %REMOTE_URL%
echo Branch: %BRANCH%
echo=====================================

git push -u origin %BRANCH%
if errorlevel 1 (
  echo.
  echo Push failed. Please log in to GitHub and retry.
  echo If your repo is private, use GitHub login or an access token.
  pause
  exit /b 1
)

echo.
echo Project was pushed successfully.
pause
exit /b 0

:ensure_ignored
set "entry=%~1"
findstr /R /C:"^%entry%$" .gitignore >nul 2>nul
if errorlevel 1 (
  >> .gitignore echo %entry%
)
exit /b 0
