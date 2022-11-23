# Copyright 2022 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Create pubsub topic to queue jobs for feed-reader function
resource "google_pubsub_topic" "feed_reader" {

  name = "feed-reader"

  message_storage_policy {
    allowed_persistence_regions = [
      var.region,
    ]
  }
}

# Package the feed_reader
data "archive_file" "feed_reader" {

  type        = "zip"
  source_dir  = "${local.root_dir}/src/feed-reader"
  output_path = "/tmp/feed-reader.zip"
}

# Upload to GCS
resource "google_storage_bucket_object" "feed_reader" {

  # Append file MD5 to force object to be recreated
  name   = "functions/feed-reader/versions/${data.archive_file.feed_reader.output_md5}.zip"
  bucket = google_storage_bucket.gcf_artifacts.name
  source = data.archive_file.feed_reader.output_path
}

resource "google_cloudfunctions2_function" "feed_reader" {

  name        = "feed-reader"
  location    = var.region
  description = ""

  build_config {
    runtime     = "go116"
    entry_point = "Handler" # Set the entry point 
    source {
      storage_source {
        bucket = google_storage_bucket_object.feed_reader.bucket
        object = google_storage_bucket_object.feed_reader.name
      }
    }
  }

  service_config {
    available_memory               = "128Mi"
    timeout_seconds                = 60
    max_instance_count             = 100
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.feed_reader.email

    environment_variables = {
      FIRESTORE_PROJECT_ID = local.project_id
    }
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic          = google_pubsub_topic.feed_reader.id
    service_account_email = split(":", google_project_iam_member.event_arc_sub_sa["roles/run.invoker"].member)[1]
    retry_policy          = "RETRY_POLICY_RETRY"
  }
}

resource "google_cloud_scheduler_job" "feed_reader" {
  for_each = local.feeds

  name        = "${each.key}-feed-reader"
  description = "Invoke the Feed Reader function for the ${upper(each.key)} web feed"
  schedule    = each.value.schedule

  pubsub_target {
    topic_name = google_pubsub_topic.feed_reader.id
    data = base64encode(jsonencode(merge(each.value, {
      "topicId" : google_pubsub_topic.feeds[each.key].name
    })))
  }
}