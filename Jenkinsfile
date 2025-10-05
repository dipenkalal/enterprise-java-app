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

  environment {
    DOCKER_IMAGE = "docker.io/dipenkalal/java-app"
    IMAGE_TAG    = "build-${env.BUILD_NUMBER}"
    GITOPS_REPO  = "https://github.com/dipenkalal/enterprise-gitops.git"
    GITOPS_PATH  = "apps/java-app/values-dev.yaml"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Test') {
      steps {
        container('maven') {
          sh 'mvn -B -ntp clean verify'
        }
      }
    }

    stage('Build & Push Image (Jib)') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub_creds',
                                          usernameVariable: 'DH_USER',
                                          passwordVariable: 'DH_PASS')]) {
          container('maven') {
            sh '''
              mvn -B -ntp -DskipTests \
                -Dimage=${DOCKER_IMAGE}:${IMAGE_TAG} \
                -Djib.to.image=${DOCKER_IMAGE}:${IMAGE_TAG} \
                -Djib.to.auth.username=${DH_USER} \
                -Djib.to.auth.password=${DH_PASS} \
                com.google.cloud.tools:jib-maven-plugin:build
            '''
          }
        }
      }
    }

    stage('Update GitOps tag') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'github_https',
                                          usernameVariable: 'GH_USER',
                                          passwordVariable: 'GH_PAT')]) {
          sh '''
            rm -rf gitops && git clone https://${GH_USER}:${GH_PAT}@github.com/dipenkalal/enterprise-gitops.git gitops
            cd gitops
            # update the "tag:" in values-dev.yaml
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
    always { echo "Build #${env.BUILD_NUMBER} -> ${DOCKER_IMAGE}:${IMAGE_TAG}" }
  }
}
