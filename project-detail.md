# Project detail: Dilbar Portfolio (Terraform + AWS + GitHub Actions)

This repository deploys a **static portfolio website** to **AWS S3** using **Terraform (IaC)**, automated by **GitHub Actions**.

---

## What this project does (high-level)

- **Hosts a static website** (HTML/CSS/PDF) from `website/`.
- **Provisions/updates AWS infrastructure** via Terraform.
- **Deploys website files** by uploading everything in `website/` to the S3 bucket as S3 objects.
- **Runs CI/CD on push to `main`** using GitHub Actions:
  - `terraform init` → `terraform validate` → `terraform plan` → `terraform apply`
  - then **invalidates CloudFront cache** so updates appear immediately.

---

## Repository structure

```text
dilbar_portfolio/
├── .github/
│   └── workflows/
│       └── deploy.yml            # CI/CD workflow (Terraform + CloudFront invalidation)
├── website/
│   ├── index.html                # Portfolio entry page
│   ├── style.css                 # Stylesheet referenced by index.html
│   └── resume.pdf                # Static asset linked from the site
├── .gitignore                    # Terraform + state ignore rules
├── .terraform.lock.hcl           # Provider lockfile (created by terraform init)
├── main.tf                       # Terraform backend + AWS resources
├── variables.tf                  # Terraform variables (bucket, region, mime-types)
├── outputs.tf                    # Currently empty (no Terraform outputs defined)
├── README.md                     # Short overview + architecture diagram
└── project-detail.md             # (this file) deeper documentation
```

---

## How everything is connected (end-to-end flow)

### 1) Source code + static assets

- **Website content lives in** `website/`.
- `website/index.html` loads `website/style.css` using a relative link:
  - `<link rel="stylesheet" href="style.css">`
- `website/index.html` links to the hosted `resume.pdf` (served from the same domain once deployed).

### 2) Terraform defines infrastructure + deployment

Terraform configuration is at the repo root.

#### Backend state (remote)

`main.tf` configures an **S3 backend**:

- **S3 bucket**: `dilbarpun-tf-state`
- **State key**: `dilbar-portfolio/terraform.tfstate`
- **Region**: `ap-southeast-2`
- **Locking**: `use_lockfile = true` (Terraform uses a lock file for state locking in supported backends)

This means:

- `terraform apply` from your laptop and from GitHub Actions will both read/write the **same** remote state.
- You should **not** commit any local `.tfstate` files (and `.gitignore` already ignores them).

#### Provider and region

`provider "aws"` uses:

- `region = var.region` (defaults to `ap-southeast-2` in `variables.tf`)

#### AWS resources

`main.tf` manages:

- **S3 website bucket**:
  - `aws_s3_bucket.portfolio` uses `var.bucket_name` (default `dilbarpun-portfolio`)

- **S3 objects for every file in `website/`**:
  - `aws_s3_object.website_files` uses:
    - `for_each = fileset("${path.module}/website", "**")` to include **all files recursively**
    - `key = each.value` to preserve folder structure under `website/`
    - `source = "${path.module}/website/${each.value}"`
    - `etag = filemd5(...)` to force updates when file contents change
    - `content_type = lookup(var.mime_types, file_extension, "application/octet-stream")`

That `for_each + fileset()` pattern is the core “deployment mechanism”: **any file you add/update in `website/` becomes an S3 object on next `terraform apply`.**

#### MIME types (Content-Type)

`variables.tf` defines a `mime_types` map, so the browser receives correct content types (e.g. `.css` as `text/css`).

Current mapping includes:

- `.html`, `.css`, `.js`, `.png`, `.jpg`, `.pdf`

If you add new asset types (like `.svg`, `.webp`, `.json`, `.woff2`), update `mime_types` accordingly or they’ll default to `application/octet-stream`.

### 3) CI/CD runs Terraform and refreshes CDN

GitHub Actions workflow: `.github/workflows/deploy.yml`

Trigger:

- **On push** to **`main`**

Main steps (what each command does):

- **Checkout code**: downloads the repo into the workflow runner.
- **Setup Terraform**: installs Terraform on the runner.
- **Configure AWS Credentials**:
  - uses repo/environment secrets:
    - `AWS_ACCESS_KEY_ID`
    - `AWS_SECRET_ACCESS_KEY`
  - sets AWS region to `ap-southeast-2`
- **Terraform Init** (`terraform init`):
  - downloads providers (AWS)
  - configures the S3 backend so Terraform can access remote state
- **Terraform Validate** (`terraform validate`):
  - checks Terraform syntax and internal consistency
- **Terraform Plan** (`terraform plan -input=false`):
  - calculates proposed infrastructure + S3 object changes
  - `-input=false` prevents interactive prompts
- **Terraform Apply** (`terraform apply -auto-approve -input=false`):
  - applies the plan automatically (no manual approval)
  - uploads changes from `website/` to S3 through `aws_s3_object.website_files`
- **Invalidate CloudFront Cache**:
  - runs: `aws cloudfront create-invalidation --distribution-id E2BL6G01SA9R7D --paths "/*"`
  - forces CloudFront to fetch the latest objects from the origin (S3)

Important note:

- This repo’s Terraform currently defines **S3 bucket + objects**, but does **not** define the CloudFront distribution itself in `main.tf`.
  - The workflow assumes a CloudFront distribution already exists with ID `E2BL6G01SA9R7D`.
  - If you replace/recreate CloudFront, update the distribution id in `.github/workflows/deploy.yml`.

---

## Commands you’ll run (local development / operations)

This repo has no Node build step; the “build” is simply **editing files in `website/`**.

### Terraform (run from repo root)

- **Format Terraform**:

```bash
terraform fmt -recursive
```

- **Initialize Terraform** (first time, or after backend/provider changes):

```bash
terraform init
```

- **Validate config**:

```bash
terraform validate
```

- **Preview changes**:

```bash
terraform plan
```

- **Apply changes (deploy infrastructure + website)**:

```bash
terraform apply
```

- **Destroy everything Terraform manages** (dangerous; removes the managed resources):

```bash
terraform destroy
```

### AWS CLI (optional / troubleshooting)

- **Invalidate CloudFront** (same as CI step):

```bash
aws cloudfront create-invalidation --distribution-id E2BL6G01SA9R7D --paths "/*"
```

- **List objects in the portfolio bucket**:

```bash
aws s3 ls s3://dilbarpun-portfolio --recursive
```

---

## Common tasks and “what to edit”

### Update website content

- Edit `website/index.html` and/or `website/style.css`
- Add new assets into `website/` (images, PDFs, etc.)
- Deploy:
  - push to `main` (CI/CD applies automatically), or run `terraform apply` locally.

### Add new file types (fix browser Content-Type)

- Update `variables.tf` → `variable "mime_types"` map
- Deploy with `terraform apply`

### Change bucket name or region

- `variables.tf`:
  - `bucket_name` (default: `dilbarpun-portfolio`)
  - `region` (default: `ap-southeast-2`)

Changing these after initial deployment can cause resource replacement. Always run `terraform plan` first to understand impact.

### Update Terraform remote state backend

- `main.tf` → `terraform { backend "s3" { ... } }`

If you change backend settings, run:

```bash
terraform init -reconfigure
```

---

## CI/CD requirements (GitHub)

### Secrets

The workflow expects these GitHub secrets to be present (in repo secrets or environment `aws` as configured in the workflow):

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

The IAM user/role behind these credentials should have permissions for:

- S3 bucket/object management for the portfolio bucket
- Access to the Terraform backend bucket/key (`dilbarpun-tf-state` + its object)
- CloudFront invalidation permissions for distribution `E2BL6G01SA9R7D`

### Environment

Workflow sets:

- `environment: aws`

If you’re using GitHub Environments, ensure the `aws` environment exists and contains the required secrets (or move secrets to repo-level).

---

## Known gaps / future improvements (optional)

- **CloudFront not managed in Terraform**: consider adding CloudFront + OAC/OAI + S3 policy, then output the distribution id and reference it in CI.
- **S3 website hosting settings**: if you want S3 static website hosting directly (instead of CloudFront), you’d add bucket website configuration + public access strategy. (With CloudFront, you typically keep S3 private and use OAC.)
- **`outputs.tf` is empty**: you can add outputs like bucket name, website URL, CloudFront distribution id, etc.

