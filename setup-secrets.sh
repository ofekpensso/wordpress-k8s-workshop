#!/bin/bash

# setup-secrets.sh
# This script injects ALL necessary secrets into the cluster.
# UPDATED: Now creates 'mysql-secrets' to match the WordPress deployment.

echo "🚀 Starting Project Setup..."

echo "1️⃣  Configuring AWS Credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ Error: AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

kubectl create secret generic aws-creds \
  --from-literal=AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id) \
  --from-literal=AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key) \
  --from-literal=AWS_DEFAULT_REGION=$(aws configure get region) \
  --namespace default \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secret 'aws-creds' created."

echo "2️⃣  Configuring Database Secrets..."
echo -n "Enter a secure password for MySQL root user: "
read -s MYSQL_ROOT_PASSWORD
echo
echo -n "Enter a secure password for WordPress database user: "
read -s MYSQL_PASSWORD
echo

kubectl create secret generic mysql-secrets \
  --from-literal=MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
  --from-literal=MYSQL_USER=wordpress \
  --from-literal=MYSQL_PASSWORD=$MYSQL_PASSWORD \
  --from-literal=MYSQL_DATABASE=wordpress \
  --namespace default \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secret 'mysql-secrets' created successfully."
echo "🎉 All secrets configured! You can now run 'kubectl apply'."