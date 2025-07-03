@echo off
REM Python executor for Gemini CLI MCP on Windows
REM Executes Python code safely

if "%1"=="run" goto :run
if "%1"=="file" goto :file
if "%1"=="version" goto :version
if "%1"=="help" goto :help
goto :usage

:run
REM Execute Python code from argument
if not "%~2"=="" (
    python -c "%~2"
) else (
    echo Error: No code provided
    exit /b 1
)
goto :end

:file
REM Execute Python file with optional arguments
shift
python %*
goto :end

:version
REM Get Python version
python --version
goto :end

:help
REM Get help
python --help
goto :end

:usage
echo Usage: %0 {run^|file^|version^|help} [code/file] [args...]
echo Examples:
echo   %0 run "print('Hello World')"
echo   %0 file script.py
echo   %0 file script.py arg1 arg2
echo   %0 version
exit /b 1

:end