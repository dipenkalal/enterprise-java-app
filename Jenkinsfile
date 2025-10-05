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
    buildDiscarder(logRotator(numToKeepStr: '20'))
    skipDefaultCheckout(true)
    timestamps()
    ansiColor('xterm')
  }

  environment {
    DOCKER_IMAGE = "docker.io/dipenkalal/java-app"
    GIT_SHA      = sh(returnStdout: true, script: 'git rev-parse --short HEAD || echo dev').trim()
    IMAGE_TAG    = "b${env.BUILD_NUMBER}-${GIT_SHA}"
    GITOPS_REPO  = "https://github.com/dipenkalal/enterprise-gitops.git"
    GITOPS_PATH  = "apps/java-app/values-dev.yaml"
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
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
          archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: true
          publishHTML(target: [
            reportDir: 'target/surefire-reports',
            reportFiles: 'index.html',
            reportName: 'Surefire report',
            keepAll: true,
            alwaysLinkToLastBuild: true
          ])
        }
      }
    }

    stage('Build & Push Image (main only)') {
      
    }

    stage('Update GitOps tag (main only)') {
      when { branch 'main' }
      steps {
        withCredentials([usernamePassword(credentialsId: 'github_https',
                                          usernameVariable: 'GH_USER',
                                          passwordVariable: 'GH_PAT')]) {
          sh '''
            rm -rf gitops && git clone https://${GH_USER}:${GH_PAT}@github.com/dipenkalal/enterprise-gitops.git gitops
            cd gitops
            awk -v tag="${IMAGE_TAG}" '
              BEGIN{done=0}
              /^ *tag:/ && !done { print "  tag: " tag; done=1; next }
              { print }
            ' ${GITOPS_PATH} > tmp && mv tmp ${GITOPS_PATH}
            git config user.name "jenkins-bot"
            git config user.email "jenkins-bot@example.com"
            git add ${GITOPS_PATH}
            git commit -m "ci(dev): bump ${DOCKER_IMAGE} to ${IMAGE_TAG}"
            git push origin main
          '''
        }
      }
    }
  }

  post {
    success { echo "OK: ${env.BRANCH_NAME} -> ${DOCKER_IMAGE}:${IMAGE_TAG}" }
    failure { echo "FAILED: ${env.BRANCH_NAME}" }
    always  { echo "Build #${env.BUILD_NUMBER} finished: ${currentBuild.currentResult}" }
  }
}
