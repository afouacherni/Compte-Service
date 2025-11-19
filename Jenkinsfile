pipeline {
    agent any

    tools {
        maven 'Maven'   // Nom de l'installation Maven configurée dans Jenkins
    }

    stages {

        stage('Checkout code') {
            steps {
                git branch: 'main', url: 'https://github.com/afouacherni/Compte-Service.git'
            }
        }

        stage('Build Maven') {
            steps {
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
        }

        success {
            echo '✅ Ansible playbook executed successfully!'
        }

        failure {
            echo '❌ Ansible playbook execution failed!'
        }
    }
}
