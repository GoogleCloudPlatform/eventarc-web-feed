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

resource "google_secret_manager_secret" "this" {
  for_each = nonsensitive(toset(keys(local.secrets)))

  secret_id = each.key

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "this" {
  for_each = google_secret_manager_secret.this

  secret = each.value.id

  secret_data = local.secrets[each.key]
}

data "google_iam_policy" "secrets" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      "serviceAccount:${google_service_account.feed_subscriber.email}",
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "this" {
  for_each = google_secret_manager_secret_version.this

  project     = local.project_id
  secret_id   = google_secret_manager_secret.this[each.key].secret_id
  policy_data = data.google_iam_policy.secrets.policy_data
}