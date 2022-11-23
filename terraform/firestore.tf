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

resource "google_app_engine_application" "firestore" {
  count = var.create_firestore ? 1 : 0

  location_id   = local.formatted_region
  database_type = "CLOUD_FIRESTORE"
}

resource "null_resource" "firestore_ttl" {
  for_each = local.feeds

  triggers = {
    cachePath = each.value.cachePath
  }

  provisioner "local-exec" {
    command = "gcloud --quiet beta firestore fields ttls update expireAt --collection-group=${each.value.cachePath} --enable-ttl --async --project=${local.project_id}"

    environment = {
      CLOUDSDK_AUTH_ACCESS_TOKEN = local.access_token
    }
  }

  depends_on = [google_app_engine_application.firestore]
}
