locals {
  # The length of application name, environment and gcp_project_id combined can at most be 46  characters long
  application = "genai-portal"

  team_name       = "goreply"
  repository      = "uksh-go-genai-studio"
  prefix          = "go-de"
  domain          = "example.com"
  sign_in_domains = []

  # Extract the variables we need for easy access
  gcp_region     = "europe-west3"

  # Due to the setup of the environments directory it will match the corresponding environment
  environment_full_path = path_relative_to_include() // e.g., "aw1/dev", "aw1/pub", "pub/dev", "pub/prod"
  path_parts            = split("/", local.environment_full_path)
  current_scope         = length(local.path_parts) == 2 ? local.path_parts[0] : "unknown_scope"
  current_env_type      = length(local.path_parts) == 2 ? local.path_parts[1] : "unknown_env_type"
  sanitized_environment_for_names = replace(local.environment_full_path, "/", "-") # e.g., "pub-dev"

  project_id_map = {
    "aw1" = {
      "dev" = "uksh-aw1-dev-genai-portal"  // Corresponds to environments/aw1/dev/
      "pub" = "uksh-aw1-prod-genai-portal" // Corresponds to environments/aw1/pub/
    },
    "pub" = {
      "dev"  = "uksh-pub-dev-genai-portal"  // Corresponds to environments/pub/dev/
      "prod" = "uksh-pub-prod-genai-portal" // Corresponds to environments/pub/prod/
    }
  }

  gcp_project_id = lookup(
    lookup(local.project_id_map, local.current_scope, {}),
    local.current_env_type,
    "ERROR-project-id-not-found-${local.current_scope}-${local.current_env_type}"
  )

  # Configmap variables
  application_name  = "GenAI Portal"
  application_email = "go.de.genai.studio@reply.de"
  application_date  = formatdate("MMMM DD, YYYY", timestamp())
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "gcs"

  config = {
    #######################################################################
    #  IMPORTANT NOTE:                                                    #
    #  We are making use of the structure of the environments directory.  #
    #  The foldername should match the actual environment.                #
    #######################################################################

    bucket   = "terraform-state-${local.current_env_type}-${local.application}-${local.gcp_project_id}"
    prefix   = "terraform.tfstate"
    project  = "${local.gcp_project_id}"
    location = "${local.gcp_region}"
  }
}

generate "terraform" {
  path      = "terraform.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "gcs" {}
  required_version = ">= 1.6.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

provider "google" {
  project = "${local.gcp_project_id}"
  region = "${local.gcp_region}"
  default_labels = {
    application         = "${local.application}"
    environment         = "${local.current_env_type}"
    team_name           = "${local.team_name}"
    repository          = "${local.repository}"
  }
}

EOF
}
#prevent_destroy = true

inputs = {
  gcp_project_id    = "${local.gcp_project_id}"
  gcp_region        = "${local.gcp_region}"
  prefix            = "${local.prefix}"
  environment       = "${local.current_env_type}"
  application       = "${local.application}"
  domain            = "${local.domain}"
  sign_in_domains   = "${local.sign_in_domains}"
  application_name  = "${local.application_name}"
  application_date  = "${local.application_date}"
  application_email = "${local.application_email}"
}
