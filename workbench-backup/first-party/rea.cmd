@echo off
setlocal
set "ROOT=%~dp0"
set "JAVA_HOME=%ROOT%jdk"
set "REA_JADX_MCP_JAR=%ROOT%downloads\jadx-headless-mcp-0.7.1-all.jar"
set "PATH=%ROOT%node-v24.22.3-win-x64;%JAVA_HOME%\bin;%ROOT%jadx\bin;%PATH%"
"%ROOT%node-v24.22.3-win-x64\node.exe" "%ROOT%runtime-packed\scripts\rea.mjs" %*
exit /b %ERRORLEVEL%
