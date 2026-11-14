# 🚀 Enterprise Cloud & DevSecOps Platform

An enterprise repository showcasing production infrastructure implementations on AWS: from a re-platformed multi-tier web application, to an automated 3-tier containerized DevSecOps pipeline, up to a cloud-native Kubernetes (EKS) platform with dynamic autoscaling.

---

# 🚀 Project 1: Multi-Tier Enterprise Web App Cloud Re-Platforming (VProfile)

A production-grade cloud migration re-architecting an on-premises multi-tier stack into highly available AWS managed services.

### 🏗️ Architecture Overview
* **Compute Layer:** AWS Elastic Beanstalk (Tomcat runtime) utilizing Auto Scaling triggers for horizontal elasticity.
* **Database Layer:** Amazon RDS MySQL deployed in Multi-AZ configuration with automated failover and daily backups.
* **In-Memory Caching:** Amazon ElastiCache (Memcached) cluster for database query offloading and session caching.
* **Asynchronous Messaging:** Amazon MQ (RabbitMQ) message broker enabling decoupled communication across application tiers.
* **Internal Routing & DNS:** Amazon Route 53 private hosted zones for internal endpoint resolution and decoupled service discovery.

### 🛠️ Tech Stack & Tools
* **Cloud Provider:** AWS (Elastic Beanstalk, RDS MySQL, ElastiCache Memcached, Amazon MQ, Route 53, CloudWatch)
* **Application Runtime:** Java, Apache Tomcat
* **Security & IAM:** AWS Secrets Manager for credential storage, strict Security Group isolation across tiers

---

# 🚀 Project 2: Production-Grade 3-Tier Web Application Infrastructure & CI/CD Pipeline

A robust, highly scalable, and secure 3-tier web application architecture deployed on AWS using Terraform (IaC), Docker, and an automated enterprise-grade GitHub Actions CI/CD Pipeline.

### 🏗️ Architecture Overview
The application follows a secure multi-tier networking model across Availability Zones:

* **Public Tier (Load Balancer):** AWS Application Load Balancer (ALB) handles incoming traffic with automatic HTTP-to-HTTPS redirection.
* **Private Compute Tier (Auto Scaling Group):** EC2 instances run inside private subnets managed via an ASG, utilizing Launch Templates, IAM Instance Profiles, and strict Security Groups. Zero-downtime rolling deployments are enforced via automated Instance Refreshes.
* **Data Tier:** MongoDB hosted on a dedicated private database instance, architected for seamless vertical scaling or future migration to managed database solutions.

### 🛠️ Tech Stack & Tools
* **Cloud Provider:** AWS (VPC, EC2, ALB, ASG, IAM, ECR, CloudWatch)
* **Infrastructure as Code (IaC):** Terraform
* **Containerization:** Docker & Docker Buildx
* **CI/CD Automation:** GitHub Actions (Optimized Caching, Vulnerability Scanning, Image Signing)
* **Security & Compliance:** Trivy (Container Scanning) & Cosign (Keyless OIDC Image Signing)
* **Monitoring & Observability:** AWS CloudWatch & Grafana/Prometheus

### 🔄 Enterprise CI/CD Pipeline Workflow
The automated pipeline (`deploy.yml`) handles code delivery through strict validation gates:

1. **Code Quality & Security Scan:** Runs lint checks with full git history checkout (`fetch-depth: 0`).
2. **Optimized Dependency Caching:** Leverages GitHub Actions caching (`actions/setup-node`) to speed up builds.
3. **Secure Containerization:** Builds the backend Docker image and pushes it securely to AWS ECR using metadata automation (latest + commit SHA tags).
4. **Vulnerability Scanning:** Trivy scans the built image for HIGH and CRITICAL vulnerabilities.
5. **Image Signing:** Cosign cryptographically signs the container image digest using Keyless OIDC, ensuring supply chain integrity.
6. **Zero-Downtime Deployment:** Triggers a dynamic AWS Auto Scaling Group Instance Refresh (`MinHealthyPercentage: 50`) to seamlessly roll out the latest code without downtime.

### 💡 Key Engineering Highlights
* **Zero-Downtime Deployments:** Configured ASG Instance Refreshes with health checks and warmup periods to ensure uninterrupted user traffic during updates.
* **Supply Chain Security:** Integrated image signing and vulnerability checks before hitting production servers.
* **Cost & Scalability Mindset:** Designed with vertical scaling patterns and future-proof migration paths for database workloads.

---

# 🚀 Project 3: Enterprise Cloud & DevSecOps Platform (AWS EKS)

> Production-grade Kubernetes platform on AWS using Terraform, Karpenter v1, and GitOps.

[![Status](https://img.shields.io/badge/Status-In%20Progress%20(Phase%201)-blue?style=flat-square)](https://github.com/)

### 📌 What This Is
Multi-AZ AWS EKS cluster automated end-to-end via Terraform, featuring sub-second node autoscaling via Karpenter v1 and declarative GitOps continuous delivery.

### 🛠️ Tech Stack
* **Cloud & IaC:** AWS (EKS, VPC, IAM IRSA), Terraform
* **Orchestration & Scaling:** Kubernetes (v1.30+), Karpenter v1 (`NodePool`, `EC2NodeClass`)
* **Traffic & Security:** AWS Load Balancer Controller, Istio (mTLS), cert-manager
* **GitOps & Monitoring:** ArgoCD, Prometheus, Grafana, Metrics Server

### 🏗️ Architecture Flow
`Traffic` ➔ `AWS ALB` ➔ `Istio Ingress` ➔ `EKS Pods (Private Subnets)` ➔ `Karpenter Auto-provisioned EC2 (Spot/On-Demand)`

### 🚧 Roadmap & Current Status
- [x] Multi-AZ VPC & Modular Terraform Foundation
- [x] EKS Control Plane + IAM OIDC (IRSA)
- [x] Karpenter v1 Dynamic Autoscaling Setup
- [ ] AWS Load Balancer Controller & SSL (cert-manager)
- [ ] ArgoCD GitOps & Microservices Deployment
- [ ] Istio Zero-Trust Mesh & RED Observability

### 🚀 Quick Start
```bash
# Provision Core Infra
cd terraform/environments/prod
terraform init && terraform apply

# Apply Karpenter Scalers
kubectl apply -f k8s/EC2NodeClass.yaml
kubectl apply -f k8s/NodePool.yaml
