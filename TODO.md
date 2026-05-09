# DevOps Assessment - TODO

## Step 1: Project structure
- [x] Create folders: `app/`, `terraform/`, `terraform/modules/`, `monitoring/`, `.github/workflows/`

## Step 2: Application
- [x] Add `app/app.js` with `/health` and `/metrics`
- [x] Add `app/package.json`

## Step 3: Containerization
- [x] Add multi-stage `Dockerfile` using a non-root user

## Step 4: Monitoring
- [x] Add `monitoring/prometheus.yml`
- [x] Add `monitoring/docker-compose.yml` (Prometheus + Grafana)

## Step 5: Terraform (modular)
- [x] Add top-level Terraform files: provider/variables/outputs/backend docs
- [x] Add module: `terraform/modules/vpc/` (VPC + public subnets)
- [x] Add module: `terraform/modules/ecr/` (ECR repo)
- [x] Add module: `terraform/modules/ecs/` (ECS Fargate cluster + task + service + IAM + logs)
- [x] Add module: `terraform/modules/alb/` (ALB + listener + target group)
- [x] Add module: `terraform/modules/s3_backend/` (S3 bucket + DynamoDB lock table)
- [x] Add root wiring in `terraform/main.tf` calling the modules

## Step 6: GitHub Actions CI/CD
- [x] Add `.github/workflows/deploy.yml`:
  - x lint + test
  - x build Docker + push to ECR
  - x terraform init/validate/apply to deploy ECS

## Step 7: Documentation
- [x] Add `README.md`:
  - x architecture overview
  - x design decisions (ECS cost-efficiency, Prometheus vendor-neutral)
  - x Shift-left security notes (least privilege, env vars)
  - x pipeline + local run instructions
  - x Terraform backend setup instructions

## Step 8: Validation (best-effort)
- [x] Run `npm install` + local smoke tests (equivalent in CI: `npm test`)
- [x] Ensure Terraform wiring compiles logically (CI runs `terraform validate`)
