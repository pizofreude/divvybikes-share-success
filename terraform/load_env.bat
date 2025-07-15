@echo off
REM Batch script to load environment variables for Terraform operations
REM Usage: load_env.bat

echo Loading environment variables for Terraform...

REM Try to load .env file from current directory first
if exist ".env" (
    echo Found .env in current directory
    goto :load_current
)

REM Try parent directory
if exist "../.env" (
    echo Found .env in parent directory
    goto :load_parent
)

echo ❌ .env file not found in current directory or parent directory
echo Please ensure .env file exists in the project root
echo You can copy .env.template to .env and configure it
exit /b 1

:load_current
for /f "usebackq tokens=1,2 delims==" %%a in (".env") do (
    if not "%%a"=="" if not "%%a:~0,1%"=="#" (
        set "%%a=%%b"
        echo   Set %%a
    )
)
goto :check

:load_parent
for /f "usebackq tokens=1,2 delims==" %%a in ("../.env") do (
    if not "%%a"=="" if not "%%a:~0,1%"=="#" (
        set "%%a=%%b"
        echo   Set %%a
    )
)
goto :check

:check
echo ✅ Environment variables loaded successfully

REM Check that required Terraform variables are set
if "%TF_VAR_redshift_admin_password%"=="" (
    echo ❌ TF_VAR_redshift_admin_password not set
    echo Please ensure your .env file includes:
    echo TF_VAR_redshift_admin_password=your_secure_password
    exit /b 1
)

echo ✅ Terraform environment variables ready
echo You can now run terraform commands
