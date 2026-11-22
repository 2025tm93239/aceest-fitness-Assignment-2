#!/bin/bash
# Load image into Minikube and apply rolling deployment manifests.
set -euo pipefail
cd "$(dirname "$0")/.."

eval "$(minikube docker-env)"
docker build -t aceest-fitness:latest .
docker tag aceest-fitness:latest aceest-fitness:stable
docker tag aceest-fitness:latest aceest-fitness:candidate
docker tag aceest-fitness:latest aceest-fitness:canary

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment-rolling.yaml
kubectl apply -f k8s/service.yaml
kubectl rollout status deployment/aceest-rolling -n aceest

echo ""
echo "Service URL:"
minikube service aceest-api -n aceest --url