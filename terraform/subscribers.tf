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

resource "google_pubsub_topic" "feeds" {
  for_each = local.feeds

  name   = "${each.key}-feed-topic"
  labels = null
  message_storage_policy {
    allowed_persistence_regions = [
      var.region,
    ]
  }
}

# Package the subscriber functions
data "archive_file" "subscribers" {
  for_each = local.subscriber_configs

  type        = "zip"
  source_dir  = each.value.src
  output_path = "/tmp/${each.key}.zip"

  lifecycle {

    precondition {
      condition     = contains(local.deployable_subscribers, each.key)
      error_message = "${each.key} is not a subscriber located in ${local.subscribers_dir}!"
    }

    precondition {
      condition     = fileexists("${each.value.src}/main.py")
      error_message = "${each.value.src} does not have a main.py entrypoint!"
    }
  }
}

# Upload to GCS
resource "google_storage_bucket_object" "subscribers" {
  for_each = data.archive_file.subscribers

  # Append file MD5 to force bucket to be recreated
  name   = "functions/subscribers/${each.key}/versions/${each.value.output_md5}.zip"
  bucket = google_storage_bucket.gcf_artifacts.name
  source = each.value.output_path
}

# Deploy to GCF v2
resource "google_cloudfunctions2_function" "subscribers" {
  for_each = google_storage_bucket_object.subscribers

  name        = each.key
  location    = var.region
  description = ""

  build_config {
    runtime     = "python310"
    entry_point = "handler" # Set the entry point 
    source {
      storage_source {
        bucket = each.value.bucket
        object = each.value.name
      }
    }
  }

  service_config {
    available_memory               = local.subscriber_configs[each.key].available_memory
    timeout_seconds                = local.subscriber_configs[each.key].timeout_seconds
    max_instance_count             = local.subscriber_configs[each.key].max_instance_count
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.feed_subscriber.email

    environment_variables = merge(local.subscriber_configs[each.key].environment_variables, {
      FIRESTORE_PROJECT_ID = local.project_id
    })

    dynamic "secret_environment_variables" {
      for_each = local.subscriber_configs[each.key].secrets
      iterator = secret_name
      content {
        key        = upper(replace(google_secret_manager_secret.this[secret_name.value].secret_id, "-", "_"))
        project_id = local.project_id
        secret     = google_secret_manager_secret.this[secret_name.value].secret_id
        version    = google_secret_manager_secret_version.this[secret_name.value].version
      }
    }
  }

  lifecycle {

    precondition {
      condition     = alltrue([for s in local.subscriber_configs[each.key].secrets : contains(keys(google_secret_manager_secret_version.this), s)])
      error_message = "The ${each.key} subscriber references a secret that does not exist!"
    }
  }
}

resource "google_eventarc_trigger" "subscribers" {
  # local.subscriber_triggers is set of strings formatted as `${feed.name}:${subscriber_function}`
  for_each = local.subscriber_triggers

  # name            = "${split(":", each.key)[0]}-to-${split(":", each.key)[1]}"
  name            = replace(each.key, ":", "-to-")
  location        = var.region
  service_account = split(":", values(google_project_iam_member.event_arc_sub_sa)[0].member)[1]

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }

  # Since Cloud Functions v2 is powered by Cloud Run, we can target/invoke the GCFs as Cloud Run services
  destination {
    cloud_run_service {
      region  = google_cloudfunctions2_function.subscribers["${split(":", each.key)[1]}"].location
      service = google_cloudfunctions2_function.subscribers["${split(":", each.key)[1]}"].name
    }
  }

  # 
  transport {
    pubsub {
      topic = google_pubsub_topic.feeds["${split(":", each.key)[0]}"].id
    }
  }

  lifecycle {

    precondition {
      condition     = contains(keys(google_cloudfunctions2_function.subscribers), split(":", each.key)[1])
      error_message = "The ${split(":", each.key)[0]} feed references the subscriber ${split(":", each.key)[1]} which does not exist!"
    }
  }
}