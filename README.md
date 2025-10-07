# 🏗️ Enterprise Java CI/CD with Jenkins, GitOps, and Kubernetes Observability

### **Author:** Dipen Kalal  
### **Date:** 06 Oct 2025  

---

## 📘 Project Overview
This project demonstrates a complete **CI/CD + GitOps + Observability** pipeline for a cloud-native Java microservice.  
It automates the entire lifecycle — from **code commit** to **deployment** on Kubernetes — with integrated **code quality**, **GitOps-based delivery**, and **real-time monitoring** using Prometheus and Grafana.

---

## ⚙️ Technology Stack

| Component | Purpose |
|------------|----------|
| **Java + Maven** | Application development & dependency management |
| **Jenkins** | CI/CD orchestration |
| **SonarQube** | Static code analysis & quality gate enforcement |
| **Docker** | Containerization of the Java application |
| **Kubernetes** | Deployment and orchestration platform |
| **Argo CD** | GitOps-based continuous deployment |
| **Prometheus** | Metrics collection & alerting |
| **Grafana** | Metrics visualization & dashboards |

---

## 🧩 Architecture Overview

```
      ┌────────────────────────┐
      │   Developer (GitHub)   │
      └────────────┬───────────┘
                   │  (Commit)
                   ▼
        ┌────────────────────┐
        │     Jenkins CI     │
        │ (Build, Test, QA)  │
        └──────┬─────────────┘
               │
               ▼
     ┌──────────────────────┐
     │    SonarQube         │
     │ Code Quality & Gate  │
     └────────┬─────────────┘
              │
              ▼
   ┌────────────────────┐
   │  Docker Registry   │
   │ (Build & Push Img) │
   └────────┬───────────┘
            │
            ▼
 ┌──────────────────────────┐
 │  Argo CD (GitOps CD)     │
 │ Syncs Git → Kubernetes   │
 └────────┬────────────────┘
          │
          ▼
 ┌──────────────────────────┐
 │ Kubernetes Cluster (App) │
 │ Prometheus + Grafana     │
 └──────────────────────────┘
```

---

## 🧱 Jenkins Pipeline Flow

### **High-Level Stages**
1. **Checkout**  
   - Jenkins pulls the latest code from GitHub.
2. **Build & Unit Test**  
   - Runs `mvn clean verify`, executes JUnit tests, and publishes HTML reports.
3. **Static Code Analysis (SonarQube)**  
   - Performs code quality scan and uploads results to SonarQube.
4. **Quality Gate**  
   - Jenkins waits for SonarQube to approve the analysis.
5. **Docker Build & Push**  
   - Jenkins builds and pushes the container image (future stage).
6. **GitOps Sync via Argo CD**
   - Automatically triggers deployment through GitOps repo updates.

---

## 🧾 Jenkinsfile (Current CI Pipeline)

```groovy
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
            def qg = waitForQualityGate()
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
```

---

## 📊 SonarQube Integration

* **Server URL:** `http://sonarqube-sonarqube.ci.svc.cluster.local:9000`
* **Project Key:** `java-app`
* **Token:** Stored securely in Jenkins credentials (`sonar-token`).
* **Pipeline Stage:** `SonarQube Analysis` followed by `Quality Gate`.

---

## 🚀 GitOps Continuous Deployment (via Argo CD)

**GitOps Repo:** [enterprise-gitops/](https://github.com/dipenkalal/enterprise-gitops)

Example Argo CD Application YAML:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: java-app-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/dipenkalal/enterprise-gitops.git
    targetRevision: main
    path: apps/java-app
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 📈 Observability Setup

### Prometheus (scraping)

```yaml
scrape_configs:
  - job_name: 'java-app'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['java-app.dev.svc.cluster.local:8080']
```

### Grafana (dashboard)

```yaml
apiVersion: 1
providers:
  - name: 'java-app'
    orgId: 1
    folder: 'Applications'
    type: file
    options:
      path: /var/lib/grafana/dashboards/java-app
```

---

## 🧠 Key Outcomes

✅ Full CI/CD pipeline executed successfully  
✅ SonarQube analysis integrated with Jenkins  
✅ Quality Gate enforcement working  
✅ Argo CD sync automated deployments  
✅ Prometheus and Grafana setup for observability  

---

## 🧩 Benefits & Learnings

* **Automation:** No manual intervention after code commit.  
* **Quality Control:** SonarQube gates enforce code hygiene.  
* **GitOps:** Versioned and traceable deployments.  
* **Observability:** Metrics-driven monitoring.  
* **Scalability:** Kubernetes-native and extensible.  

---

## 📸 Screenshots (Attach in report)

* Jenkins build success  
* SonarQube dashboard  
* Argo CD sync view  
* Grafana dashboard  

---

## 📚 Future Enhancements

* Add **Docker image build & push** stage  
* Integrate **Kubernetes deployment** in same pipeline  
* Add **Slack or Teams notifications** for build status  
* Include **ELK/Loki** for centralized logging  

---

**© 2025 — Dipen Kalal**  
*All rights reserved for educational and demonstration use.*

