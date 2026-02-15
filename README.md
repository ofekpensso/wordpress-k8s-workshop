# 🚀 High-Availability WordPress on Kubernetes (Helm + AWS ECR)

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Helm](https://img.shields.io/badge/HELM-0F1689?style=for-the-badge&logo=helm&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=Prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)

A production-grade infrastructure project deploying a scalable WordPress site on Kubernetes using **Helm Charts**.  
This project demonstrates a real-world DevOps scenario including private registry integration (ECR), secret management, stateful databases, and full observability.

---

## 📌 Overview

This project provisions a **high-availability WordPress environment** inside a Kubernetes cluster with:

- ✅ Automated deployment (One-Click script)
- ✅ Manual step-by-step deployment (Educational mode)
- ✅ Private AWS ECR integration
- ✅ Secure secret management (no hardcoded credentials)
- ✅ MySQL StatefulSet with persistent storage
- ✅ NGINX Ingress routing
- ✅ Prometheus & Grafana monitoring stack

---

## 🏗️ Architecture Highlights

- **Automated Deployment:** Choose between a "One-Click" script or manual installation.
- **Package Management:** Managed via a custom Helm Chart (`my-wordpress-chart`).
- **Secure Registry:** Pulls images from private AWS ECR with automated token renewal (CronJob).
- **Security First:** Credentials injected into Kubernetes Secrets using helper scripts.
- **Persistence:** MySQL runs as a StatefulSet with PersistentVolumeClaims.
- **Traffic Routing:** NGINX Ingress routes traffic via `ofek-wordpress.local`.
- **Observability:** Full monitoring stack with Prometheus and Grafana dashboards.

---

## 🛠️ Prerequisites

Before starting, ensure you have:

- A running Kubernetes cluster (Minikube / EKS / EC2 + Kubeadm)
- `kubectl` installed and configured
- `helm` installed
- `aws-cli` installed and configured with ECR permissions

Verify:

```bash
kubectl version
helm version
aws sts get-caller-identity
```

---

# 🚀 Deployment Options

You can deploy using either:

- 🅰️ Fast Track (Fully Automated)
- 🅱️ Manual Deployment (Step-by-Step)

---

# 🅰️ Option A: Fast Track (Recommended) 🏎️

Best for quick demos and environment validation.

## 1️⃣ Grant Execution Permissions

```bash
chmod +x quick-deploy.sh setup-secrets.sh
```

## 2️⃣ Run the Automation Script

```bash
./quick-deploy.sh
```

### 🔍 What This Script Does

- Creates AWS & MySQL secrets
- Installs Prometheus & Grafana
- Deploys the WordPress Helm chart
- Initializes ECR authentication
- Starts port-forward tunnels automatically

After completion, you can immediately access the system.

---

# 🅱️ Option B: Manual Deployment (Educational Mode) 📚

Best for understanding the system components and debugging.

---

## 1️⃣ Setup Secrets

```bash
./setup-secrets.sh
```

---

## 2️⃣ Install Monitoring Stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  --create-namespace \
  --namespace monitoring
```

---

## 3️⃣ Deploy WordPress Application

```bash
helm install my-blog ./my-wordpress-chart
```

---

## 4️⃣ Initialize ECR Access

```bash
kubectl create job --from=cronjob/ecr-renew-cron initial-token-job
```

---

# 🌐 Hosts File Configuration (Mandatory)

You must map your domain to your server IP.

## 🔎 Find Your Server IP

- **EC2 / Remote Server:** Use Public IP
- **Minikube:**  
  ```bash
  minikube ip
  ```

---

## ✏️ Edit Hosts File

### Linux / macOS

```bash
sudo nano /etc/hosts
```

### Windows

Run Notepad as Administrator:

```
C:\Windows\System32\drivers\etc\hosts
```

---

## ➕ Add This Line

```
<YOUR_SERVER_IP>  ofek-wordpress.local
```

---

# 💻 Accessing the Application

---

## 🌍 WordPress Website

```
http://ofek-wordpress.local
```

If not accessible, verify that the Ingress port-forward is active.

---

## 📊 Grafana Dashboard

```
http://localhost:3000
```

### Default Credentials

- **Username:** `admin`
- **Password:**

### Fast Track
Displayed automatically at the end of the script.

### Manual Retrieval

```bash
kubectl get secret --namespace monitoring monitoring-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

---

## 📈 Import Custom Dashboard

Inside Grafana:

```
Dashboards → New → Import
```

Upload:

```
monitoring/custom-dashboard.json
```

---

# 🧹 Cleanup & Disaster Recovery

---

## 🛑 Stop Background Port-Forwards

If using Fast Track:

```bash
sudo pkill -f port-forward
```

---

## 🗑️ Full Cluster Cleanup

```bash
helm uninstall my-blog
helm uninstall monitoring -n monitoring

kubectl delete namespace monitoring
kubectl delete pvc mysql-pv-claim
kubectl delete secret mysql-secrets aws-creds ecr-registry-helper
```

---

# 📂 Project Structure

```
wordpress-k8s-workshop/
│
├── quick-deploy.sh         # 🚀 One-Click Deployment Script
├── setup-secrets.sh        # 🔐 Secret Injection Script
│
├── my-wordpress-chart/     # 📦 Custom Helm Chart
│   ├── templates/          # Kubernetes Manifests
│   ├── values.yaml         # Configuration Values
│   └── Chart.yaml
│
├── monitoring/             # 📊 Observability
│   └── custom-dashboard.json
│
└── README.md               # 📖 Documentation
```

---

# 🔐 Security Considerations

- No credentials are stored in source control.
- Secrets are dynamically created inside Kubernetes.
- ECR token auto-renewal prevents image pull failures.
- MySQL data persists across pod restarts.

---

# 📈 Future Improvements

- Horizontal Pod Autoscaler (HPA)
- HTTPS with Cert-Manager
- CI/CD pipeline (GitHub Actions)
- Terraform-based infrastructure provisioning
- External DNS automation

---

# 👨‍💻 Author

**Ofek Penso**  
DevOps Infrastructure Project  

Built with ❤️ using Kubernetes, Helm, and AWS.
