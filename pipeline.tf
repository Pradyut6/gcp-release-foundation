locals {
  stages = ["staging", "production"]
}

resource "google_clouddeploy_target" "environment" {
  for_each = toset(local.stages)

  project          = var.delivery_project_id
  location         = var.region
  name             = "${var.service_name}-${each.key}"
  require_approval = each.key == "production"

  run {
    location = "projects/${var.environments[each.key].project_id}/locations/${var.region}"
  }

  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    service_account   = var.environments[each.key].execution_account
    execution_timeout = "1800s"
  }
}

resource "google_clouddeploy_delivery_pipeline" "release" {
  project     = var.delivery_project_id
  location    = var.region
  name        = var.service_name
  description = "Staged Cloud Run delivery with production approval"

  serial_pipeline {
    dynamic "stages" {
      for_each = local.stages
      content {
        target_id = google_clouddeploy_target.environment[stages.value].name
        profiles  = [stages.value]
      }
    }
  }
}
