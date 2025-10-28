pipeline {
    agent any
    tools {
        maven 'myMaven'
    }
    stages {
        stage('Checkout code') {
            steps {
                git branch: 'main', url: 'https://github.com/afouacherni/Compte-Service.git'
            }
        }
        stage('Compile code') {
            steps {
                sh 'mvn compile'
            }
        }
        stage('Test code') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Package code') {
            steps {
                sh 'mvn package'
            }
        }
    }
    post {
        success {
            junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
        }
    }
}
