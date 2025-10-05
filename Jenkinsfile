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

  options { timestamps() }

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
        // If junit/htmlpublisher plugins aren’t installed yet, comment these two lines:
        junit 'target/surefire-reports/*.xml'
        publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true,
                     reportDir: 'target/surefire-reports', reportFiles: 'index.html',
                     reportName: 'Surefire report'])
      }
    }

    stage('Build & Push Image (main only)') {
      when { branch 'main' }
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub_creds',
                                          usernameVariable: 'dipen7466',
                                          passwordVariable: '9016651945@Dipen')]) {
          container('maven') {
            sh '''
              set -eux
              IMAGE_TAG="b${BUILD_NUMBER}-dev"
              IMAGE_PATH="docker.io/${DH_USER}/java-app:${IMAGE_TAG}"

              mvn -B -ntp -DskipTests \
                com.google.cloud.tools:jib-maven-plugin:3.4.4:build \
                -Djib.to.image="${IMAGE_PATH}" \
                -Djib.to.auth.username="${DH_USER}" \
                -Djib.to.auth.password="${DH_PASS}"
            '''
          }
        }
      }
    }

    stage('Update GitOps tag (main only)') {
      when { branch 'main' }
      steps {
        withCredentials([usernamePassword(credentialsId: 'github_https',
                                          usernameVariable: 'GH_USER',
                                          passwordVariable: 'GH_PASS')]) {
          sh '''
            set -eux
            WORKDIR="$(mktemp -d)"
            git clone https://${GH_USER}:${GH_PASS}@github.com/dipenkalal/enterprise-gitops.git "$WORKDIR"
            cd "$WORKDIR/apps/java-app"

            # point dev values to the just-pushed image
            sed -i "s|image: .*|image: docker.io/${DH_USER}/java-app:b${BUILD_NUMBER}-dev|g" values-dev.yaml || true

            git config user.name "dipenkalal"
            git config user.email "171080107009.acet@gmail.com"
            git commit -am "ci: deploy java-app b${BUILD_NUMBER}-dev"
            git push origin main
          '''
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
