pipeline {
  agent {label "magento-2.4"}
  options {
    buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '5', daysToKeepStr: '', numToKeepStr: '5')
  }
  stages {
    stage('Hello') {
      steps {
        sh '''
          pwd
        ''',
        echo "Hello"
      }
    }
  }
}
