# 🚀 High-Availability WordPress on Kubernetes (Minikube & AWS)

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=Prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)

A production-grade implementation of WordPress on Kubernetes, deployed on an AWS EC2 instance using Minikube. This project demonstrates advanced DevOps practices including **Self-Healing**, **Secret Management**, **Persistent Storage**, **Automated ECR Authentication**, and **Full-Stack Monitoring**.

---

## 🏗 Architecture Overview

The infrastructure is designed to be resilient and observable:

- **Ingress Controller (NGINX):** Routes external HTTP traffic to the internal services.
- **WordPress Deployment:** Stateless application pods running in high availability (ReplicaSet).
- **MySQL StatefulSet:** Database with **Persistent Volume Claim (PVC)** ensuring data survives pod restarts.
- **Security Automation:** Custom bash script injects secrets directly into K8s memory (no plain-text secrets in Git).
- **ECR Refresher Bot:** A CronJob that automatically renews the AWS ECR token every 6 hours.
- **Monitoring Stack:** Prometheus & Grafana installed via Helm to monitor cluster health and pod uptime.

---

## 📂 Project Structure

```bash
.
├── k8s-infrastructure/
│   └── ecr-renew-cron.yml      # CronJob for AWS ECR authentication
├── mysql/
│   ├── mysql-pvc.yml           # Persistent Volume Claim
│   ├── mysql-service.yml       # Headless Service for Stable Network ID
│   └── mariadb-statefulset.yml # StatefulSet configuration
├── wordpress/
│   ├── wordpress-deployment.yml
│   ├── wordpress-service.yml
│   └── wordpress-ingress.yml
├── monitoring/                 # Monitoring configurations
├── setup-secrets.sh            # 🔐 Security Script (Injects secrets safely)
└── README.md
```

---

## 🛠️ Prerequisites

**Infrastructure:**  
AWS EC2 Instance (t3.medium or larger recommended).

**Tools:**  
- docker  
- minikube  
- kubectl  
- helm  

**Cloud:**  
AWS Account with ECR repository created.

---

## 🚀 Deployment Guide (How to Run)

Follow these steps to deploy the application from scratch.

### 1️⃣ Initialize Cluster

Start Minikube with the Docker driver and enable the Ingress addon (Critical for routing).

```bash
minikube start --driver=docker
minikube addons enable ingress
```

---

### 2️⃣ Secure Secret Injection

Instead of applying a YAML file with passwords, run the injection script.  
This script prompts for credentials and creates K8s Secrets directly.

```bash
chmod +x setup-secrets.sh
./setup-secrets.sh
```

---

### 3️⃣ Monitoring Stack (Helm)

Install Prometheus and Grafana for observability.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
```

---

### 4️⃣ Deploy Database Layer

Deploy the database first to ensure the PVC is bound.

```bash
kubectl apply -f mysql/mysql-pvc.yml
kubectl apply -f mysql/mysql-service.yml
kubectl apply -f mysql/mariadb-statefulset.yml
```

---

### 5️⃣ Deploy ECR Authentication Bot

Deploy a CronJob to handle private registry pulls from AWS.

```bash
kubectl apply -f k8s-infrastructure/ecr-renew-cron.yml

# Trigger manually for the first pull:
kubectl create job --from=cronjob/ecr-renew-cron init-ecr-login
```

---

### 6️⃣ Deploy Application Layer

```bash
kubectl apply -f wordpress/wordpress-deployment.yml
kubectl apply -f wordpress/wordpress-service.yml
kubectl apply -f wordpress/wordpress-ingress.yml
```

---

## 7️⃣ Access the Application

To access the services from outside the EC2 instance, run the following commands in **separate terminals**:

---

### 🖥 Terminal 1: WordPress Access

> Port 80 requires `sudo` + explicit kubeconfig path

```bash
sudo kubectl --kubeconfig /home/ubuntu/.kube/config \
port-forward --address 0.0.0.0 \
-n ingress-nginx service/ingress-nginx-controller 80:80
```

Access WordPress via:

```
http://<EC2-Public-IP>
```

---

### 📊 Terminal 2: Grafana Access (Port 3000)

```bash
kubectl --kubeconfig /home/ubuntu/.kube/config \
port-forward -n monitoring \
svc/monitoring-grafana 3000:80 \
--address 0.0.0.0
```

Access Grafana via:

```
http://<EC2-Public-IP>:3000
```

(Default credentials: `admin`)

---


## 🧪 Chaos Testing & Resilience

This project was tested for resilience:

- **Persistence Test:**  
  Created a post → Deleted MySQL Pod → Verified post still exists after pod recovery (PVC Success).

- **Self-Healing Test:**  
  Deleted WordPress pods → Kubernetes automatically recreated them (ReplicaSet Success).

- **Rolling Updates:**  
  Verified zero-downtime updates when changing image tags.

---

## 🔮 Future Improvements

- [ ] Convert all manifests into a unified Helm Chart.  
- [ ] Implement GitOps with ArgoCD.  
- [ ] Add HPA (Horizontal Pod Autoscaler) based on CPU usage.  

---

Created by **Ofek Penso** | DevOps Portfolio Project 2026
