# GCP Release Foundation

A Terraform project for promoting the same container image from staging to production with Cloud Deploy. Artifact Registry stores immutable tags. Separate execution accounts deploy to separate Cloud Run projects, and production waits for an explicit approval.

~~~mermaid
flowchart LR
    CI[CI publisher] --> Registry[Artifact Registry]
    Registry --> Staging[Cloud Run staging]
    Staging --> Approval[Production approval]
    Approval --> Production[Cloud Run production]
~~~

## What Terraform manages

| Resource | Control |
| --- | --- |
| Artifact Registry repository | Immutable tags and repository-scoped access |
| Cloud Deploy targets | Separate workload projects and execution identities |
| Delivery pipeline | Ordered staging and production stages with a production approval gate |
| GitHub Actions | Formatting, read-only provider initialization, validation, and mocked plan tests |

The project uses existing Google Cloud projects and service accounts. It does not grant broad project roles or create account keys. The example Cloud Run services use internal ingress and dedicated runtime accounts.

## Verify locally

~~~sh
terraform init -backend=false -input=false -lockfile=readonly
terraform fmt -check -recursive
terraform validate
terraform test
~~~

The test runs against a mocked provider, so it needs no Google credentials. The dependency lockfile covers Linux and Windows AMD64.

## Configure a lab

1. Choose a delivery project and separate staging and production workload projects. Enable Artifact Registry, Cloud Deploy and Cloud Build in the delivery project, and Cloud Run in each workload project. Initialize the Cloud Run service agents in both workload projects before applying.
2. Supply an existing publisher account in the delivery project, distinct staging and production execution accounts, and the Cloud Run service agent email for each workload project. Copy `terraform.tfvars.example` to `terraform.tfvars` and replace the example values.
3. Grant each execution account the Cloud Deploy job runner access it needs in the delivery project and Cloud Run Developer access in its own target project. Grant the account Service Account User on only its target runtime account. Also allow the Cloud Deploy service agent to use the configured execution accounts, and grant the release creator and production approver the corresponding Cloud Deploy permissions. The release creator also needs permission to act as the render account, and the promoter needs permission to act as the production deployment account. For exact identity requirements and artifact storage access, follow the [Cloud Deploy service-account guide](https://cloud.google.com/deploy/docs/cloud-deploy-service-account).
4. Authenticate Terraform using Application Default Credentials. Save your inputs in the ignored `terraform.tfvars`. Run `terraform plan -out=release.tfplan`, review the target projects and IAM changes, then run `terraform apply release.tfplan`.

The default backend is local for a disposable lab. Configure a restricted, versioned GCS backend before sharing state. Registry storage, build executions, and deployed workloads may incur charges.

## Promote one image digest

Replace the placeholder runtime accounts in `example-release/service-*.yaml`. Push an application image that listens on port 8080. Set `IMAGE_DIGEST` to its full Artifact Registry image reference ending in `@sha256:...`. Set `DELIVERY_PROJECT`, `REGION`, and `PIPELINE` to the Terraform inputs, and choose a unique `RELEASE` name.

~~~sh
gcloud deploy releases create "$RELEASE" \
  --project="$DELIVERY_PROJECT" --region="$REGION" \
  --delivery-pipeline="$PIPELINE" --source=example-release \
  --images="app=$IMAGE_DIGEST"

gcloud deploy releases promote --release="$RELEASE" \
  --project="$DELIVERY_PROJECT" --region="$REGION" \
  --delivery-pipeline="$PIPELINE" --to-target="${PIPELINE}-production"
~~~

Validate the staging service from an approved internal caller before promoting. An authorized approver reviews the production rollout in Cloud Deploy before it proceeds. [Cloud Deploy approvals](https://cloud.google.com/deploy/docs/promote-release#require_approval)

## Operations

- **Render fails**. Check that the release source contains the staging and production Skaffold profiles and the image mapping uses the manifest placeholder `app`.
- **Deploy fails**. Check the rollout’s Cloud Build logs, the target execution account’s Cloud Run permissions, and its access to use the target runtime account.
- **Image pull is denied**. Verify that the repository reader binding points to the target workload project’s Cloud Run service agent. [Deploy images from another project](https://cloud.google.com/run/docs/deploying#other-projects)
- **Roll back**. Use Cloud Deploy to roll back the affected target to a known-good release. Check approval status and validate the restored revision before closing the incident.
- **Teardown**. Delete lab Cloud Run services separately, then review `terraform plan -destroy` and destroy the delivery resources only after retaining any required release artifacts.

## Attribution

Adapted from the delivery pattern in Google’s [Enterprise Application blueprint](https://github.com/GoogleCloudPlatform/terraform-google-enterprise-application). This implementation uses Cloud Run targets and adds an immutable registry, repository-scoped IAM, and a production approval gate. The [Apache 2.0 license](LICENSE) is included.
