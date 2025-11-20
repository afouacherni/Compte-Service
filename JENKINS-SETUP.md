# Guide de Configuration Jenkins pour le Pipeline CI/CD

Ce guide explique comment configurer Jenkins pour que le pipeline fonctionne correctement avec Kubernetes et Prometheus.

## 🔧 Prérequis Jenkins

### 1. Plugins Jenkins Requis

Installez les plugins suivants dans Jenkins (`Manage Jenkins` > `Manage Plugins`):

- **Git Plugin** - Pour checkout depuis GitHub
- **Pipeline** - Pour exécuter les Jenkinsfiles
- **Docker Pipeline** - Pour les commandes Docker
- **Kubernetes CLI Plugin** - Pour kubectl
- **JUnit Plugin** - Pour les rapports de tests
- **SonarQube Scanner** (optionnel)

### 2. Configuration Maven dans Jenkins

1. Allez dans `Manage Jenkins` > `Tools`
2. Trouvez la section **Maven**
3. Cliquez sur **Add Maven**
4. Nom: `myMaven` (doit correspondre au Jenkinsfile)
5. Version: Maven 3.9.x ou plus récent
6. Cochez "Install automatically"
7. Sauvegardez

### 3. Configuration Docker

Assurez-vous que Jenkins a accès à Docker:

```bash
# Ajouter l'utilisateur Jenkins au groupe Docker
sudo usermod -aG docker jenkins

# Redémarrer Jenkins
sudo systemctl restart jenkins
```

### 4. Configuration Kubectl

Jenkins doit avoir accès à kubectl et à votre cluster Kubernetes:

```bash
# Copier la config kubectl pour Jenkins
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
```

## 🚀 Configuration du Pipeline

### Option 1: Déploiement Local (Docker uniquement)

Si vous n'avez pas de Docker Registry, laissez `DOCKER_REGISTRY` vide dans le Jenkinsfile:

```groovy
environment {
    DOCKER_REGISTRY = "" // Vide = déploiement local Docker
    IMAGE_NAME = "my-compte-service"
    // ...
}
```

Le pipeline utilisera Docker local sans pousser vers un registry.

### Option 2: Déploiement Kubernetes avec Registry

Pour déployer sur Kubernetes, configurez un Docker Registry:

```groovy
environment {
    DOCKER_REGISTRY = "docker.io/votre-username" // ou registry privé
    IMAGE_NAME = "my-compte-service"
    // ...
}
```

#### Configuration des credentials Docker dans Jenkins

1. Allez dans `Manage Jenkins` > `Manage Credentials`
2. Cliquez sur `(global)`
3. Cliquez sur `Add Credentials`
4. Type: `Username with password`
5. Username: Votre username Docker Hub
6. Password: Votre token Docker Hub
7. ID: `docker-hub-credentials`
8. Sauvegardez

#### Modifier le Jenkinsfile pour utiliser les credentials

Ajoutez avant le stage "Push Docker Image":

```groovy
stage('Docker Login') {
    when {
        expression { return env.DOCKER_REGISTRY?.trim() }
    }
    steps {
        script {
            withCredentials([usernamePassword(
                credentialsId: 'docker-hub-credentials',
                usernameVariable: 'DOCKER_USER',
                passwordVariable: 'DOCKER_PASS'
            )]) {
                sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
            }
        }
    }
}
```

## 📝 Création du Job Jenkins

### 1. Créer un nouveau Pipeline Job

1. Sur le dashboard Jenkins, cliquez sur **New Item**
2. Nom: `Compte-Service-Pipeline`
3. Type: **Pipeline**
4. Cliquez sur **OK**

### 2. Configuration du Job

#### Section "General"
- ✅ Cochez "GitHub project"
- Project url: `https://github.com/afouacherni/Compte-Service/`

#### Section "Build Triggers"
- ✅ Cochez "GitHub hook trigger for GITScm polling" (pour webhook automatique)
- OU ✅ Cochez "Poll SCM" avec Schedule: `H/5 * * * *` (vérifier toutes les 5 minutes)

#### Section "Pipeline"
- Definition: **Pipeline script from SCM**
- SCM: **Git**
- Repository URL: `https://github.com/afouacherni/Compte-Service.git`
- Credentials: (ajoutez si repository privé)
- Branch: `*/main`
- Script Path: `Jenkinsfile`

### 3. Sauvegarder

Cliquez sur **Save**

## 🔗 Configuration du Webhook GitHub (Optionnel mais recommandé)

Pour déclencher automatiquement le build à chaque push:

### 1. Dans votre repository GitHub

1. Allez dans **Settings** > **Webhooks**
2. Cliquez sur **Add webhook**
3. Payload URL: `http://JENKINS_URL/github-webhook/`
   - Exemple: `http://192.168.1.100:8080/github-webhook/`
4. Content type: `application/json`
5. Events: Cochez "Just the push event"
6. Active: ✅
7. Cliquez sur **Add webhook**

### 2. Exposer Jenkins sur Internet (si nécessaire)

Si Jenkins est local, vous pouvez utiliser **ngrok**:

```bash
# Installer ngrok
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar -xvzf ngrok-v3-stable-linux-amd64.tgz
sudo mv ngrok /usr/local/bin/

# Lancer ngrok (Jenkins sur port 8080)
ngrok http 8080
```

Utilisez l'URL ngrok dans le webhook GitHub.

## ✅ Checklist Avant Premier Build

### Vérifications Jenkins

- [ ] Maven configuré avec le nom `myMaven`
- [ ] Jenkins peut exécuter `docker` commands
- [ ] Jenkins peut exécuter `kubectl` commands
- [ ] Les credentials Docker sont configurés (si registry)
- [ ] Le job Pipeline est créé et configuré

### Vérifications Cluster Kubernetes

- [ ] Cluster Kubernetes est accessible (`kubectl get nodes`)
- [ ] Le namespace `monitoring` existe ou peut être créé
- [ ] Vous avez les permissions pour déployer

### Vérifications Fichiers

- [ ] `Jenkinsfile` est à la racine du projet
- [ ] `Dockerfile` est présent
- [ ] `pom.xml` est configuré correctement
- [ ] Tous les fichiers k8s sont dans le dossier `k8s/`

### Variables d'Environnement à Vérifier

Dans le Jenkinsfile, ajustez selon votre environnement:

```groovy
environment {
    // Pour Kubernetes: mettre votre registry Docker
    DOCKER_REGISTRY = "docker.io/votre-username"
    // OU pour Docker local: laisser vide
    DOCKER_REGISTRY = ""
    
    IMAGE_NAME = "my-compte-service"
    
    // URLs selon votre déploiement
    PROMETHEUS_URL = "http://localhost:9091"  // Ou NodePort si K8s
    GRAFANA_URL = "http://localhost:3000"     // Ou NodePort si K8s
    APP_URL = "http://localhost:8082"         // Ou NodePort si K8s
}
```

## 🔄 Flux de Déploiement

### Pour Docker Local (DOCKER_REGISTRY vide):

```
GitHub Push → Jenkins
  ↓
  ├─ Checkout code
  ├─ Compile
  ├─ Test
  ├─ Package JAR
  ├─ Build Docker Image (local)
  ├─ Deploy with Docker (docker run)
  ├─ Health Check
  └─ Verify Prometheus Metrics
```

### Pour Kubernetes (DOCKER_REGISTRY défini):

```
GitHub Push → Jenkins
  ↓
  ├─ Checkout code
  ├─ Compile
  ├─ Test
  ├─ Package JAR
  ├─ Build Docker Image
  ├─ Push to Registry
  ├─ Deploy to Kubernetes
  │   ├─ Create monitoring namespace
  │   ├─ Deploy Prometheus ConfigMap
  │   ├─ Deploy Prometheus
  │   ├─ Deploy Application
  │   ├─ Deploy Service
  │   └─ Deploy ServiceMonitor
  ├─ Health Check (via kubectl)
  └─ Verify Prometheus Metrics
```

## 🧪 Tester le Pipeline

### 1. Premier Build Manuel

1. Dans Jenkins, allez dans votre job
2. Cliquez sur **Build Now**
3. Cliquez sur le numéro du build (ex: #1)
4. Cliquez sur **Console Output** pour voir les logs

### 2. Vérifier le Déploiement

#### Si Docker Local:

```bash
# Vérifier le conteneur
docker ps | grep compte-service

# Tester l'application
curl http://localhost:8082/actuator/health
curl http://localhost:8082/actuator/prometheus
```

#### Si Kubernetes:

```bash
# Vérifier les pods
kubectl get pods -l app=compte-service
kubectl get pods -n monitoring

# Vérifier les services
kubectl get svc
kubectl get svc -n monitoring

# Tester l'application
kubectl port-forward svc/compte-service 8082:8082
curl http://localhost:8082/actuator/health
```

### 3. Test du Webhook

Faites un petit changement dans votre code et poussez sur GitHub:

```bash
git add .
git commit -m "Test Jenkins webhook"
git push origin main
```

Le build devrait se déclencher automatiquement dans Jenkins.

## 🐛 Dépannage

### Erreur: "mvn: command not found"

→ Vérifiez que Maven est bien configuré dans Jenkins Tools avec le nom `myMaven`

### Erreur: "docker: command not found"

```bash
# Vérifier que Jenkins est dans le groupe docker
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Erreur: "kubectl: command not found"

```bash
# Installer kubectl sur le serveur Jenkins
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Erreur: "unauthorized: authentication required"

→ Vérifiez que les credentials Docker Hub sont correctement configurés dans Jenkins

### Erreur: "The connection to the server localhost:8080 was refused"

→ Jenkins n'a pas accès au cluster Kubernetes. Vérifiez la config kubectl.

### Les pods ne démarrent pas dans Kubernetes

```bash
# Vérifier les logs des pods
kubectl logs -l app=compte-service

# Vérifier les events
kubectl get events --sort-by='.lastTimestamp'

# Vérifier que l'image est accessible
kubectl describe pod <pod-name>
```

## 📊 Accéder aux Applications Déployées

### Kubernetes NodePort

```bash
# Obtenir les NodePorts
kubectl get svc

# Accéder aux applications
# Application: http://<node-ip>:30082
# Prometheus: http://<node-ip>:30090
```

### Port-Forward (Alternative)

```bash
# Application
kubectl port-forward svc/compte-service 8082:8082

# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

## 🎯 URLs Importantes Post-Déploiement

- **Application**: http://localhost:8082 ou NodePort
- **Health Check**: http://localhost:8082/actuator/health
- **Métriques Prometheus**: http://localhost:8082/actuator/prometheus
- **Swagger UI**: http://localhost:8082/swagger-ui.html
- **Prometheus UI**: http://localhost:9090 ou NodePort :30090
- **Grafana**: Suivre le guide de setup Grafana

## 📝 Prochaines Étapes

1. ✅ Push votre code sur GitHub
2. ✅ Configurer Jenkins selon ce guide
3. ✅ Lancer le premier build
4. ✅ Vérifier que tout fonctionne
5. 📈 Importer le dashboard Grafana
6. 🎉 Profiter du CI/CD automatisé !
