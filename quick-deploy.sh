#!/bin/bash

# quick-deploy.sh - Automated Fast-Track Deployment
# This script handles the entire lifecycle from zero to a running environment.

echo "🚀 Starting High-Speed Deployment..."

# 1. Setup Secrets
echo "🔐 Step 1: Configuring Secrets..."
chmod +x setup-secrets.sh
./setup-secrets.sh

# 2. Install Monitoring
echo "📊 Step 2: Installing Monitoring Stack (Prometheus & Grafana)..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack --create-namespace --namespace monitoring

# 3. Deploy Application
echo "📦 Step 3: Deploying WordPress and MariaDB..."
helm install my-blog ./my-wordpress-chart

# 4. Initialize ECR
echo "🔑 Step 4: Initializing ECR Token..."
kubectl create job --from=cronjob/ecr-renew-cron initial-token-job

# 5. Wait for Readiness
echo "⏳ Waiting for WordPress to be ready (this may take a minute)..."
kubectl wait --for=condition=ready pod -l app=wordpress --timeout=120s

# 6. Final Instructions & Access
GRAFANA_PASS=$(kubectl get secret --namespace monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
SERVER_IP=$(curl -s http://checkip.amazonaws.com)

echo ""
echo "===================================================="
echo "🎉 DEPLOYMENT COMPLETE!"
echo "===================================================="
echo "🌐 WordPress URL: http://ofek-wordpress.local"
echo "📊 Grafana URL:   http://localhost:3000"
echo "🔑 Grafana Pass:  $GRAFANA_PASS"
echo "===================================================="
echo "📝 MANDATORY STEP: Add this to your local /etc/hosts:"
echo "$SERVER_IP  ofek-wordpress.local"
echo "===================================================="
echo ""

echo "🚀 Opening Port-Forwards in the background..."
sudo kubectl --kubeconfig $HOME/.kube/config port-forward -n ingress-nginx service/ingress-nginx-controller 80:80 --address 0.0.0.0 > /dev/null 2>&1 & 

sudo kubectl --kubeconfig $HOME/.kube/config port-forward --address 0.0.0.0 -n monitoring service/monitoring-grafana 3000:80 > /dev/null 2>&1 &

echo "✅ Port-forwards are running in the background."
echo "💡 To stop them later, run: pkill -f port-forward"
