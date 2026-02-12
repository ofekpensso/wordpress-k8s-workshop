# 🚀 WordPress High-Availability on Kubernetes (Helm Edition)

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=Prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)

This project demonstrates a **production-grade WordPress deployment** on a Kubernetes cluster (Minikube running on AWS EC2).

It includes:

- ✅ Private AWS ECR integration  
- ✅ Automated image pull secret rotation  
- ✅ Stateful database deployment  
- ✅ Persistent storage  
- ✅ Full monitoring stack (Prometheus + Grafana)  
- ✅ Helm-based package management  

This setup simulates a real-world DevOps production environment.

---

# 🏗️ Architecture Overview

## 🔹 Helm Chart
The entire stack is packaged and managed via a **custom Helm chart**, allowing reproducible, versioned deployments.

## 🔹 WordPress (Frontend)
- Deployed as a **scalable Deployment**
- Exposed via **Nginx Ingress Controller**
- Pulls images from **private AWS ECR**

## 🔹 MariaDB (Backend)
- Deployed as a **StatefulSet**
- Ensures stable network identity and persistent storage
- Designed for data consistency and reliability

## 🔹 Storage
- Uses **Persistent Volume Claims (PVCs)**
- Ensures WordPress and MariaDB data persist across pod restarts

## 🔹 Private Registry (AWS ECR)
- Images are stored in a private ECR repository
- Kubernetes authenticates using an imagePullSecret
- A **CronJob renews the ECR token every 8 hours**
- Manual bootstrap job available for immediate initialization

## 🔹 Monitoring Stack
Powered by:

- **kube-prometheus-stack**
- **Prometheus**
- **Grafana**
- Custom dashboard for:
  - Pod health
  - Resource usage
  - Cluster metrics

---

# 🛠️ Prerequisites

Before you begin, ensure the following tools are installed:

- **Minikube**
- **Kubectl**
- **Helm v3+**
- **AWS CLI** (configured with proper IAM permissions)
- EC2 instance with sufficient resources

---

# 🚀 Quick Start (Zero → Production)

## 1️⃣ Clone Repository & Setup Secrets

Secrets are NOT stored in Git for security reasons.

Clone the repository:

```bash
git clone https://github.com/ofekpenso/wordpress-k8s-workshop.git
cd wordpress-k8s-workshop
```

Make the setup script executable and run it:

```bash
chmod +x setup-secrets.sh
./setup-secrets.sh
```

This script:

- Creates Kubernetes secrets
- Configures AWS credentials
- Generates database passwords
- Creates imagePullSecret for ECR

---

## 2️⃣ Deploy the Stack with Helm

Install the entire infrastructure:

```bash
helm install my-blog ./my-wordpress-chart
```

Verify pods:

```bash
kubectl get pods
```

---

## 3️⃣ Initialize ECR Token (First Time Only)

Because the cluster needs immediate access to private ECR images, manually trigger the first job:

```bash
kubectl create job --from=cronjob/ecr-renew-cron initial-token-job
```

After that, the CronJob automatically renews the token every 8 hours.

---

## 4️⃣ Access the Application

### Update your local `/etc/hosts`

Add:

```
<YOUR_SERVER_IP>  ofek-wordpress.local
```

### Run Port Forward (Ingress)

```bash
sudo kubectl port-forward \
  --address 0.0.0.0 \
  -n ingress-nginx \
  service/ingress-nginx-controller 80:80
```

Then open:

👉 **http://ofek-wordpress.local**

---

# 📊 Monitoring

The monitoring stack uses **kube-prometheus-stack**.

## Install Monitoring (if not already installed)

```bash
helm install monitoring prometheus-community/kube-prometheus-stack
```

## Access Grafana

```bash
kubectl port-forward service/grafana 3000:80
```

Then visit:

👉 http://localhost:3000

(Default credentials usually: `admin / prom-operator` unless overridden)

---

## Import Custom Dashboard

1. Go to Grafana → Dashboards → Import  
2. Upload file:

```
/monitoring/custom-dashboard.json
```

This dashboard provides:

- Pod health metrics  
- CPU & Memory usage  
- WordPress performance visibility  
- Cluster resource overview  

---

# 📂 Project Structure

```
wordpress-k8s-workshop/
│
├── my-wordpress-chart/        # Main Helm chart (templates + values)
│
├── legacy-manifests/          # Raw YAML files used during development
│
├── monitoring/
│   └── custom-dashboard.json  # Grafana dashboard configuration
│
├── setup-secrets.sh           # Secret automation script
│
└── README.md
```

---

# 🔐 Security Considerations

- ❌ Secrets are not committed to Git  
- ✅ ECR token auto-rotation  
- ✅ Private image registry  
- ✅ Persistent storage isolation  
- ✅ Namespace separation (recommended)

---

# 🎯 What This Project Demonstrates

- Production-style Kubernetes architecture  
- Helm packaging best practices  
- Secure AWS ECR integration  
- CronJob-based token automation  
- Stateful workloads  
- Observability & monitoring  
- Clean project structure for real DevOps workflows  

---

# 👨‍💻 Author

**Ofek Penso**

DevOps / Cloud / Kubernetes Project  
Built as a production-style hands-on infrastructure deployment.
