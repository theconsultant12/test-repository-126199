provider "google" {
  project = "olusola-fowosire-play2-7da0" # Replace with your GCP Project ID
  region  = "us-central1"        # Baseline tier-friendly region
}

# ==========================================================================
# RESOURCE 1: Google Cloud Functions v2 (Serverless Compute)
# ==========================================================================
# Free Tier Baseline: 2 Million invocations per month free.

# Service account for Cloud Function execution
resource "google_service_account" "function_sa" {
  account_id   = "free-tier-function-sa"
  display_name = "Free Tier Cloud Function Service Account"
}

# Zip the source code locally
data "archive_file" "function_zip" {
  type        = "zip"
  output_path = "${path.module}/function_source.zip"

  source {
    content  = "def hello_world(request):\n    return 'Hello from GCP Free Tier!'"
    filename = "main.py"
  }

  source {
    content  = "functions-framework==3.*"
    filename = "requirements.txt"
  }
}

# Source bucket to hold the function package
resource "google_storage_bucket" "source_bucket" {
  name                        = "sola-source-bucket-${random_id.bucket_suffix.hex}"
  location                    = "us-central1"
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Upload zipped source code to the bucket
resource "google_storage_bucket_object" "source_zip" {
  name   = "source.zip"
  bucket = google_storage_bucket.source_bucket.name
  source = data.archive_file.function_zip.output_path
}

# Cloud Function v2 deployment
resource "google_cloudfunctions2_function" "free_function" {
  name        = "free-tier-serverless-function"
  location    = "us-central1"
  description = "Free serverless cloud function v2"

  build_config {
    runtime     = "python311"
    entry_point = "hello_world"
    
    # CRITICAL FIX: Wrap storage_source inside a source block
    source {
      storage_source {
        bucket = google_storage_bucket.source_bucket.name
        object = google_storage_bucket_object.source_zip.name
      }
    }
  }

  service_config {
    max_instance_count    = 1 
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.function_sa.email
  }
}




# ==========================================================================
# RESOURCE 3: Google Cloud Pub/Sub (Message Queue / Event Bus)
# ==========================================================================
# Free Tier Baseline: 10 GB of data transfer volume per month.

# Equivalent to an SQS Queue concept
resource "google_pubsub_topic" "free_topic" {
  name = "free-tier-serverless-queue-topic"
}

# Creates a subscription mechanism to process messages
resource "google_pubsub_subscription" "free_subscription" {
  name  = "free-tier-serverless-queue-sub"
  topic = google_pubsub_topic.free_topic.name

  # Message expiration parameters
  message_retention_duration = "345600s" # 4 days
  retain_acked_messages      = false
  ack_deadline_seconds       = 10
}


# ==========================================================================
# OUTPUTS
# ==========================================================================
output "cloud_function_uri" {
  value       = google_cloudfunctions2_function.free_function.service_config[0].uri
  description = "The target URL invocation endpoint of the Cloud Function."
}



output "pubsub_topic_id" {
  value       = google_pubsub_topic.free_topic.id
  description = "The unique resource identifier for your Pub/Sub queue pipeline."
}
