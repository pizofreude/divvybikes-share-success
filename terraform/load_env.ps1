# PowerShell script to load environment variables for Terraform operations
# Usage: . .\load_env.ps1 (note the dot space before the script name)

function Load-EnvFile {
    param([string]$FilePath)
    
    if (Test-Path $FilePath) {
        Write-Host "Loading environment variables from $FilePath..." -ForegroundColor Green
        Get-Content $FilePath | ForEach-Object {
            if ($_ -match "^\s*([^#][^=]*)\s*=\s*(.*)\s*$") {
                $name = $matches[1].Trim()
                $value = $matches[2].Trim()
                # Remove quotes if present
                $value = $value -replace '^["'']|["'']$'
                Set-Item -Path "env:$name" -Value $value
                Write-Host "  Set $name" -ForegroundColor Gray
            }
        }
        return $true
    }
    return $false
}

# Try to load .env file from current directory first, then parent directory
$envLoaded = $false

if (Load-EnvFile ".env") {
    $envLoaded = $true
} elseif (Load-EnvFile "../.env") {
    $envLoaded = $true
} else {
    Write-Host "❌ .env file not found in current directory or parent directory" -ForegroundColor Red
    Write-Host "Please ensure .env file exists in the project root" -ForegroundColor Yellow
    Write-Host "You can copy .env.template to .env and configure it" -ForegroundColor Yellow
    exit 1
}

if ($envLoaded) {
    Write-Host "✅ Environment variables loaded successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to load environment variables" -ForegroundColor Red
    exit 1
}

# Check that required Terraform variables are set
if (-not $env:TF_VAR_redshift_admin_password) {
    Write-Host "❌ TF_VAR_redshift_admin_password not set" -ForegroundColor Red
    Write-Host "Please ensure your .env file includes:" -ForegroundColor Yellow
    Write-Host "TF_VAR_redshift_admin_password=your_secure_password" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Terraform environment variables ready" -ForegroundColor Green
Write-Host "You can now run terraform commands" -ForegroundColor Cyan
