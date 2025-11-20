pipeline {
    agent any

    tools {
        maven 'Maven' // Nom Maven défini dans Jenkins
    }

    environment {
        DOCKER_USER = 'afwacherni123'
        IMAGE_NAME = 'my-compte-service'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout code') {
            steps {
                echo '📥 Récupération du code source depuis GitHub...'
                git branch: 'main', url: 'https://github.com/afouacherni/Compte-Service.git'
            }
        }

        stage('Build maven') {
            steps {
                echo '⚙️ Compilation et tests avec Maven...'
                sh 'mvn clean install'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                    echo '📊 Rapports de tests générés'
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                echo '🐳 Construction et push de l\'image Docker...'
                // Construction de l'image
                sh "docker build . -t ${env.IMAGE_NAME}:${env.IMAGE_TAG}"

                // Login et Push vers Docker Hub
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-pwd',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PWD'
                )]) {
                    sh 'docker login -u $DOCKER_USER -p $DOCKER_PWD'
                    sh "docker tag ${env.IMAGE_NAME}:${env.IMAGE_TAG} \$DOCKER_USER/${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                    sh "docker tag ${env.IMAGE_NAME}:${env.IMAGE_TAG} \$DOCKER_USER/${env.IMAGE_NAME}:latest"
                    sh "docker push \$DOCKER_USER/${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                    sh "docker push \$DOCKER_USER/${env.IMAGE_NAME}:latest"
                    sh 'docker logout'
                }
                echo '✓ Image Docker poussée sur Docker Hub'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo '☸️ Déploiement sur Kubernetes avec Prometheus...'
                withKubeConfig(credentialsId: 'KubeConfig-file', serverUrl: '') {
                    // Créer le namespace monitoring s'il n'existe pas
                    sh 'kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -'
                    
                    // Déployer Prometheus et sa configuration
                    sh 'kubectl apply -f k8s/prometheus-configmap.yaml'
                    sh 'kubectl apply -f k8s/prometheus-deployment.yaml'
                    
                    // Déployer l'application (3 pods avec annotations Prometheus)
                    sh 'kubectl apply -f my-deployment.yaml'
                    sh 'kubectl apply -f service.yaml'
                    sh 'kubectl apply -f k8s/servicemonitor.yaml'
                    
                    // Attendre que les déploiements soient prêts
                    sh 'kubectl rollout status deployment/my-compte-service --timeout=300s || true'
                    sh 'kubectl rollout status deployment/prometheus -n monitoring --timeout=300s || true'
                    
                    echo '✓ Application et Prometheus déployés sur Kubernetes'
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '🔍 Vérification du déploiement...'
                withKubeConfig(credentialsId: 'KubeConfig-file', serverUrl: '') {
                    sh 'kubectl get pods -l app=compte-service'
                    sh 'kubectl get pods -n monitoring'
                    sh 'kubectl get svc'
                    sh 'kubectl get svc -n monitoring'
                }
            }
        }

        stage('Health Check') {
            steps {
                echo '🏥 Vérification de la santé de l\'application...'
                withKubeConfig(credentialsId: 'KubeConfig-file', serverUrl: '') {
                    script {
                        retry(5) {
                            sleep time: 10, unit: 'SECONDS'
                            sh 'kubectl get pods -l app=compte-service -o wide'
                            // Vérifier qu'au moins un pod est prêt
                            sh 'kubectl wait --for=condition=ready pod -l app=compte-service --timeout=60s'
                        }
                    }
                }
                echo '✓ Les pods sont en bonne santé'
            }
        }
    }

    post {
        success {
            echo """
            ╔════════════════════════════════════════════════════════╗
            ║        ✅ PIPELINE RÉUSSI - PODS EN SURVEILLANCE !     ║
            ╠════════════════════════════════════════════════════════╣
            ║ 🎯 3 Pods déployés et surveillés par Prometheus       ║
            ║ 📊 Commandes utiles:                                   ║
            ║   kubectl get pods -l app=compte-service               ║
            ║   kubectl get pods -n monitoring                       ║
            ║   kubectl port-forward -n monitoring svc/prometheus 9090:9090 ║
            ║   kubectl port-forward svc/compte-service 8082:8082    ║
            ╚════════════════════════════════════════════════════════╝
            """
        }

        failure {
            echo """
            ╔════════════════════════════════════════════════════════╗
            ║           ❌ LE PIPELINE A ÉCHOUÉ !                    ║
            ╠════════════════════════════════════════════════════════╣
            ║ Consultez les logs pour plus de détails               ║
            ╚════════════════════════════════════════════════════════╝
            """
        }
        
        always {
            echo '🧹 Nettoyage des ressources temporaires...'
            cleanWs(deleteDirs: true, patterns: [[pattern: 'target/**', type: 'INCLUDE']])
        }
    }
}
