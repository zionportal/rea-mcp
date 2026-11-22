@echo off
setlocal
set "ROOT=%~dp0"
set "PLAYWRIGHT_BROWSERS_PATH=%ROOT%playwright\browsers"
"%ROOT%node-v24.22.3-win-x64\node.exe" "%ROOT%playwright\node_modules\playwright\cli.js" %*
exit /b %ERRORLEVEL%
