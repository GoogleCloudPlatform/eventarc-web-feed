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

# Create Feed Reader IAM Service Account + add required permissions
resource "google_service_account" "feed_reader" {
  account_id   = "feed-reader-sa"
  display_name = "Service account for the Feed Reader Function"
}

resource "google_project_iam_member" "feed_reader" {
  for_each = local.feed_reader_iam_roles

  project = local.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.feed_reader.email}"
}

# Create Feed Subscriber IAM Service Account + add required permissions
resource "google_service_account" "feed_subscriber" {
  account_id   = "feed-subscriber-sa"
  display_name = "Service account for the Feed Subscriber Functions"
}

resource "google_project_iam_member" "feed_subscriber" {
  for_each = local.feed_subscriber_iam_roles

  project = local.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.feed_subscriber.email}"
}

# Ensure pubsub service identity exists
resource "google_project_service_identity" "pubsub" {
  provider = google-beta

  project = local.project_id
  service = "pubsub.googleapis.com"
}

# Grant pubsub service identity ability to impersonate service accounts
resource "google_project_iam_member" "pubsub_sa" {
  for_each = toset(["roles/iam.serviceAccountTokenCreator"])

  project = local.project_id
  role    = each.value
  member  = "serviceAccount:${google_project_service_identity.pubsub.email}"
}

# Create service account for pubsub to impersonate
resource "google_service_account" "event_arc_sub_sa" {
  account_id   = "eventarc-subscription-sa"
  display_name = "Service account for Eventarc triggers"
}

# Grant above SA ability to invoke Cloud Run service (Cloud Functions v2)
resource "google_project_iam_member" "event_arc_sub_sa" {
  for_each = toset(["roles/run.invoker"])

  project = local.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.event_arc_sub_sa.email}"
}