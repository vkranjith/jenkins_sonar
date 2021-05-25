pipeline {
  agent {label "master"}
  options {
    buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '5', daysToKeepStr: '', numToKeepStr: '5')
  }
  stages {
    stage('Build') {
      steps {
        sh '''
          ~/built.sh
        '''
      }
    }
    stage('Deploy') {
      when {
        branch "fix-*"
      }
      steps {
        sh '''
          echo "Starting the Deployment Process"
          
          cat README.md
          
          echo "Completed the Deployment Process"
        '''
      }
    }
  }
}
