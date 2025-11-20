# Guide de Surveillance des Pods Kubernetes

Ce guide explique comment déployer et configurer la surveillance des pods Kubernetes pour le service Compte-Service avec Prometheus et Grafana.

## 📋 Prérequis

- Un cluster Kubernetes fonctionnel (Minikube, Kind, ou cluster cloud)
- `kubectl` configuré pour accéder à votre cluster
- Les images Docker de votre application déployées

## 🚀 Déploiement

### 1. Créer le namespace de monitoring

```bash
kubectl create namespace monitoring
```

### 2. Déployer la configuration Prometheus

```bash
# Appliquer le ConfigMap Prometheus
kubectl apply -f k8s/prometheus-configmap.yaml

# Déployer Prometheus avec les permissions nécessaires
kubectl apply -f k8s/prometheus-deployment.yaml
```

### 3. Déployer l'application Compte-Service

```bash
# Déployer l'application avec les annotations Prometheus
kubectl apply -f my-deployment.yaml

# Déployer le service
kubectl apply -f service.yaml

# Optionnel: Déployer le ServiceMonitor si vous utilisez Prometheus Operator
kubectl apply -f k8s/servicemonitor.yaml
```

## 🔍 Vérification du déploiement

### Vérifier que Prometheus est en cours d'exécution

```bash
# Vérifier le pod Prometheus
kubectl get pods -n monitoring

# Vérifier le service Prometheus
kubectl get svc -n monitoring
```

### Vérifier les pods de l'application

```bash
# Vérifier les pods compte-service
kubectl get pods -l app=compte-service

# Vérifier les annotations Prometheus
kubectl describe pod <nom-du-pod> | grep prometheus.io
```

## 🌐 Accéder à Prometheus

### Option 1: Port-forward (Recommandé pour le développement)

```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

Puis ouvrez votre navigateur sur: http://localhost:9090

### Option 2: NodePort (Déjà configuré)

Le service Prometheus est exposé sur le port 30090. Accédez-y via:
```
http://<node-ip>:30090
```

Pour obtenir l'IP du node:
```bash
kubectl get nodes -o wide
```

## 📊 Configuration de Grafana

### 1. Déployer Grafana (si pas encore fait)

```bash
# Créer un déploiement Grafana
kubectl create deployment grafana --image=grafana/grafana:latest -n monitoring

# Exposer Grafana
kubectl expose deployment grafana --type=NodePort --port=3000 --target-port=3000 -n monitoring
```

### 2. Accéder à Grafana

```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

Accédez à: http://localhost:3000
- Utilisateur par défaut: `admin`
- Mot de passe par défaut: `admin`

### 3. Configurer la source de données Prometheus

1. Allez dans **Configuration > Data Sources**
2. Cliquez sur **Add data source**
3. Sélectionnez **Prometheus**
4. URL: `http://prometheus.monitoring.svc.cluster.local:9090`
5. Cliquez sur **Save & Test**

### 4. Importer le dashboard de surveillance des pods

1. Allez dans **Create > Import**
2. Uploadez le fichier `grafana-dashboard-pods.json`
3. Sélectionnez la source de données Prometheus
4. Cliquez sur **Import**

## 📈 Métriques surveillées

Le dashboard affiche les métriques suivantes pour chaque pod:

### Métriques de santé
- **Nombre de pods actifs**: Compte le nombre de pods en cours d'exécution
- **Pods ready**: Nombre de pods prêts à recevoir du trafic
- **Liste des pods**: Table avec les détails de chaque pod

### Métriques de performance
- **CPU Usage par pod**: Utilisation CPU de chaque pod en pourcentage
- **Memory Usage par pod**: Utilisation mémoire de chaque pod en MB
- **JVM Threads par pod**: Nombre de threads actifs et daemon par pod
- **Uptime par pod**: Temps de fonctionnement de chaque pod

### Métriques applicatives
- **HTTP Requests par pod**: Nombre de requêtes HTTP par seconde pour chaque pod
- **HTTP Response Time par pod**: Temps de réponse moyen par pod en millisecondes
- **Database Connections par pod**: Connexions actives et idle par pod
- **Répartition de la charge**: Distribution du trafic entre les pods

## 🔧 Configuration des annotations Prometheus

Les pods sont automatiquement découverts grâce aux annotations suivantes dans `my-deployment.yaml`:

```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8082"
  prometheus.io/path: "/actuator/prometheus"
```

## 🎯 Targets Prometheus

Pour vérifier que Prometheus scrape correctement vos pods:

1. Accédez à Prometheus UI: http://localhost:9090
2. Allez dans **Status > Targets**
3. Vérifiez que les jobs suivants sont présents et UP:
   - `kubernetes-pods`
   - `compte-service`
   - `kubernetes-nodes`
   - `kubernetes-services`

## 🔄 Mise à l'échelle et test

### Tester la mise à l'échelle

```bash
# Augmenter le nombre de replicas
kubectl scale deployment my-compte-service --replicas=5

# Vérifier les pods
kubectl get pods -l app=compte-service

# Réduire le nombre de replicas
kubectl scale deployment my-compte-service --replicas=3
```

Observez les changements dans le dashboard Grafana en temps réel.

### Générer de la charge pour tester

```bash
# Obtenir l'IP et le port du service
kubectl get svc compte-service

# Générer des requêtes (exemple avec curl en boucle)
for i in {1..1000}; do
  curl http://<service-ip>:<port>/comptes
  sleep 0.1
done
```

Vous verrez la répartition de la charge entre les différents pods dans le dashboard.

## 🐛 Dépannage

### Les pods ne sont pas détectés par Prometheus

1. Vérifiez les annotations sur les pods:
```bash
kubectl describe pod <nom-du-pod> | grep prometheus.io
```

2. Vérifiez les logs Prometheus:
```bash
kubectl logs -n monitoring deployment/prometheus
```

3. Vérifiez la configuration Prometheus:
```bash
kubectl get configmap prometheus-config -n monitoring -o yaml
```

### Les métriques ne s'affichent pas dans Grafana

1. Vérifiez que la source de données Prometheus est correctement configurée
2. Testez une requête simple dans Grafana: `up{application="compte-service"}`
3. Vérifiez que l'endpoint `/actuator/prometheus` est accessible:
```bash
kubectl port-forward <nom-du-pod> 8082:8082
curl http://localhost:8082/actuator/prometheus
```

### Permissions insuffisantes

Si Prometheus ne peut pas découvrir les pods:
```bash
# Vérifier les permissions
kubectl auth can-i list pods --as=system:serviceaccount:monitoring:prometheus -n default

# Re-appliquer les permissions
kubectl apply -f k8s/prometheus-deployment.yaml
```

## 📚 Requêtes PromQL utiles

Voici quelques requêtes PromQL utiles pour la surveillance des pods:

```promql
# Nombre de pods actifs
count(up{application="compte-service"})

# CPU moyen par pod
avg by(kubernetes_pod_name) (process_cpu_usage{application="compte-service"})

# Mémoire totale utilisée par l'application
sum(jvm_memory_used_bytes{application="compte-service"}) / 1024 / 1024

# Taux de requêtes HTTP par pod
rate(http_server_requests_seconds_count{application="compte-service"}[5m])

# Latence P95 par pod
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{application="compte-service"}[5m]))
```

## 🔐 Sécurité

Pour la production, considérez:

1. **Activer l'authentification** sur Prometheus et Grafana
2. **Utiliser des secrets** pour les mots de passe:
```bash
kubectl create secret generic grafana-admin --from-literal=password=<votre-mot-de-passe> -n monitoring
```
3. **Configurer TLS** pour les communications
4. **Limiter les permissions** RBAC au strict nécessaire
5. **Utiliser des NetworkPolicies** pour restreindre l'accès

## 📞 Support

Pour plus d'informations:
- Documentation Prometheus: https://prometheus.io/docs/
- Documentation Grafana: https://grafana.com/docs/
- Documentation Kubernetes Service Discovery: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config
