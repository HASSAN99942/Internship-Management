# Usage: .\set-ip.ps1 192.168.2.117
# Updates the dev IP in both backend and mobile config files.

param(
    [Parameter(Mandatory=$true)]
    [string]$ip
)

$backendEnv = "backend\.env"
$mobileEnv  = "mobile\.env"

# Update backend ALLOWED_HOSTS (keep localhost entries, swap the IP)
$b = Get-Content $backendEnv -Raw
$b = $b -replace 'ALLOWED_HOSTS=.*', "ALLOWED_HOSTS=127.0.0.1,localhost,$ip"
$b = $b -replace 'CORS_ALLOWED_ORIGINS=.*', "CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:5000,http://${ip}:5000"
Set-Content $backendEnv $b -NoNewline

# Update mobile API base URL
$m = Get-Content $mobileEnv -Raw
$m = $m -replace 'API_BASE_URL=.*', "API_BASE_URL=http://${ip}:8000"
Set-Content $mobileEnv $m -NoNewline

Write-Host "IP set to $ip"
Write-Host "  backend/.env  -> ALLOWED_HOSTS and CORS updated"
Write-Host "  mobile/.env   -> API_BASE_URL=http://${ip}:8000"
Write-Host ""
Write-Host "Restart the Django server:  python manage.py runserver ${ip}:8000"
