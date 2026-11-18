# ☸️ Enterprise AWS EKS & GitOps Kubernetes Platform

A production-ready Kubernetes platform engineered on **Amazon EKS**, utilizing **Terraform**, **ArgoCD (App-of-Apps)**, **Karpenter**, and **Prometheus/Grafana** to automate application delivery, intelligent node autoscaling, and full-stack observability.

---

## 🏗️ Platform Architecture

```text
GitHub Repository (Declarative Manifests)
        │
        ▼ (Auto-Sync & Self-Heal)
ArgoCD (App-of-Apps Pattern)
   ├── apps/           ──► SmartBite Monolithic App (HPA) + MongoDB (EBS gp3 PVC)
   ├── networking/     ──► AWS Load Balancer Controller (ALB Ingress)
   ├── observability/  ──► kube-prometheus-stack (Prometheus, Grafana, Alertmanager)
   └── security/       ──► RBAC, Namespace Isolation, Policy Enforcement
        │
        ▼ (Just-in-Time Compute Provisioning)
Karpenter Node Autoscaler (AWS EC2 Spot/On-Demand)
```

---

## 🛠️ Core Platform Components

* **Infrastructure Provisioning (Terraform):** Automated EKS cluster setup with OIDC provider, IRSA (IAM Roles for Service Accounts), EBS CSI Driver (`gp3` persistent storage), and VPC networking.
* **Declarative GitOps (ArgoCD):** Managed via a single `root-bootstrap-app` (App-of-Apps pattern) that continuously reconciles cluster state against Git, featuring automated drift detection and self-healing.
* **Intelligent Autoscaling (Karpenter + HPA):**
  * **Pod-Level:** Horizontal Pod Autoscaler (HPA) scales workloads dynamically based on CPU/Memory utilization via `metrics-server`.
  * **Node-Level:** Karpenter provisions right-sized EC2 nodes in seconds when pending pods require compute and consolidates underutilized nodes to cut AWS costs.
* **Ingress & Load Balancing:** AWS Load Balancer Controller dynamically provisions internet-facing Application Load Balancers (ALBs) with IP-mode target routing.
* **Observability & Disaster Recovery:** Full cluster telemetry via **Prometheus & Grafana**, alongside **Velero** for cluster resource backups.

---

## 🐛 Production Troubleshooting & Engineering Learnings

Real-world infrastructure issues encountered and resolved during cluster deployment and GitOps reconciliation:

1. **AWS ALB Ingress Target Port Mismatch (`502 Bad Gateway` / Health Check Failures)**
   * **Root Cause:** The Node.js application container listened on port `3000`, while the Kubernetes `ClusterIP` service and Ingress manifests initially targeted port `80` without port translation, causing ALB target group health checks to fail.
   * **Resolution:** Standardized the traffic chain (`Ingress: 80` → `Service port: 80 / targetPort: 3000` → `Pod containerPort: 3000`) and verified IP-mode target registration on the AWS ALB.

2. **Database Service Discovery & Environment Configuration (`MONGO_URI`)**
   * **Root Cause:** Application pods defaulted to local database fallback strings during container startup because the Kubernetes internal DNS endpoint for MongoDB was not injected via deployment environment variables.
   * **Resolution:** Configured explicit `MONGO_URI` environment injection pointing to the cluster-internal FQDN (`mongodb://canteen-db-svc.prod.svc.cluster.local:27017/canteenDB`) backed by an AWS EBS `gp3` PersistentVolumeClaim.

3. **GitOps Sync Ordering & Namespace Dependency (`namespaces "prod" not found`)**
   * **Root Cause:** Applying child ingress and workload manifests prior to namespace initialization caused sync rejections in ArgoCD.
   * **Resolution:** Enforced declarative namespace provisioning (`CreateNamespace=true` sync policy in ArgoCD `root-bootstrap-app`) and structured the App-of-Apps hierarchy to ensure deterministic resource rollout.

4. **CI-to-CD Manifest Merge Conflicts on Automated Image Tag Updates**
   * **Root Cause:** Simultaneous manual manifest edits and automated GitHub Actions commit-SHA image tag updates (`sha-<commit>`) caused non-fast-forward push rejections.
   * **Resolution:** Standardized a rebase-first GitOps workflow (`git pull --rebase`) to keep automated CI image tags synchronized with declarative cluster manifests.

---

## 📂 Repository Structure

```text
├── terraform/environments/prod/   # EKS Cluster, IRSA, EBS CSI & Karpenter IaC
└── k8s/
    ├── root-app.yaml              # ArgoCD App-of-Apps bootstrap manifest
    ├── apps/                      # Application Deployments, Services, HPA & PVCs
    ├── networking/                # AWS ALB Ingress rules
    ├── observability/             # Prometheus & Grafana stack configurations
    └── security/                  # Cluster security & policy manifests
```

---

## 🚀 Quick Deployment Workflow

```bash
# 1. Provision EKS Cluster & Add-ons
cd terraform/environments/prod
terraform init && terraform apply -auto-approve

# 2. Bootstrap GitOps Control Plane
kubectl create namespace prod
kubectl apply -f k8s/root-app.yaml
```

---

## 👨‍💻 Author
**Salman Vohra** — DevOps & Cloud Infrastructure Engineer  
* [GitHub](https://github.com/salmanvohra-dev)
