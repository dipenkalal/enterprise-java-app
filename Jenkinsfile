pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.9-eclipse-temurin-17
    command: ['cat']
    tty: true
"""
    }
  }

  options {
    timestamps()
    ansiColor('xterm')
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Test') {
      steps {
        container('maven') {
          sh 'mvn -B -ntp clean verify'
        }
        junit '**/target/surefire-reports/*.xml'
        publishHTML(target: [
          allowMissing: false,
          alwaysLinkToLastBuild: true,
          keepAll: true,
          reportDir: 'target/surefire-reports',
          reportFiles: 'index.html',
          reportName: 'Surefire report'
        ])
      }
    }


stage('SonarQube Analysis') {
  steps {
    container('maven') {
      withSonarQubeEnv('SonarQube') {
        withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
          sh '''
            set -eux
            mvn -B -ntp verify sonar:sonar \
              -Dsonar.projectKey=java-app \
              -Dsonar.projectName=java-app \
              -Dsonar.token=$SONAR_TOKEN
          '''
        }
      }
    }
  }
}
stage('Quality Gate') {
  steps {
    timeout(time: 10, unit: 'MINUTES') {
      script {
        def qg = waitForQualityGate() // waits for webhook/polls
        if (qg.status != 'OK') {
          error "Quality Gate failed: ${qg.status}"
        }
      }
    }
  }
}




  }

  post {
    always {
      echo "Build #${env.BUILD_NUMBER} finished: ${currentBuild.currentResult}"
    }
  }
}
