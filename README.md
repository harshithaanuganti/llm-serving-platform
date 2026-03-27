# LLM Inference Platform

A production-grade large language model serving platform built on Kubernetes, designed to handle real-world inference workloads with autoscaling, GitOps deployments, and full observability.

## Overview

This platform accepts text prompts via a REST API and returns generated text using a hosted language model, built to serve LLMs in production. The system is designed for reliability, cost efficiency, and operational visibility, not just getting a model running, but keeping it running well under load.

## Architecture

Incoming requests are routed through a Kubernetes Ingress controller to a pool of vLLM inference pods, each running a quantized language model with continuous batching for maximum throughput. Infrastructure is provisioned entirely as code using Terraform, with GPU node pools that scale automatically based on utilization metrics. Deployments are managed via Argo CD using a GitOps workflow, a push to the main branch is the only action needed to update production. The full observability stack (Prometheus + Grafana) provides real-time dashboards for token throughput, request latency, GPU utilization, and SLO burn rate.

## Tech stack

Kubernetes (EKS) · vLLM · Helm · Terraform · Argo CD · Prometheus · Grafana · GitHub Actions · AWS ECR · Docker

## Status

- [ ] Terraform EKS cluster provisioned
- [ ] vLLM pods deployed via Helm
- [ ] CI/CD pipeline green
- [ ] Argo CD GitOps configured
- [ ] Prometheus + Grafana dashboards live
- [ ] Autoscaling on GPU metrics (KEDA)
- [ ] Benchmark results documented
- [ ] Blog post published

## Benchmarks

*To be updated as the platform matures.*

| Metric | Value |
|---|---|
| Model | TBD |
| Hardware | TBD |
| Throughput (tokens/sec) | TBD |
| Latency p50 | TBD |
| Latency p99 | TBD |
| Batch size | TBD |