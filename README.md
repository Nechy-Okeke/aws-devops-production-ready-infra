 Metrics + Health Node.js on AWS (ECS Fargate + ALB + ECR) — Production-ready DevOps Practical


This repo provisions and deploys a small Node.js service that exposes:
- `GET /health` (liveness)
- `GET /metrics` (Prometheus-compatible metrics)

It also includes:
- Multi-stage Docker build with **non-root** runtime user
- Modular Terraform (VPC, ECR, ECS Fargate, ALB, S3/DynamoDB Terraform state backend)
- CI/CD with GitHub Actions (lint, test, build Docker image, push to ECR, Terraform apply)
- Monitoring assets: `prometheus.yml` + `docker-compose.yml` (Prometheus + Grafana)

---

## Architecture Overview

**Traffic flow**
`ALB (public) → ECS Fargate Service (awsvpc) → container (/health, /metrics)`

**Container image flow**
`GitHub Actions → Docker build → ECR → ECS task definition`

**Metrics / Observability**
- Container exposes `/metrics` for Prometheus.
- ECS service sends application logs to **CloudWatch Logs** via `awslogs`.

**Monitoring (local)**
- `docker-compose.yml` runs:
  - Prometheus (scrapes `/metrics`)
  - Grafana (ready to connect to Prometheus)

---

## Design Decisions

### Why ECS Fargate?
- **Cost-efficiency and operational simplicity** for a small service:
  - no instance management (unlike EC2)
  - simple autoscaling options
- Production-friendly defaults:
  - ALB integration, awsvpc networking, CloudWatch logging

### Why Prometheus (vendor-neutral monitoring)?
- `/metrics` endpoint follows a standard exposition format.
- Prometheus + Grafana avoids vendor lock-in for metrics ingestion/visualization.

### Why S3 + DynamoDB for Terraform backend locking?
- Prevents concurrent `terraform apply` runs from corrupting state.
- S3 stores state; DynamoDB provides a lock with `PAY_PER_REQUEST`.
- This design is compatible with automated CI pipelines (state is locked during applies).

---

## Repository Structure

```
app/
  app.js
  package.json

monitoring/
  prometheus.yml
  docker-compose.yml

terraform/
  backend.tf (notes)
  main.tf
  provider.tf
  variables.tf
  outputs.tf
  modules/
    vpc/
    ecr/
    ecs/
    alb/
    s3_backend/

.github/
  workflows/
    deploy.yml

Dockerfile
README.md
```

---

## Prerequisites

1. **AWS account**
2. **GitHub repository** configured with Secrets (names used in workflow):
   - `AWS_REGION` (e.g. `us-east-1`)
   - `AWS_ROLE_TO_ASSUME` (recommended for least privilege via OIDC)
   - `ECR_REPOSITORY` (optional override; workflow defaults to `metrics-health-service`)
   - `ECS_SERVICE_NAME` (optional override)
   - `PROJECT_NAME` (optional override)
   - `TF_STATE_BUCKET` (S3 bucket name for Terraform state)
   - `TF_LOCK_TABLE` (DynamoDB lock table name)
   - `TF_STATE_KEY` (optional override; default `terraform/terraform.tfstate`)

> Note on Terraform backend (state locking)
> Terraform backends require S3/Dynamo resources to exist **before** `terraform init`.
> This repo uses a two-phase deploy in GitHub Actions:
> 1) **Bootstrap** (`terraform/bootstrap`) to create:
>    - S3 bucket (state)
>    - DynamoDB table (locking)
> 2) **Main apply** (`terraform/`) using `terraform init -backend-config=...`.

---

## How to Run Monitoring Locally

1. Start Prometheus + Grafana:
```bash
cd monitoring
docker compose up -d
```

2. Prometheus is available at:
- `http://localhost:9090`

3. Grafana is available at:
- `http://localhost:3000`
  - default credentials (Grafana image default): `admin / admin`

> `monitoring/prometheus.yml` scrapes `${ALB_DNS_NAME}:80`.
> - `monitoring/docker-compose.yml` sets `ALB_DNS_NAME=app:3000` for local use.

---

## How to Build & Test the App Locally

```bash
npm install
npm test
node app/app.js
```

- Health: `http://localhost:3000/health`
- Metrics: `http://localhost:3000/metrics`

---

## Deployment Pipeline (GitHub Actions)

On every push to `main`, `.github/workflows/deploy.yml` performs:

1. **Lint** (best-effort)
2. **Test** (basic smoke test against `/health`)
3. **Build Docker image**
4. **Push image to ECR**
   - tags: `${GITHUB_SHA}` and `latest`
5. **Terraform init + validate** (main stack, with backend configured for the bootstrapped bucket/table)
6. **Terraform apply**
   - updates ECS task definition image tag and deploys service

### Shift-Left Security in CI/CD
- GitHub Actions uses **OIDC** (`configure-aws-credentials`) to assume an IAM role (`AWS_ROLE_TO_ASSUME`).
- Terraform provisions least-privileged IAM roles for ECS:
  - execution role for ECR pull + CloudWatch logs
  - task role kept minimal for app runtime

Secrets are never hard-coded; runtime configuration uses **environment variables**.

---

## Terraform Modules (High level)

- `terraform/modules/vpc`
  - VPC + **public subnets**
- `terraform/modules/ecr`
  - ECR repository for the app image
- `terraform/modules/ecs`
  - ECS cluster + Fargate task definition + ECS service + logging + IAM roles
- `terraform/modules/alb`
  - ALB + listener + target group forwarding to ECS tasks
- `terraform/modules/s3_backend`
  - S3 state bucket + DynamoDB lock table

---

## Outputs / Where to Find the App

After Terraform apply completes, Terraform outputs:
- `alb_dns_name` — use this to access the service:
  - `http://<alb_dns_name>/health`
  - `http://<alb_dns_name>/metrics`

Logs:
- CloudWatch Logs group created by ECS module for the task definition.

---

<!-- NOTE: docs-only change to create a clean commit on top of an earlier incorrect message. -->
## Improvements / Next Steps
- Add TLS termination (HTTPS) to ALB using ACM
- Add ECS service autoscaling policies
- Add Grafana provisioning dashboards automatically
- Add an ECS service health check grace period and more robust routing behavior
