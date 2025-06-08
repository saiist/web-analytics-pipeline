# Analytics Pipeline Terraform Configuration
# This recreates the GCP resources for the web analytics system

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "your-analytics-project"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "location" {
  description = "BigQuery Location"
  type        = string
  default     = "US"
}

variable "deletion_protection" {
  description = "Enable deletion protection for BigQuery resources"
  type        = bool
  default     = true
}

variable "credentials_file" {
  description = "Path to the Google Cloud service account key file (optional)"
  type        = string
  default     = null
}

# Provider configuration
# 認証方法（以下のいずれかを選択）:
# 1. Application Default Credentials (推奨): gcloud auth application-default login
# 2. サービスアカウントキー: credentials = "path/to/service-account-key.json"
# 3. 環境変数: GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account-key.json"
provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.credentials_file != null ? var.credentials_file : null
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "bigquery.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "pubsub.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_on_destroy = false
}

# BigQuery Dataset
resource "google_bigquery_dataset" "analytics" {
  dataset_id                 = "analytics"
  friendly_name              = "Analytics Dataset"
  description                = "Dataset for web analytics events"
  location                   = var.location
  delete_contents_on_destroy = !var.deletion_protection

  depends_on = [google_project_service.required_apis]
}

# BigQuery Table
resource "google_bigquery_table" "events" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "events"

  schema = jsonencode([
    {
      name = "timestamp"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name = "event_type"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "user_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "session_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "url"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "properties"
      type = "JSON"
      mode = "NULLABLE"
    }
  ])

  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }

  clustering = ["event_type"]
  
  deletion_protection = var.deletion_protection
}

# Cloud Storage bucket for function source code
resource "google_storage_bucket" "function_source" {
  name          = "${var.project_id}-function-source"
  location      = var.region
  force_destroy = true

  depends_on = [google_project_service.required_apis]
}

# Cloud Storage bucket for web hosting
resource "google_storage_bucket" "web_hosting" {
  name          = "${var.project_id}-web"
  location      = var.region
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }

  depends_on = [google_project_service.required_apis]
}

# Make web hosting bucket publicly readable
resource "google_storage_bucket_iam_member" "public_access" {
  bucket = google_storage_bucket.web_hosting.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Archive Cloud Function source code
data "archive_file" "function_source" {
  type        = "zip"
  output_path = "${path.module}/function-source.zip"
  source_dir  = "${path.module}/../function"
}

# Upload function source to bucket
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_source.output_path

  depends_on = [data.archive_file.function_source]
}

# Cloud Function
resource "google_cloudfunctions2_function" "track_event" {
  name        = "track-event"
  location    = var.region
  description = "Function to track analytics events"

  build_config {
    runtime     = "nodejs20"
    entry_point = "trackEvent"
    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count = 100
    available_memory   = "256M"
    timeout_seconds    = 60
    ingress_settings   = "ALLOW_ALL"
  }

  depends_on = [
    google_project_service.required_apis,
    google_storage_bucket_object.function_source
  ]
}

# Make Cloud Function publicly accessible
resource "google_cloud_run_service_iam_member" "function_invoker" {
  location = google_cloudfunctions2_function.track_event.location
  service  = google_cloudfunctions2_function.track_event.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Process HTML template with dynamic values
locals {
  website_content = templatefile("${path.module}/index.html.tpl", {
    function_url = google_cloudfunctions2_function.track_event.service_config[0].uri
    project_id   = var.project_id
  })
}

# Upload website to hosting bucket
resource "google_storage_bucket_object" "website" {
  name         = "index.html"
  bucket       = google_storage_bucket.web_hosting.name
  content      = local.website_content
  content_type = "text/html"
}

# Outputs
output "function_url" {
  description = "Cloud Function URL"
  value       = google_cloudfunctions2_function.track_event.service_config[0].uri
}

output "website_url" {
  description = "Website URL"
  value       = "https://storage.googleapis.com/${google_storage_bucket.web_hosting.name}/index.html"
}

output "bigquery_dataset" {
  description = "BigQuery Dataset"
  value       = "${var.project_id}.${google_bigquery_dataset.analytics.dataset_id}"
}

output "bigquery_table" {
  description = "BigQuery Events Table"
  value       = "${var.project_id}.${google_bigquery_dataset.analytics.dataset_id}.${google_bigquery_table.events.table_id}"
}