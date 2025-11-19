# Script PowerShell de configuration Grafana pour le Compte Service
# Ce script configure automatiquement la source de données Prometheus et importe le dashboard

$GRAFANA_URL = "http://localhost:3000"
$GRAFANA_USER = "admin"
$GRAFANA_PASSWORD = "admin"
$PROMETHEUS_URL = "http://localhost:9091"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Configuration de Grafana" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Créer les credentials pour l'authentification
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $GRAFANA_USER, $GRAFANA_PASSWORD)))
$headers = @{
    "Authorization" = "Basic $base64AuthInfo"
    "Content-Type" = "application/json"
}

# Attendre que Grafana soit disponible
Write-Host "1. Attente de la disponibilité de Grafana..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
$grafanaReady = $false

while (-not $grafanaReady -and $attempt -lt $maxAttempts) {
    try {
        $response = Invoke-WebRequest -Uri "$GRAFANA_URL/api/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $grafanaReady = $true
        }
    } catch {
        Write-Host "   Grafana n'est pas encore prêt... Nouvelle tentative dans 5s" -ForegroundColor Gray
        Start-Sleep -Seconds 5
        $attempt++
    }
}

if ($grafanaReady) {
    Write-Host "   ✓ Grafana est prêt!" -ForegroundColor Green
} else {
    Write-Host "   ✗ Impossible de se connecter à Grafana" -ForegroundColor Red
    exit 1
}

# Créer la source de données Prometheus
Write-Host "2. Configuration de la source de données Prometheus..." -ForegroundColor Yellow
$datasourceBody = @{
    name = "Prometheus"
    type = "prometheus"
    url = $PROMETHEUS_URL
    access = "proxy"
    isDefault = $true
    jsonData = @{
        timeInterval = "15s"
    }
} | ConvertTo-Json

try {
    $dsResponse = Invoke-RestMethod -Uri "$GRAFANA_URL/api/datasources" -Method Post -Headers $headers -Body $datasourceBody -ErrorAction Stop
    Write-Host "   ✓ Source de données Prometheus configurée" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "   ⚠ Source de données existe déjà" -ForegroundColor Yellow
    } else {
        Write-Host "   ⚠ Erreur de configuration: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Importer le dashboard
Write-Host "3. Importation du dashboard Compte Service..." -ForegroundColor Yellow
$dashboardPath = "grafana-dashboard.json"

if (Test-Path $dashboardPath) {
    try {
        $dashboardContent = Get-Content $dashboardPath -Raw | ConvertFrom-Json
        $importBody = @{
            dashboard = $dashboardContent.dashboard
            overwrite = $true
            message = "Imported via PowerShell script"
        } | ConvertTo-Json -Depth 100
        
        $dbResponse = Invoke-RestMethod -Uri "$GRAFANA_URL/api/dashboards/db" -Method Post -Headers $headers -Body $importBody -ErrorAction Stop
        Write-Host "   ✓ Dashboard importé avec succès" -ForegroundColor Green
    } catch {
        Write-Host "   ✗ Erreur lors de l'importation du dashboard: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "   ✗ Fichier grafana-dashboard.json introuvable" -ForegroundColor Red
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Configuration terminée!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Accès Grafana: $GRAFANA_URL" -ForegroundColor White
Write-Host "Utilisateur: $GRAFANA_USER" -ForegroundColor White
Write-Host "Mot de passe: $GRAFANA_PASSWORD" -ForegroundColor White
Write-Host "=====================================" -ForegroundColor Cyan
