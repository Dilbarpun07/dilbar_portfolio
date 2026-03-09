# Portfolio – CI/CD Deployment with AWS & Terraform

This project demonstrates a **production-ready CI/CD pipeline** used to deploy a static portfolio website to **AWS S3** using **Terraform and GitHub Actions**.

The repository showcases modern **Infrastructure as Code (IaC)** practices and automated cloud deployment workflows.

---

## Project Overview

The goal of this project is to build and deploy a **static portfolio website** using automated cloud infrastructure and CI/CD best practices.

The pipeline automatically:

* Provisions infrastructure using **Terraform**
* Deploys the website to **AWS S3**
* Uses **GitHub Actions** for automated build and deployment
* Manages AWS authentication securely using **GitHub Secrets**

This setup demonstrates how modern DevOps workflows can be used to deliver reliable cloud infrastructure and deployments.

---

## Architecture

Developer Push → GitHub Repository → GitHub Actions CI/CD Pipeline → Terraform → AWS S3 → Live Website

---

## Technologies Used

* **AWS S3** – Static website hosting
* **Terraform** – Infrastructure as Code (IaC)
* **GitHub Actions** – CI/CD pipeline automation
* **AWS IAM** – Secure authentication and permissions
* **AWS CLI** – Deployment and management
* **HTML / CSS** – Portfolio website
* **GitHub Secrets** – Secure credential management

---

## CI/CD Workflow

The automated workflow performs the following steps:

1. Code is pushed to the repository
2. GitHub Actions pipeline is triggered
3. Terraform initializes and validates infrastructure
4. Terraform provisions or updates AWS resources
5. Website files are deployed to the S3 bucket
6. Changes become live automatically

```
           ┌───────────────────┐
           │   S3 State Bucket │
           │ dilbarpun-tf-state│
           │                   │
           │ terraform.tfstate │
           └─────────▲─────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
   Developer Laptop        GitHub Actions
   terraform apply         terraform plan
        │                         │
        └────────────┬────────────┘
                     │
                Reads SAME state
```

---

## The Final Architecture of Your Project

```
Developer
   │
   │ push code
   ▼
GitHub Repository
   │
   ▼
GitHub Actions CI/CD
   │
   │ terraform init
   │
   ▼
Terraform Backend (S3)
*bucket*-tf-state
   │
   ▼
Reads infrastructure state
   │
   ▼
Terraform Apply
   │
   ▼
AWS S3 Website Bucket
*bucket*
   │
   ▼
CloudFront CDN
   │
   ▼
Website Users
```
---

## Security

Sensitive credentials are stored securely using **GitHub Secrets**:

* AWS Access Key
* AWS Secret Access Key

This ensures credentials are never exposed in the repository.

---

## Project Structure

```
*whatevername*_portfolio/
│
├── terraform/          # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── website/            # Static portfolio files
│   ├── index.html
│   └── style.css
│
├── .github/workflows/  # CI/CD pipelines
│   └── deploy.yml
│
└── README.md
```

---

## Deployment

To deploy manually:

```bash
terraform init
terraform plan
terraform apply
```

The CI/CD pipeline will automatically deploy when changes are pushed to the repository.

---

## Live Website

Portfolio website:

```
https://dilbarportfolio.it.com
```

---

## Author

**Dilbar Pun**

Cloud Support Engineer
Azure | AWS | DevOps | API Integrations

GitHub:
https://github.com/dilbarpun07

---

## Purpose of This Project

This project was built to demonstrate skills in:

* Cloud infrastructure automation
* CI/CD pipeline design
* Infrastructure as Code (Terraform)
* AWS cloud deployment
* DevOps best practices

---
