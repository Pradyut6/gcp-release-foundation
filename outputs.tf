output "image_repository" {
  description = "Artifact Registry repository prefix for Docker image references."
  value       = "${var.region}-docker.pkg.dev/${var.delivery_project_id}/${google_artifact_registry_repository.images.repository_id}"
}

output "pipeline_id" {
  description = "Cloud Deploy delivery pipeline resource ID."
  value       = google_clouddeploy_delivery_pipeline.release.id
}
