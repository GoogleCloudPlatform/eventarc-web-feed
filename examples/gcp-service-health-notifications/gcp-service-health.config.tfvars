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

# The Google Cloud region to deploy resources into
region = "us-central1"

# Boolean to control creation of Firestore Database as only one App Engine application can exist per project. Set to false if you're already setup Firestore in this project.
create_firestore = true

# List of secret configuration objects
# The `secrets` list(string) variable should ideally be set using the TF_VAR_ syntax to avoid committing it to version control
# https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#private_cp
secrets = [{
  name  = "slack-webhooks-urls"
  value = "" # Must provide a json encoded struct matching -> {"webhooks": [LIST_OF_SLACK_WEBHOOK_URLS]}
}]

# List of subscriber configuration objects
subscribers = [{
  name = "gcp-health-slack-publisher", # NOTE: when enabling slack-publisher subscriber, secrets variable MUST provide a secret with a name of slack-webhook-urls whose value is a json encoded object with a root attribute of "webhooks" whose value is a list of valid Slack webhooks
  secrets = [
    "slack-webhook-urls"
  ]
}]

# List of feed configuration objects
feeds = [{
  url      = "https://status.cloud.google.com/en/feed.atom",
  type     = "ATOM",
  schedule = "*/5 * * * *",
  name     = "gcp-generic"
  subscribers = [
    "gcp-health-slack-publisher",
  ]
  },
]