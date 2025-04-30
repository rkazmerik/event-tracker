locals {
  project_name = "event-tracking-pipeline"
  common_tags = {
    Project     = local.project_name
    Environment = var.environment
  }
}