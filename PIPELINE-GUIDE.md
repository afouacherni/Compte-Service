# 🚀 Guide Complet du Pipeline CI/CD - Compte Service

## 📋 Table des matières
1. [Architecture du Pipeline](#architecture)
2. [Prérequis](#prérequis)
3. [Configuration Prometheus](#prometheus)
4. [Configuration Grafana](#grafana)
5. [Configuration Jenkins](#jenkins)
6. [Déploiement](#déploiement)
7. [Vérification](#vérification)
8. [Dépannage](#dépannage)

---

## 🏗️ Architecture du Pipeline <a name="architecture"></a>

```
GitHub → Jenkins → Maven (Build/Test) → Docker → Kubernetes/Tomcat
                                          ↓
                                    Prometheus ← Métriques
                                          ↓
                                      Grafana (Dashboards)
```

### Flux du Pipeline:
1. **Checkout**: Récupération du code depuis GitHub
2. **Compile**: Compilation avec Maven
3. **Test**: Exécution des tests unitaires (JUnit)
4. **SonarQube**: Analyse de qualité du code (optionnel)
5. **Package**: Création du JAR/WAR
6. **Docker Build**: Construction de l'image Docker
7. **Deploy**: Déploiement sur Kubernetes ou Tomcat
8. **Health Check**: Vérification de la santé de l'application
9. **Monitoring**: Configuration de Prometheus et Grafana

---

## ✅ Prérequis <a name="prérequis"></a>

### Logiciels installés:
- ✅ Java 17+
- ✅ Maven 3.8+
- ✅ Docker
- ✅ Jenkins
- ✅ Prometheus (port 9091)
- ✅ Grafana (port 3000)
- ✅ Git
- ✅ Kubernetes (optionnel)
- ✅ Tomcat (optionnel)

### Vérification:
```bash
java -version
mvn -version
docker --version
git --version
```

---

## 🔍 Configuration Prometheus <a name="prometheus"></a>

### 1. Fichier de configuration
Le fichier `prometheus.yml` est déjà configuré pour scraper votre application:

```yaml
scrape_configs:
  - job_name: 'compte-service'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['localhost:8082']
```

### 2. Démarrage de Prometheus
```bash
# Windows (depuis le dossier d'installation de Prometheus)
prometheus.exe --config.file=C:\Users\user\Desktop\Compte-Service\prometheus.yml --web.listen-address=:9091

# Linux/Mac
./prometheus --config.file=./prometheus.yml --web.listen-address=:9091
```

### 3. Vérification
Accédez à: http://localhost:9091
- Vérifiez dans **Status → Targets** que `compte-service` est "UP"
- Testez une requête: `http_server_requests_seconds_count`

---

## 📈 Configuration Grafana <a name="grafana"></a>

### 1. Démarrage de Grafana
```bash
# Windows (depuis le dossier d'installation de Grafana)
grafana-server.exe

# Linux/Mac
./bin/grafana-server
```

Accédez à: http://localhost:3000
- **Login**: admin
- **Password**: admin (changez-le au premier login)

### 2. Configuration automatique
Exécutez le script de configuration:

**Sur Windows:**
```powershell
cd C:\Users\user\Desktop\Compte-Service
.\setup-grafana.ps1
```

**Sur Linux/Mac:**
```bash
chmod +x setup-grafana.sh
./setup-grafana.sh
```

### 3. Configuration manuelle (alternative)

#### A. Ajouter la source de données Prometheus:
1. Cliquez sur **⚙️ Configuration → Data Sources**
2. Cliquez sur **Add data source**
3. Sélectionnez **Prometheus**
4. URL: `http://localhost:9091`
5. Cliquez sur **Save & Test**

#### B. Importer le dashboard:
1. Cliquez sur **+ → Import**
2. Cliquez sur **Upload JSON file**
3. Sélectionnez `grafana-dashboard.json`
4. Sélectionnez la source de données **Prometheus**
5. Cliquez sur **Import**

### 4. Dashboard inclus
Le dashboard fourni affiche:
- 📊 CPU Usage
- 💾 Memory Usage
- ⏱️ JVM Uptime
- 🌐 HTTP Requests per second
- ⚡ HTTP Response Time
- 📈 Total HTTP Requests
- ❌ HTTP Error Rate
- 🗄️ Database Connections

---

## 🔧 Configuration Jenkins <a name="jenkins"></a>

### 1. Prérequis Jenkins

#### A. Installer les plugins nécessaires:
Dans Jenkins → **Manage Jenkins → Manage Plugins**, installez:
- Git Plugin
- Maven Integration Plugin
- Docker Pipeline Plugin
- Kubernetes Plugin (si déploiement K8s)
- JUnit Plugin
- Pipeline Plugin

#### B. Configurer Maven:
1. **Manage Jenkins → Global Tool Configuration**
2. Section **Maven** → **Add Maven**
3. Nom: `myMaven`
4. Cochez **Install automatically**
5. Sélectionnez une version (ex: 3.9.0)
6. **Save**

### 2. Créer le job Jenkins

#### A. Nouveau job:
1. **New Item**
2. Nom: `Compte-Service-Pipeline`
3. Type: **Pipeline**
4. **OK**

#### B. Configuration du job:
1. **General**:
   - Description: "Pipeline CI/CD pour le micro-service Compte"
   
2. **Build Triggers** (optionnel):
   - ☑️ GitHub hook trigger for GITScm polling
   - ☑️ Poll SCM: `H/5 * * * *` (vérifie toutes les 5 minutes)

3. **Pipeline**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/afouacherni/Compte-Service.git`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`

4. **Save**

### 3. Configuration des variables d'environnement

Dans le `Jenkinsfile`, ajustez ces variables selon votre environnement:

```groovy
environment {
    DEPLOY_PATH = "/opt/tomcat/webapps"      // Chemin Tomcat
    WAR_NAME = "compte-service.war"          // Nom du WAR
    DOCKER_REGISTRY = ""                     // Registry Docker (optionnel)
    IMAGE_NAME = "my-compte-service"
    PROMETHEUS_URL = "http://localhost:9091"
    GRAFANA_URL = "http://localhost:3000"
    APP_URL = "http://localhost:8082"
}
```

---

## 🚀 Déploiement <a name="déploiement"></a>

### 1. Push vers GitHub

```bash
cd C:\Users\user\Desktop\Compte-Service

# Ajouter tous les fichiers
git add .

# Commit
git commit -m "feat: Add complete CI/CD pipeline with Prometheus and Grafana monitoring"

# Push vers GitHub
git push origin main
```

### 2. Lancer le build Jenkins

#### Option A: Build manuel
1. Accédez à Jenkins: http://localhost:8080
2. Cliquez sur votre job **Compte-Service-Pipeline**
3. Cliquez sur **Build Now**

#### Option B: Build automatique
Le build se déclenchera automatiquement à chaque push sur GitHub (si configuré)

### 3. Suivre le pipeline

Cliquez sur le numéro du build → **Console Output** pour voir les logs en temps réel

### 4. Étapes du pipeline

Le pipeline exécutera automatiquement:
1. ✅ Checkout du code
2. ✅ Compilation
3. ✅ Tests unitaires
4. ✅ Package (JAR/WAR)
5. ✅ Build Docker image
6. ✅ Déploiement
7. ✅ Health check
8. ✅ Vérification Prometheus
9. ✅ Configuration Grafana

---

## 🔍 Vérification <a name="vérification"></a>

### 1. Application
```bash
# Health check
curl http://localhost:8082/actuator/health

# Métriques Prometheus
curl http://localhost:8082/actuator/prometheus

# Swagger UI
http://localhost:8082/swagger-ui.html

# H2 Console
http://localhost:8082/h2-console
```

### 2. Prometheus
- URL: http://localhost:9091
- Vérifiez les targets: **Status → Targets**
- Requête test: `up{job="compte-service"}`

### 3. Grafana
- URL: http://localhost:3000
- Dashboard: **Compte Service - Monitoring Dashboard**
- Vérifiez les graphiques en temps réel

### 4. Jenkins
- URL: http://localhost:8080
- Vérifiez que le build est ✅ Success
- Consultez les artifacts et rapports de tests

---

## 🐛 Dépannage <a name="dépannage"></a>

### Problème 1: Prometheus ne scrape pas l'application
**Solution:**
```bash
# Vérifiez que l'application expose les métriques
curl http://localhost:8082/actuator/prometheus

# Vérifiez prometheus.yml
# Redémarrez Prometheus
```

### Problème 2: Grafana n'affiche pas de données
**Solutions:**
1. Vérifiez la source de données Prometheus
2. Testez la requête dans Prometheus d'abord
3. Vérifiez l'horloge système (synchronisation temps)
4. Rechargez le dashboard

### Problème 3: Jenkins build échoue
**Solutions:**
```bash
# Vérifiez les logs détaillés dans Console Output
# Vérifiez que Maven est bien configuré
# Vérifiez les permissions Docker
# Vérifiez que tous les services sont démarrés
```

### Problème 4: Port déjà utilisé
```bash
# Windows - Trouver le processus
netstat -ano | findstr :8082
taskkill /PID <PID> /F

# Linux/Mac
lsof -i :8082
kill -9 <PID>
```

### Problème 5: Docker build échoue
**Solutions:**
```bash
# Vérifiez que Docker est démarré
docker info

# Nettoyez les anciennes images
docker system prune -a

# Vérifiez le Dockerfile
docker build -t test .
```

---

## 📊 Endpoints Utiles

| Service | URL | Description |
|---------|-----|-------------|
| Application | http://localhost:8082 | API principale |
| Health | http://localhost:8082/actuator/health | Santé de l'app |
| Prometheus Metrics | http://localhost:8082/actuator/prometheus | Métriques |
| Swagger UI | http://localhost:8082/swagger-ui.html | Documentation API |
| H2 Console | http://localhost:8082/h2-console | Base de données |
| Prometheus | http://localhost:9091 | Monitoring |
| Grafana | http://localhost:3000 | Dashboards |
| Jenkins | http://localhost:8080 | CI/CD |

---

## 🎯 Commandes Rapides

### Démarrer tout l'environnement:
```bash
# 1. Démarrer Prometheus
cd <prometheus-dir>
prometheus.exe --config.file=C:\Users\user\Desktop\Compte-Service\prometheus.yml --web.listen-address=:9091

# 2. Démarrer Grafana
cd <grafana-dir>
grafana-server.exe

# 3. Démarrer l'application
cd C:\Users\user\Desktop\Compte-Service
mvn spring-boot:run

# 4. Configurer Grafana
.\setup-grafana.ps1
```

### Build et test local:
```bash
cd C:\Users\user\Desktop\Compte-Service
mvn clean install
mvn spring-boot:run
```

### Push et déploiement:
```bash
git add .
git commit -m "Update configuration"
git push origin main
# Le build Jenkins se déclenchera automatiquement
```

---

## 📝 Notes Importantes

1. **Sécurité**: Changez les mots de passe par défaut (Grafana, Jenkins)
2. **Production**: Utilisez des variables d'environnement pour les secrets
3. **Backup**: Sauvegardez régulièrement les configurations Jenkins et Grafana
4. **Monitoring**: Configurez des alertes dans Grafana pour les métriques critiques
5. **Logs**: Activez la rotation des logs pour éviter le remplissage du disque

---

## 🆘 Support

En cas de problème:
1. Consultez les logs Jenkins: Console Output
2. Vérifiez les logs de l'application: `mvn spring-boot:run`
3. Consultez la documentation officielle:
   - [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
   - [Prometheus](https://prometheus.io/docs/)
   - [Grafana](https://grafana.com/docs/)
   - [Jenkins Pipeline](https://www.jenkins.io/doc/book/pipeline/)

---

**✨ Félicitations ! Votre pipeline CI/CD complet est maintenant configuré ! ✨**
