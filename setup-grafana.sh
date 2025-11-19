#!/bin/bash

# Script de configuration Grafana pour le Compte Service
# Ce script configure automatiquement la source de données Prometheus et importe le dashboard

GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="admin"
PROMETHEUS_URL="http://localhost:9091"

echo "====================================="
echo "Configuration de Grafana"
echo "====================================="

# Attendre que Grafana soit disponible
echo "1. Attente de la disponibilité de Grafana..."
until curl -s ${GRAFANA_URL}/api/health > /dev/null 2>&1; do
    echo "   Grafana n'est pas encore prêt... Nouvelle tentative dans 5s"
    sleep 5
done
echo "   ✓ Grafana est prêt!"

# Créer la source de données Prometheus
echo "2. Configuration de la source de données Prometheus..."
curl -X POST \
  -H "Content-Type: application/json" \
  -u ${GRAFANA_USER}:${GRAFANA_PASSWORD} \
  ${GRAFANA_URL}/api/datasources \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "'${PROMETHEUS_URL}'",
    "access": "proxy",
    "isDefault": true,
    "jsonData": {
      "timeInterval": "15s"
    }
  }' 2>/dev/null

if [ $? -eq 0 ]; then
    echo "   ✓ Source de données Prometheus configurée"
else
    echo "   ⚠ Source de données existe déjà ou erreur de configuration"
fi

# Importer le dashboard
echo "3. Importation du dashboard Compte Service..."
if [ -f "grafana-dashboard.json" ]; then
    DASHBOARD_JSON=$(cat grafana-dashboard.json)
    curl -X POST \
      -H "Content-Type: application/json" \
      -u ${GRAFANA_USER}:${GRAFANA_PASSWORD} \
      ${GRAFANA_URL}/api/dashboards/db \
      -d "{
        \"dashboard\": $(cat grafana-dashboard.json | jq '.dashboard'),
        \"overwrite\": true,
        \"message\": \"Imported via script\"
      }" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "   ✓ Dashboard importé avec succès"
    else
        echo "   ✗ Erreur lors de l'importation du dashboard"
    fi
else
    echo "   ✗ Fichier grafana-dashboard.json introuvable"
fi

echo ""
echo "====================================="
echo "Configuration terminée!"
echo "====================================="
echo "Accès Grafana: ${GRAFANA_URL}"
echo "Utilisateur: ${GRAFANA_USER}"
echo "Mot de passe: ${GRAFANA_PASSWORD}"
echo "====================================="
