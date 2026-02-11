# Kubernetes WordPress Project 🚀

A robust, production-like WordPress deployment on Kubernetes (Minikube/AWS). This project demonstrates a full GitOps workflow including persistent storage, ingress networking, monitoring stack (Prometheus & Grafana), and automated secret management for AWS ECR.

---

## 🏗 Architecture

The project consists of the following components:

- **Application:** WordPress (Deployment with 2 replicas for high availability).
- **Database:** MariaDB/MySQL (StatefulSet with Persistent Volume Claim).
- **Networking:** NGINX Ingress Controller exposing the app via a custom domain.
- **Monitoring:** Full kube-prometheus-stack (Prometheus, Grafana, AlertManager).
- **Automation:** A CronJob that automatically renews AWS ECR authorization tokens every 8 hours.

---

## 🛠 Prerequisites

Before you begin, ensure you have the following installed:

- **AWS CLI** (Configured with `aws configure`)
- **Minikube** (Running on Docker driver)
- **Kubectl**
- **Helm** (For monitoring stack)

---

## 🚀 Getting Started

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/your-username/wordpress-k8s-workshop.git
cd wordpress-k8s-workshop
```

---

### 2️⃣ Setup Secrets (Important!)

For security reasons, secrets are not committed to the repository.

Run the provided setup script to inject your local AWS credentials into the cluster securely:

```bash
chmod +x setup-secrets.sh
./setup-secrets.sh
```

This script creates the `aws-creds` secret required by the automation bot.

---

### 3️⃣ Deploy the Infrastructure

#### Step A: Database (MySQL)

Deploy the StatefulSet and Service for the database first to ensure persistence.

```bash
kubectl apply -f mysql/mysql-pvc.yml
kubectl apply -f mysql/mysql-service.yml
kubectl apply -f mysql/mariadb-statefulset.yml
```

---

#### Step B: Application (WordPress)

Deploy the WordPress app and the CronJob for ECR authentication.

```bash
kubectl apply -f k8s-infrastructure/ecr-renew-cron.yml

# Ideally, run the job once manually to ensure the image pull secret exists immediately:
kubectl create job --from=cronjob/ecr-renew-cron init-ecr-secret

kubectl apply -f wordpress/wordpress-deployment.yml
kubectl apply -f wordpress/wordpress-service.yml
```

---

#### Step C: Networking (Ingress)

Deploy the Ingress rule to route traffic.

```bash
kubectl apply -f wordpress/wordpress-ingress.yml
```

---

## 🌐 Accessing the Application

Since this runs on Minikube (likely on a remote EC2), you need to tunnel the traffic.

### On the Server

Keep the port-forward running for the Ingress Controller:

```bash
sudo kubectl port-forward --address 0.0.0.0 -n ingress-nginx service/ingress-nginx-controller 80:80
```

### On Your Local Machine

Update your `/etc/hosts` file to point to the server IP:

```
<YOUR_EC2_PUBLIC_IP>  ofek-wordpress.local
```

Then browse to:

```
http://ofek-wordpress.local
```

---

## 📊 Monitoring (Prometheus & Grafana)

This project uses the kube-prometheus-stack for observability.

### Installation

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
```

---

### Accessing Grafana

#### Get Admin Password

```bash
kubectl get secret --namespace monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

#### Port Forward

```bash
sudo kubectl port-forward --address 0.0.0.0 -n monitoring service/monitoring-grafana 3000:80
```

Login at:

```
http://<YOUR_EC2_IP>:3000
```

- **User:** admin  
- **Password:** (retrieved from command above)

Navigate to:

```
Dashboards → New → Import
```

Or use the pre-built Kubernetes dashboards to view Pod Uptime and resource usage.

---

## 🤖 Automation (How the CronJob Works)

AWS ECR tokens expire every 12 hours.  
To prevent `ImagePullBackOff` errors, a Kubernetes CronJob runs every 8 hours:

1. Uses the injected `aws-creds`.
2. Authenticates against AWS ECR.
3. Updates the `ecr-registry-helper` secret in the cluster.

This ensures the WordPress deployment can always pull new images.

---

## 📂 Project Structure

```
.
├── k8s-infrastructure/     # Automation & Maintenance configs
│   └── ecr-renew-cron.yml  # The bot that renews ECR tokens
├── mysql/                  # Database configuration
│   ├── mariadb-statefulset.yml
│   ├── mysql-pvc.yml
│   └── mysql-service.yml
├── wordpress/              # Application configuration
│   ├── wordpress-deployment.yml
│   ├── wordpress-ingress.yml
│   └── wordpress-service.yml
├── setup-secrets.sh        # Local script to inject AWS credentials
└── README.md               # Project documentation
```

---

## ⚠️ Important: setup-secrets.sh File

Make sure this file exists in your project root directory.

```bash
#!/bin/bash

# setup-secrets.sh
# This script injects local AWS credentials into the Kubernetes cluster
# strictly for the use of the ECR renewal CronJob.

echo "Creating AWS credentials secret..."

# Verify AWS CLI connection
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

# Create the secret from current environment configuration
kubectl create secret generic aws-creds \
  --from-literal=AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id) \
  --from-literal=AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key) \
  --from-literal=AWS_DEFAULT_REGION=$(aws configure get region) \
  --namespace default \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secret 'aws-creds' created successfully! You can now deploy the CronJob."
```


