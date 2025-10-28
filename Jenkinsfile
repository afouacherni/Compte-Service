pipeline {
    agent any

    tools {
        maven 'myMaven' // Nom Maven défini dans Jenkins > Manage Jenkins > Tools
    }

    environment {
        DEPLOY_PATH = "/opt/tomcat/webapps"      // chemin du Tomcat
        WAR_NAME = "compte-service.war"          // nom final du fichier
    }

    stages {
        stage('Checkout code') {
            steps {
                git branch: 'main', url: 'https://github.com/afouacherni/Compte-Service.git'
            }
        }

        stage('Compile code') {
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('Test code') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package code') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }

        stage('Deploy to Tomcat') {
            steps {
                echo '🚀 Déploiement du WAR sur Apache Tomcat...'
                sh '''
                    sudo cp target/*.war $DEPLOY_PATH/$WAR_NAME
                    sudo systemctl restart tomcat
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline réussi et déployé sur Tomcat !"
        }
        failure {
            echo "❌ Le pipeline a échoué !"
        }
    }
}
