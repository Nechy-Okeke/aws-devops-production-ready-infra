# DevOps Assessment - TODO

## Step 1: Project structure
- [ ] Create folders: `app/`, `terraform/`, `terraform/modules/`, `monitoring/`, `.github/workflows/`

## Step 2: Application
- [ ] Add `app/app.js` with `/health` and `/metrics`
- [ ] Add `app/package.json`

## Step 3: Containerization
- [ ] Add multi-stage `Dockerfile` using a non-root user

## Step 4: Monitoring
- [ ] Add `monitoring/prometheus.yml`
- [ ] Add `monitoring/docker-compose.yml` (Prometheus + Grafana)

## Step 5: Terraform (modular)
- [ ] Add top-level Terraform files: provider/variables/outputs/backend docs
- [ ] Add module: `terraform/modules/vpc/` (VPC + public subnets)
- [ ] Add module: `terraform/modules/ecr/` (ECR repo)
- [ ] Add module: `terraform/modules/ecs/` (ECS Fargate cluster + task + service + IAM + logs)
- [ ] Add module: `terraform/modules/alb/` (ALB + listener + target group)
- [ ] Add module: `terraform/modules/s3_backend/` (S3 bucket + DynamoDB lock table)
- [ ] Add root wiring in `terraform/main.tf` calling the modules

## Step 6: GitHub Actions CI/CD
- [ ] Add `.github/workflows/deploy.yml`:
  - lint + test
  - build Docker + push to ECR
  - terraform init/validate/apply to deploy ECS

## Step 7: Documentation
- [ ] Add `README.md`:
  - architecture overview
  - design decisions (ECS cost-efficiency, Prometheus vendor-neutral)
  - Shift-left security notes (least privilege, env vars)
  - pipeline + local run instructions
  - Terraform backend setup instructions

## Step 8: Validation (best-effort)
- [ ] Run `npm install` + local smoke tests (if tooling available)
- [ ] Run `terraform fmt -check` and `terraform validate` (if tooling available)
