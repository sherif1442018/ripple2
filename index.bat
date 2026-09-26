@echo off
setlocal
pushd "%~dp0"

where node >nul 2>&1
if errorlevel 1 (
  echo Node.js is not installed. Download it from https://nodejs.org/
  pause
  exit /b 1
)

if not exist "node_modules\" (
  echo Installing dependencies...
  call npm.cmd install
  if errorlevel 1 (
    echo npm install failed.
    pause
    exit /b 1
  )
)

start "Ripple Dev Server" cmd /k "npm.cmd run dev"

echo Waiting for http://localhost:3000 ...
set /a tries=0
:waitloop
timeout /t 2 /nobreak >nul
set /a tries+=1
if %tries% gtr 45 (
  echo Server did not start in time. Check the "Ripple Dev Server" window for errors.
  pause
  exit /b 1
)
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:3000' -UseBasicParsing -TimeoutSec 3; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }"
if errorlevel 1 goto waitloop

start "" http://localhost:3000
popd
endlocal
