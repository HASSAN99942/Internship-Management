# Reads DEV_HOST and FLUTTER_WEB_PORT from dev.config and syncs them into
# mobile/.env and backend/.env. Run this whenever your LAN IP changes.

$config = @{}
Get-Content "$PSScriptRoot\dev.config" | Where-Object { $_ -match '^\s*[^#]\S+=\S+' } | ForEach-Object {
    $parts = $_ -split '=', 2
    $config[$parts[0].Trim()] = $parts[1].Trim()
}

$host_ip   = $config['DEV_HOST']
$web_port  = $config['FLUTTER_WEB_PORT']

if (-not $host_ip) {
    Write-Error "DEV_HOST not found in dev.config"
    exit 1
}

# ── mobile/.env ──────────────────────────────────────────────────────────────
$mobileEnv = "$PSScriptRoot\mobile\.env"
$mobileContent = Get-Content $mobileEnv -Raw
$mobileContent = $mobileContent -replace 'API_BASE_URL=.*', "API_BASE_URL=http://$host_ip`:8000"
Set-Content $mobileEnv -Value $mobileContent.TrimEnd() -Encoding utf8
Write-Host "  mobile/.env  -> API_BASE_URL=http://$host_ip`:8000"

# ── backend/.env ─────────────────────────────────────────────────────────────
$backendEnv = "$PSScriptRoot\backend\.env"
$backendContent = Get-Content $backendEnv -Raw

$backendContent = $backendContent -replace 'ALLOWED_HOSTS=.*', "ALLOWED_HOSTS=127.0.0.1,localhost,$host_ip"
$backendContent = $backendContent -replace 'CORS_ALLOWED_ORIGINS=.*', "CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:$web_port,http://$host_ip`:$web_port"

Set-Content $backendEnv -Value $backendContent.TrimEnd() -Encoding utf8
Write-Host "  backend/.env -> ALLOWED_HOSTS includes $host_ip"
Write-Host "  backend/.env -> CORS_ALLOWED_ORIGINS includes http://$host_ip`:$web_port"

Write-Host ""
Write-Host "Done. Restart Django:  python manage.py runserver $host_ip`:8000"
