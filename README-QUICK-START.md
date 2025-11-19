# 🚀 Quick Start - Pipeline CI/CD

## Démarrage Rapide en 5 étapes

### 1️⃣ Démarrer Prometheus
```bash
# Naviguez vers le dossier d'installation de Prometheus
prometheus.exe --config.file=C:\Users\user\Desktop\Compte-Service\prometheus.yml --web.listen-address=:9091
```
✅ Vérifiez: http://localhost:9091

### 2️⃣ Démarrer Grafana
```bash
# Naviguez vers le dossier d'installation de Grafana
grafana-server.exe
```
✅ Vérifiez: http://localhost:3000 (admin/admin)

### 3️⃣ Configurer Grafana
```powershell
cd C:\Users\user\Desktop\Compte-Service
.\setup-grafana.ps1
```

### 4️⃣ Push vers GitHub
```bash
cd C:\Users\user\Desktop\Compte-Service
git add .
git commit -m "feat: Add CI/CD pipeline with Prometheus and Grafana"
git push origin main
```

### 5️⃣ Lancer le Build Jenkins
1. Accédez à http://localhost:8080
2. Ouvrez votre job **Compte-Service-Pipeline**
3. Cliquez sur **Build Now**
4. Surveillez la progression dans **Console Output**

---

## ✅ Vérifications après le build

### Application
```bash
curl http://localhost:8082/actuator/health
```

### Prometheus
http://localhost:9091/targets
- Vérifiez que `compte-service` est **UP**

### Grafana
http://localhost:3000/dashboards
- Ouvrez le dashboard **Compte Service - Monitoring Dashboard**

---

## 📊 Accès Rapides

| Service | URL |
|---------|-----|
| 🌐 Application | http://localhost:8082 |
| 📊 Métriques | http://localhost:8082/actuator/prometheus |
| 📈 Grafana | http://localhost:3000 |
| 🔍 Prometheus | http://localhost:9091 |
| 🚀 Jenkins | http://localhost:8080 |
| 📚 Swagger | http://localhost:8082/swagger-ui.html |

---

## 🆘 En cas de problème

1. **Vérifiez que tous les services sont démarrés**
2. **Consultez PIPELINE-GUIDE.md pour le dépannage détaillé**
3. **Vérifiez les logs Jenkins (Console Output)**

---

**Bonne chance ! 🎉**
