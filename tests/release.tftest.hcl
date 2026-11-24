mock_provider "google" {}

variables {
  delivery_project_id = "portfolio-delivery"
  service_name        = "release-demo"
  publisher_account   = "image-publisher@portfolio-delivery.iam.gserviceaccount.com"
  environments = {
    staging = {
      project_id         = "portfolio-staging"
      execution_account  = "staging-exec@portfolio-delivery.iam.gserviceaccount.com"
      image_pull_account = "service-123456789012@serverless-robot-prod.iam.gserviceaccount.com"
    }
    production = {
      project_id         = "portfolio-production"
      execution_account  = "production-exec@portfolio-delivery.iam.gserviceaccount.com"
      image_pull_account = "service-123456789013@serverless-robot-prod.iam.gserviceaccount.com"
    }
  }
}

run "enforce_release_controls" {
  command = plan

  assert {
    condition     = google_artifact_registry_repository.images.docker_config[0].immutable_tags
    error_message = "Image tags must be immutable."
  }

  assert {
    condition     = !google_clouddeploy_target.environment["staging"].require_approval && google_clouddeploy_target.environment["production"].require_approval
    error_message = "Production promotion must require approval."
  }

  assert {
    condition     = [for stage in google_clouddeploy_delivery_pipeline.release.serial_pipeline[0].stages : stage.target_id] == ["release-demo-staging", "release-demo-production"]
    error_message = "The delivery pipeline must promote staging before production."
  }

  assert {
    condition     = google_artifact_registry_repository_iam_member.publisher.role == "roles/artifactregistry.writer" && alltrue([for binding in google_artifact_registry_repository_iam_member.pull : binding.role == "roles/artifactregistry.reader"])
    error_message = "Workload service agents must receive read-only repository access."
  }
}

run "reject_shared_workload_project" {
  command = plan

  variables {
    environments = {
      staging = {
        project_id         = "portfolio-shared"
        execution_account  = "staging-exec@portfolio-delivery.iam.gserviceaccount.com"
        image_pull_account = "service-123456789012@serverless-robot-prod.iam.gserviceaccount.com"
      }
      production = {
        project_id         = "portfolio-shared"
        execution_account  = "production-exec@portfolio-delivery.iam.gserviceaccount.com"
        image_pull_account = "service-123456789013@serverless-robot-prod.iam.gserviceaccount.com"
      }
    }
  }

  expect_failures = [var.environments]
}
