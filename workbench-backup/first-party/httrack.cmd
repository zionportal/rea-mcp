@echo off
"%~dp0httrack\httrack\httrack.exe" %*
exit /b %ERRORLEVEL%
