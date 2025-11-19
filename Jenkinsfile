pipeline {
    agent any

    tools {
<<<<<<< Updated upstream
        maven 'Maven'   // Nom de l'installation Maven configurée dans Jenkins
=======
        maven 'myMaven' // Nom Maven défini dans Jenkins > Manage Jenkins > Tools
    }

    environment {
        DEPLOY_PATH = "/opt/tomcat/webapps"      // chemin du Tomcat
        WAR_NAME = "compte-service.war"          // nom final du fichier
        // Variables pour Docker/Kubernetes
        DOCKER_REGISTRY = "" // ex: myregistry.io/namespace
        IMAGE_NAME = "my-compte-service"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        // Variables pour Prometheus et Grafana
        PROMETHEUS_URL = "http://localhost:9091"
        GRAFANA_URL = "http://localhost:3000"
        APP_URL = "http://localhost:8082"
>>>>>>> Stashed changes
    }

    stages {

        stage('Checkout code') {
            steps {
                echo '📥 Récupération du code source depuis GitHub...'
                git branch: 'main', url: 'https://github.com/afouacherni/Compte-Service.git'
            }
        }

        stage('Build Maven') {
            steps {
<<<<<<< Updated upstream
                sh 'mvn clean install'
            }
        }

        stage('Deploy using Ansible playbook') {
            steps {
                script {
                    // Exécution du playbook Ansible
                    // Remplace playbookCICD.yml par le nom réel de ton playbook
                    sh 'ansible-playbook -i hosts playbookCICD.yml'
                }
            }
        }
    }

    post {
        always {
            // Nettoyage du workspace Jenkins après le build
            cleanWs()
=======
                echo '⚙️ Compilation du code...'
                sh 'mvn clean compile'
            }
        }

        stage('SonarQube Analysis') {
            when {
                expression { return fileExists('sonar-project.properties') }
            }
            steps {
                echo '🔍 Analyse de code avec SonarQube...'
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Test code') {
            steps {
                echo '🧪 Exécution des tests unitaires...'
                sh 'mvn test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                    echo '📊 Rapports de tests générés'
                }
            }
        }

        stage('Package code') {
            steps {
                echo '📦 Création du package JAR/WAR...'
                sh 'mvn package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Construction de l\'image Docker...'
                script {
                    def imageName = env.DOCKER_REGISTRY ? "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}:${env.IMAGE_TAG}" : "${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                    sh "docker build -t ${imageName} ."
                    
                    // Tag avec 'latest' aussi
                    def latestTag = env.DOCKER_REGISTRY ? "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}:latest" : "${env.IMAGE_NAME}:latest"
                    sh "docker tag ${imageName} ${latestTag}"
                    
                    echo "✓ Image créée: ${imageName}"
                }
            }
        }

        stage('Push Docker Image') {
            when {
                expression { return env.DOCKER_REGISTRY?.trim() }
            }
            steps {
                echo '📤 Push de l\'image vers le registry Docker...'
                script {
                    def fullImage = "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                    def latestTag = "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}:latest"
                    sh "docker push ${fullImage}"
                    sh "docker push ${latestTag}"
                    echo "✓ Images poussées: ${fullImage} et ${latestTag}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                expression { return env.DOCKER_REGISTRY?.trim() }
            }
            steps {
                echo '☸️ Déploiement sur Kubernetes...'
                sh 'kubectl apply -f my-deployment.yaml'
                sh 'kubectl apply -f service.yaml'
                sh 'kubectl apply -f k8s/servicemonitor.yaml'
                echo '✓ Application déployée sur Kubernetes'
            }
        }

        stage('Deploy to Tomcat') {
            when {
                expression { return !env.DOCKER_REGISTRY?.trim() }
            }
            steps {
                echo '🚀 Déploiement du WAR sur Apache Tomcat...'
                sh '''
                    sudo cp target/*.war $DEPLOY_PATH/$WAR_NAME
                    sudo systemctl restart tomcat
                '''
                echo '✓ Application déployée sur Tomcat'
            }
        }

        stage('Health Check') {
            steps {
                echo '🏥 Vérification de la santé de l\'application...'
                script {
                    retry(5) {
                        sleep time: 10, unit: 'SECONDS'
                        sh "curl -f ${env.APP_URL}/actuator/health || exit 1"
                    }
                    echo '✓ L\'application est en bonne santé'
                }
            }
        }

        stage('Verify Prometheus Metrics') {
            steps {
                echo '📊 Vérification des métriques Prometheus...'
                script {
                    // Vérifier que l'endpoint Prometheus est accessible
                    sh "curl -f ${env.APP_URL}/actuator/prometheus | head -n 20"
                    echo '✓ Endpoint Prometheus accessible'
                    
                    // Vérifier que Prometheus scrape l'application
                    sleep time: 20, unit: 'SECONDS'
                    def prometheusCheck = sh(
                        script: "curl -s ${env.PROMETHEUS_URL}/api/v1/targets | grep compte-service || true",
                        returnStdout: true
                    ).trim()
                    
                    if (prometheusCheck) {
                        echo '✓ L\'application est scrapée par Prometheus'
                    } else {
                        echo '⚠️ Prometheus ne scrape pas encore l\'application (vérifier prometheus.yml)'
                    }
                }
            }
        }

        stage('Setup Grafana Dashboard') {
            steps {
                echo '📈 Configuration du dashboard Grafana...'
                script {
                    // Vérifier que Grafana est accessible
                    def grafanaCheck = sh(
                        script: "curl -f ${env.GRAFANA_URL}/api/health || echo 'FAIL'",
                        returnStdout: true
                    ).trim()
                    
                    if (grafanaCheck != 'FAIL') {
                        echo '✓ Grafana est accessible'
                        // Exécuter le script de configuration si disponible
                        if (fileExists('setup-grafana.sh')) {
                            sh 'chmod +x setup-grafana.sh'
                            sh './setup-grafana.sh || echo "Configuration Grafana à faire manuellement"'
                        }
                    } else {
                        echo '⚠️ Grafana n\'est pas accessible sur ${env.GRAFANA_URL}'
                    }
                }
            }
        }
    }

    post {
        success {
            echo """
            ╔════════════════════════════════════════════════════════╗
            ║        ✅ PIPELINE RÉUSSI ET DÉPLOYÉ !                 ║
            ╠════════════════════════════════════════════════════════╣
            ║ 🌐 Application: ${env.APP_URL}                         ║
            ║ 📊 Métriques: ${env.APP_URL}/actuator/prometheus       ║
            ║ 🔍 Prometheus: ${env.PROMETHEUS_URL}                   ║
            ║ 📈 Grafana: ${env.GRAFANA_URL}                         ║
            ║ 📚 Swagger: ${env.APP_URL}/swagger-ui.html            ║
            ╚════════════════════════════════════════════════════════╝
            """
>>>>>>> Stashed changes
        }

        success {
            echo '✅ Ansible playbook executed successfully!'
        }

        failure {
<<<<<<< Updated upstream
            echo '❌ Ansible playbook execution failed!'
=======
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
>>>>>>> Stashed changes
        }
    }
}
