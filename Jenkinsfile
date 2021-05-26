pipeline {
    agent {label "master"}
    options {
        buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '5', daysToKeepStr: '', numToKeepStr: '5')
    }
    stages {
        stage('Build') {
            environment {
                ADMIN_URL='manger_test'
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
            steps {
                sh '''
                    # ~/deploy.sh
                '''
            }
        }
    }
}
