#!/bin/bash

# quick-deploy.sh - Secure & Automated Deployment
# Includes "Fail-Fast" mechanisms to stop on errors.

# 🛑 SAFETY FIRST: Exit immediately if any command fails
set -e

# --- Helper Functions ---
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[step] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        error "$1 is not installed. Please install it first."
    fi
}

# --- 1. Pre-flight Checks ---
echo "🚀 Starting Safe Deployment..."
log "Checking prerequisites..."

check_command aws
check_command helm
check_command kubectl

# Check if AWS is actually logged in
if ! aws sts get-caller-identity &> /dev/null; then
    error "AWS CLI is not configured! Please run 'aws configure' and try again."
fi

# --- 2. Setup Secrets ---
log "Configuring Secrets..."
# We run this explicitly. If it fails, 'set -e' will stop the script.
chmod +x setup-secrets.sh
./setup-secrets.sh

# --- 3. Install NGINX Ingress Controller ---
log "Installing NGINX Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
# FIX: Added 'controller.service.type=NodePort' to prevent hanging on LoadBalancer creation
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --wait

# --- 4. Install Monitoring ---
log "Installing Monitoring Stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --create-namespace --namespace monitoring --wait

# --- 5. Deploy Application ---
log "Deploying WordPress & MariaDB..."
if helm status my-blog &> /dev/null; then
    log "Updating existing release..."
    helm upgrade my-blog ./my-wordpress-chart
else
    log "Installing new release..."
    helm install my-blog ./my-wordpress-chart
fi

# --- 6. Initialize ECR ---
log "Initializing ECR Token..."
kubectl delete job initial-token-job --ignore-not-found
kubectl create job --from=cronjob/ecr-renew-cron initial-token-job

# --- 7. Wait for Readiness ---
log "Waiting for WordPress to be ready (Timeout: 120s)..."
kubectl wait --for=condition=ready pod -l app=wordpress --timeout=120s

# --- 8. Final Output ---
# Get password safely
GRAFANA_PASS=$(kubectl get secret --namespace monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

# Get Public IP
SERVER_IP=$(curl -s http://checkip.amazonaws.com || curl -s https://ifconfig.me)

echo ""
echo "===================================================="
echo -e "${GREEN}🎉 DEPLOYMENT SUCCESSFUL!${NC}"
echo "===================================================="
echo "🌐 WordPress URL: http://ofek-wordpress.local"
echo "📊 Grafana URL:   http://localhost:3000"
echo "👤 Grafana User:  admin"
echo "🔑 Grafana Pass:  $GRAFANA_PASS"
echo "===================================================="
echo "📝 MANDATORY: Add this to your local /etc/hosts:"
echo "$SERVER_IP  ofek-wordpress.local"
echo "===================================================="
echo ""

log "Opening Port-Forwards in the background..."

sudo pkill -f "port-forward" || true

# Start new tunnels
sudo kubectl --kubeconfig $HOME/.kube/config port-forward -n ingress-nginx service/ingress-nginx-controller 80:80 --address 0.0.0.0 > /dev/null 2>&1 &
sudo kubectl --kubeconfig $HOME/.kube/config port-forward -n monitoring service/monitoring-grafana 3000:80 --address 0.0.0.0 > /dev/null 2>&1 &

echo "✅ Tunnels active. Run 'sudo pkill -f port-forward' to stop."