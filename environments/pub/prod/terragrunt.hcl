terraform {
  source = "../../..//terraform"
}

include {
  merge_strategy = "deep"
  path           = find_in_parent_folders("root.hcl")
}

inputs = {

  node_env        = "production"
  domain          = "pub.genai-portal.uksh.de"
  sign_in_domains = ["gcp.uksh.de"]

  git_push_config = {
    trigger_type = "tag"
    value        = "v*"
  }

  user_group_mail = ["goreply-admins@uksh.de", "goreply-editors@uksh.de"]
  
  # Cloud Armor configuration
  enable_cloud_armor = true
}
