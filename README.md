# LLM Serving Platform

A production-grade large language model serving platform built on Kubernetes, designed to handle real-world inference workloads with autoscaling, GitOps deployments, and full observability.

![Architecture](docs/images/architecture-diagram.png)

## Overview

This platform accepts text prompts via a REST API and returns generated text using a hosted language model, built to mirror how AI companies serve LLMs in production. The system is designed for reliability, cost efficiency, and operational visibility — not just getting a model running, but keeping it running well under load.

The platform is built in two phases. Phase 1 uses a CPU-based FastAPI stub to validate the full infrastructure stack end to end — Kubernetes, Helm, CI/CD, GitOps, and observability — without GPU costs. Phase 2 swaps in a real vLLM inference engine (Llama-3 8B) by changing a few lines in the Helm values file. The platform architecture is identical in both phases.

## Architecture

Incoming requests are routed through a Kubernetes Service to a pool of inference pods running on EKS. In Phase 1, pods run a FastAPI CPU stub that validates the serving infrastructure. In Phase 2, pods run vLLM with a quantized Llama-3 8B model with continuous batching for maximum throughput. Infrastructure is provisioned entirely as code using Terraform. Deployments are managed via Argo CD using a GitOps workflow — a push to the main branch triggers CI, which builds and pushes the image, then Argo CD automatically syncs the change to the cluster. The full observability stack (Prometheus + Grafana) provides real-time dashboards for request rate, latency percentiles, and per-endpoint traffic.

## Observability

Real-time monitoring with Prometheus and Grafana. The FastAPI app exposes Prometheus metrics at `/metrics`, a ServiceMonitor configures automatic scraping, and a custom Grafana dashboard tracks request rate, p99 latency, and requests by endpoint.

![Grafana Dashboard](docs/images/grafana-dashboard.png)

## Tech stack

Kubernetes (EKS) · FastAPI · vLLM (Phase 2) · Helm · Terraform · Argo CD · Prometheus · Grafana · GitHub Actions · AWS ECR · Docker · Python 3.11

## Status

- [x] Terraform EKS cluster provisioned
- [x] Docker image built and pushed to ECR
- [x] FastAPI CPU stub verified working locally
- [x] vLLM pods deployed via Helm
- [x] CI/CD pipeline green
- [x] Argo CD GitOps configured
- [x] Prometheus + Grafana dashboards live
- [ ] Autoscaling on GPU metrics (KEDA)
- [ ] Phase 2: real vLLM with Llama-3 8B
- [ ] Benchmark results documented
- [ ] Blog post published

## API

### Generate text
```
POST /v1/generate
Content-Type: application/json

{
  "prompt": "Hello world",
  "max_tokens": 256,
  "temperature": 0.7
}
```

### Health check
```
GET /healthz
```

### Metrics
```
GET /metrics
```
Prometheus-format metrics including request count, latency histograms, and request size.

## Benchmarks

*To be updated as the platform matures.*

| Metric | Phase 1 (CPU stub) | Phase 2 (vLLM + Llama-3 8B) |
|---|---|---|
| Model | FastAPI stub | Llama-3 8B INT4 |
| Hardware | t3.medium (CPU) | g4dn.xlarge (GPU) |
| Throughput (tokens/sec) | TBD | TBD |
| Latency p50 | TBD | TBD |
| Latency p99 | TBD | TBD |
| Batch size | TBD | TBD |

## Architecture decisions

- **Two-phase build** — validate the entire platform on cheap CPU infrastructure before incurring GPU costs. The Helm chart switches between CPU stub and GPU vLLM by changing resource limits and the container command.
- **GitOps with Argo CD** — git is the single source of truth. A push to main triggers CI, which builds and pushes the image, then Argo CD auto-deploys. No manual kubectl commands in normal operation.
- **Infrastructure as code** — the entire AWS environment (VPC, EKS, IAM, networking) is reproducible from Terraform in any region with one command.

## Local development

```bash
# Run locally
docker build -t llm-serving-platform:latest .
docker run -p 8000:8000 llm-serving-platform:latest

# Test
curl -X POST http://localhost:8000/v1/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello world", "max_tokens": 50}'
```

## Deployment

```bash
# Provision infrastructure
cd terraform
terraform apply

# Connect kubectl
aws eks update-kubeconfig --region us-west-2 --name llm-serving-platform

# Install Argo CD and apply the application manifest
kubectl apply -f argocd/application.yaml

# Argo CD then deploys the app automatically from git.
# Or deploy manually with Helm:
helm install llm-platform ./helm/vllm
```

## Project structure

```
llm-serving-platform/
├── app/                      # FastAPI inference application
│   ├── main.py
│   └── requirements.txt
├── terraform/                # Infrastructure as code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── eks/              # EKS cluster + node groups
│       └── vpc/              # VPC, subnets, networking
├── helm/vllm/                # Helm chart for deployment
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       └── servicemonitor.yaml
├── argocd/                   # Argo CD GitOps configuration
│   └── application.yaml
├── monitoring/dashboards/    # Grafana dashboard JSON
├── docs/images/              # Architecture diagram + screenshots
├── .github/workflows/        # CI/CD pipeline
│   └── ci.yml
├── Dockerfile
└── README.md
```