#!/bin/bash

echo "Creating AWS credentials secret..."

if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

kubectl create secret generic aws-creds \
  --from-literal=AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id) \
  --from-literal=AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key) \
  --from-literal=AWS_DEFAULT_REGION=$(aws configure get region) \
  --namespace default \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Secret 'aws-creds' created successfully!"
