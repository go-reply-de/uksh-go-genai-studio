resource "google_clouddeploy_target" "primary" {
  project  = data.google_project.project.id
  location = var.gcp_region
  name     = "${var.application}-${var.environment}-clouddeploy-target"

  gke {
    cluster = var.cluster_id
  }

  # Configuration for the service account Cloud Deploy will use for RENDER, DEPLOY, etc.
  execution_configs {
    usages = [
      "RENDER",
      "DEPLOY"
    ]
    service_account = google_service_account.cloudbuild_service_account.email
  }

  require_approval = false
}

resource "google_clouddeploy_delivery_pipeline" "primary" {
  project  = data.google_project.project.id
  location = var.gcp_region
  name     = "${var.application}-${var.environment}-delivery-pipeline"

  serial_pipeline {
    stages {
      target_id = google_clouddeploy_target.primary.target_id
    }
  }

  depends_on = [
    google_clouddeploy_target.primary
  ]
}