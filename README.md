# LLM Serving Platform

A production-grade large language model serving platform built on Kubernetes, designed to handle real-world inference workloads with autoscaling, GitOps deployments, and full observability.

## Overview

This platform accepts text prompts via a REST API and returns generated text using a hosted language model, built to mirror how AI companies serve LLMs in production. The system is designed for reliability, cost efficiency, and operational visibility — not just getting a model running, but keeping it running well under load.

The platform is built in two phases. Phase 1 uses a CPU-based FastAPI stub to validate the full infrastructure stack end to end — Kubernetes, Helm, CI/CD, observability, and autoscaling — without GPU costs. Phase 2 swaps in a real vLLM inference engine (Llama-3 8B) by changing two lines in the Helm values file. The platform architecture is identical in both phases.

## Architecture

Incoming requests are routed through a Kubernetes Ingress controller to a pool of inference pods running on EKS. In Phase 1, pods run a FastAPI CPU stub that validates the serving infrastructure. In Phase 2, pods run vLLM with a quantized Llama-3 8B model with continuous batching for maximum throughput. Infrastructure is provisioned entirely as code using Terraform, with node pools that scale automatically based on utilization metrics. Deployments are managed via Argo CD using a GitOps workflow — a push to the main branch is the only action needed to update production. The full observability stack (Prometheus + Grafana) provides real-time dashboards for token throughput, request latency, and SLO burn rate.

## Tech stack

Kubernetes (EKS) · FastAPI · vLLM (Phase 2) · Helm · Terraform · Argo CD · Prometheus · Grafana · GitHub Actions · AWS ECR · Docker · Python 3.11

## Status

- [x] Terraform EKS cluster provisioned
- [x] Docker image built and pushed to ECR
- [x] FastAPI CPU stub verified working locally
- [ ] vLLM pods deployed via Helm
- [ ] CI/CD pipeline green
- [ ] Argo CD GitOps configured
- [ ] Prometheus + Grafana dashboards live
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