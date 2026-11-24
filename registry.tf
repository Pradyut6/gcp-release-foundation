# Derived from the Artifact Registry delivery pattern in Google's Enterprise
# Application blueprint. This project adds immutable tags and scoped accounts.
resource "google_artifact_registry_repository" "images" {
  project       = var.delivery_project_id
  repository_id = var.service_name
  location      = var.region
  format        = "DOCKER"
  description   = "Immutable container images for ${var.service_name}"

  docker_config {
    immutable_tags = true
  }
}

resource "google_artifact_registry_repository_iam_member" "publisher" {
  project    = var.delivery_project_id
  location   = var.region
  repository = google_artifact_registry_repository.images.repository_id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.publisher_account}"
}

resource "google_artifact_registry_repository_iam_member" "pull" {
  for_each = toset([
    var.environments.staging.image_pull_account,
    var.environments.production.image_pull_account,
  ])

  project    = var.delivery_project_id
  location   = var.region
  repository = google_artifact_registry_repository.images.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${each.value}"
}
