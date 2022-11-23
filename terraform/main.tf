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

terraform {
  backend "gcs" {
    prefix = "terraform/state/gcp-health-notifer"
  }
}

provider "google" {

  region                      = var.region
  project                     = local.backend_config["project"]
  impersonate_service_account = local.backend_config["serviceAccount"]
}

provider "google-beta" {

  region                      = var.region
  project                     = local.backend_config["project"]
  impersonate_service_account = local.backend_config["serviceAccount"]
}