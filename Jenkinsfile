pipeline {
    agent {label "master"}
    options {
        buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '5', daysToKeepStr: '', numToKeepStr: '5')
    }
    stages {
        stage('Build') {
            environment {
                SERVER_LOCATION='192.168.56.104'
                ADMIN_URL='manager_test'
            }
            steps {
                sh '''
                    ~/build.sh
                '''
            }
        }
        stage('Deploy') {
            when {
                branch "fix-*"
            }
            environment {
                SERVER_LOCATION='192.168.56.104'
            }
            steps {
                sh '''
                    ~/deploy.sh
                '''
            }
        }
    }
}
