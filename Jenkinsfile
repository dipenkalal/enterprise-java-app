pipeline {
  agent any
  options { timestamps() }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Hello CI') {
      steps {
        sh 'echo CI is alive on $(uname -a)'
      }
    }
  }
  post {
    always { echo "Build #${env.BUILD_NUMBER} finished: ${currentBuild.currentResult}" }
  }
}
