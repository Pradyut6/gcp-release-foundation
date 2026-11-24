variable "delivery_project_id" {
  type        = string
  description = "Existing project that owns Cloud Deploy and Artifact Registry."
}

variable "region" {
  type        = string
  description = "Region for the registry, pipeline, and Cloud Run deployment targets."
  default     = "us-central1"
}

variable "service_name" {
  type        = string
  description = "Prefix for the registry, pipeline and Cloud Deploy targets."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,28}[a-z0-9]$", var.service_name))
    error_message = "Use 3 to 30 lowercase letters, digits or hyphens, starting with a letter and ending with a letter or digit."
  }
}

variable "environments" {
  type = object({
    staging = object({
      project_id         = string
      execution_account  = string
      image_pull_account = string
    })
    production = object({
      project_id         = string
      execution_account  = string
      image_pull_account = string
    })
  })
  description = "Existing workload projects, Cloud Deploy execution account emails, and Cloud Run service agent emails."

  validation {
    condition = (
      var.environments.staging.project_id != var.environments.production.project_id &&
      var.environments.staging.execution_account != var.environments.production.execution_account &&
      alltrue([for env in [var.environments.staging, var.environments.production] :
        can(regex("^[a-z0-9-]+@[a-z0-9-]+\\.iam\\.gserviceaccount\\.com$", env.execution_account)) &&
        can(regex("^service-[0-9]+@serverless-robot-prod\\.iam\\.gserviceaccount\\.com$", env.image_pull_account))
      ])
    )
    error_message = "Use separate workload projects and execution accounts, and supply each project's Cloud Run service agent email."
  }
}

variable "publisher_account" {
  type        = string
  description = "Existing CI service account email that can push images to this repository."

  validation {
    condition     = can(regex("^[a-z0-9-]+@[a-z0-9-]+\\.iam\\.gserviceaccount\\.com$", var.publisher_account))
    error_message = "Supply the email of a dedicated user-managed service account."
  }
}
