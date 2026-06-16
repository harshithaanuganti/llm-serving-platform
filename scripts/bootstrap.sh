#!/usr/bin/env bash
#
# Bootstrap script — installs cluster-level dependencies after `terraform apply`.
# Run from the repo root after the EKS cluster is provisioned.
#
# Usage: ./scripts/bootstrap.sh

set -euo pipefail

CLUSTER_NAME="llm-serving-platform"
AWS_REGION="us-west-2"
DASHBOARD_PATH="monitoring/dashboards/llm-platform-dashboard.json"

echo "▶ Connecting kubectl to the cluster..."
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

echo "▶ Verifying cluster is reachable..."
kubectl get nodes

echo ""
echo "▶ Installing Argo CD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || true

echo "▶ Waiting for Argo CD pods to be ready (this can take 2-3 minutes)..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd

echo ""
echo "▶ Installing Prometheus + Grafana stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.maximumStartupDurationSeconds=300 \
  --wait --timeout 5m

echo ""
echo "▶ Installing KEDA..."
helm repo add kedacore https://kedacore.github.io/charts >/dev/null 2>&1 || true
helm repo update >/dev/null

kubectl create namespace keda --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install keda kedacore/keda \
  --namespace keda \
  --wait --timeout 3m

echo ""
echo "▶ Applying Argo CD application manifest..."
kubectl apply -f argocd/application.yaml

echo ""
echo "▶ Importing Grafana dashboard..."
if [ ! -f "$DASHBOARD_PATH" ]; then
  echo "  ⚠️  Dashboard JSON not found at $DASHBOARD_PATH — skipping import."
else
  # Wait for Grafana to be fully ready
  kubectl wait --for=condition=available --timeout=120s \
    deployment/monitoring-grafana -n monitoring

  # Get Grafana admin password
  GRAFANA_PASSWORD=$(kubectl get secret monitoring-grafana -n monitoring \
    -o jsonpath="{.data.admin-password}" | base64 -d)

  # Port-forward Grafana temporarily in the background
  kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80 &
  PF_PID=$!

  # Give port-forward a moment to establish
  sleep 3

  # Wrap the dashboard JSON in the format Grafana's import API expects
  DASHBOARD_JSON=$(cat "$DASHBOARD_PATH")
  IMPORT_PAYLOAD=$(printf '{"dashboard": %s, "overwrite": true, "folderId": 0}' "$DASHBOARD_JSON")

  # Import via Grafana HTTP API
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST http://localhost:3000/api/dashboards/db \
    -H "Content-Type: application/json" \
    -u "admin:${GRAFANA_PASSWORD}" \
    -d "$IMPORT_PAYLOAD")

  # Kill the temporary port-forward
  kill $PF_PID 2>/dev/null || true

  if [ "$HTTP_STATUS" = "200" ]; then
    echo "  ✅ Dashboard imported successfully!"
  else
    echo "  ⚠️  Dashboard import returned HTTP $HTTP_STATUS — you may need to import manually."
  fi
fi

echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Dashboards"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Argo CD     →  https://localhost:8080"
echo "    kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "    user: admin"
echo "    pass: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d ; echo"
echo ""
echo "  Grafana     →  http://localhost:3000"
echo "    kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80"
echo "    user: admin"
echo "    pass: kubectl get secret monitoring-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d ; echo"
echo ""
echo "  Prometheus  →  http://localhost:9090"
echo "    kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090"
echo "    (no login required)"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  Quick health checks"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  kubectl get pods -A"
echo "  kubectl get application -n argocd"
echo "  kubectl get scaledobject"
echo ""