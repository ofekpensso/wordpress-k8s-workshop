# 🚀 High-Availability WordPress on Kubernetes (AWS ECR + Helm Edition)

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Helm](https://img.shields.io/badge/HELM-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=Prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)

A production-grade infrastructure project deploying a scalable WordPress site on Kubernetes using **Helm Charts**.  
The project integrates with **AWS ECR** for private images, manages secrets securely, and includes a full monitoring stack.

---

## 🏗️ Architecture Highlights

- **Package Management:** Fully managed via a custom **Helm Chart** for easy upgrades and configuration.  
- **Secure Registry:** Images are pulled from a private **AWS ECR** repository using an automated CronJob for token rotation.  
- **Security:** No hardcoded passwords! A helper script injects AWS credentials and DB passwords directly into Kubernetes Secrets.  
- **Persistence:** MySQL/MariaDB runs as a **StatefulSet** with PVCs to ensure data survival across pod restarts.  
- **Traffic Routing:** Uses **Nginx Ingress Controller** for domain-based routing (`ofek-wordpress.local`).  
- **Observability:** Integrated **Prometheus & Grafana** stack with a custom dashboard for Pod health and restarts.  

---

## 🛠️ Prerequisites

- Kubernetes Cluster (Minikube / EKS / Kubeadm)  
- `kubectl` & `helm` installed  
- `aws-cli` configured with permissions to access ECR  

---

## 🚀 Quick Start Guide

### 1️⃣ Clone & Secure Setup

First, generate the necessary Kubernetes Secrets (AWS credentials & Database passwords) without committing them to Git.

```bash
# Clone the repository
git clone https://github.com/ofekpenso/wordpress-k8s-workshop.git
cd wordpress-k8s-workshop

# Run the secret generation script
chmod +x setup-secrets.sh
./setup-secrets.sh
```

Follow the prompts to enter your MySQL root and user passwords.

---

### 2️⃣ Install Monitoring Stack (Optional but Recommended)

We use the Prometheus Operator stack.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack
```

---

### 3️⃣ Deploy the Application

Deploy WordPress and MySQL using the custom Helm chart.

```bash
helm install my-blog ./my-wordpress-chart
```

---

### 4️⃣ Initialize ECR Access

Since the CronJob runs every 8 hours, trigger it manually once to get immediate access to the private ECR images.

```bash
kubectl create job --from=cronjob/ecr-renew-cron initial-token-job
```

---

# 🌐 Accessing the Application

## Method 1: Ingress (Production Style)

To access the site via a domain name, update your local hosts file.

### Edit Hosts File:

- Linux/Mac:
  ```bash
  sudo nano /etc/hosts
  ```

- Windows:
  ```
  C:\Windows\System32\drivers\etc\hosts
  ```

Add the following line:

```
<YOUR_SERVER_IP>  ofek-wordpress.local
```

### Open Tunnel (if using Minikube/EC2 without LoadBalancer):

```bash
sudo kubectl --kubeconfig $HOME/.kube/config port-forward -n ingress-nginx service/ingress-nginx-controller 80:80 --address 0.0.0.0
```

Visit:

```
http://ofek-wordpress.local
```

---

## Method 2: Port Forwarding (Quick Debug)

```bash
kubectl port-forward svc/wordpress-service 8080:80 --address 0.0.0.0
```

Visit:

```
http://<YOUR_SERVER_IP>:8080
```

---

# 📊 Monitoring Dashboard

Import the custom dashboard to visualize Pod health and availability.

### Access Grafana:

```bash
sudo kubectl --kubeconfig $HOME/.kube/config port-forward --address 0.0.0.0 -n monitoring service/monitoring-grafana 3000:80
```

URL:

```
http://localhost:3000
```

Credentials:

```
User: admin
Password: kubectl get secret --namespace monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

### Import Dashboard:

1. Go to **Dashboards → New → Import**
2. Upload the file:
   ```
   monitoring/custom-dashboard.json
   ```

---

# 📂 Project Structure

```
wordpress-k8s-workshop/
│
├── my-wordpress-chart/     # 📦 THE MAIN HELM CHART
│   ├── templates/          # K8s Manifests (Deployments, Services, Ingress)
│   ├── values.yaml         # Global configuration (Images, Replicas, Resources)
│   ├── Chart.yaml          # Metadata
│   └── .helmignore         # Packaging exclusions
│
├── monitoring/             # 📊 Grafana Dashboards
│   └── custom-dashboard.json
│
├── setup-secrets.sh        # 🔐 Automation script for Secrets
└── README.md               # 📖 Documentation
```

---

# 🧹 Cleanup (Disaster Recovery Drill)

To completely remove the installation and start fresh:

```bash
helm uninstall my-blog
kubectl delete pvc mysql-pv-claim
kubectl delete secret mysql-secrets aws-creds ecr-registry-helper
```

---

# 👨‍💻 Author

**Ofek Penso – DevOps Project**  

Built with ❤️ using Kubernetes, Helm, and AWS.
