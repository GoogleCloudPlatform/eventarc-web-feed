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

locals {
  root_dir       = dirname(abspath(path.module))
  backend_config = yamldecode(file("${local.root_dir}/.config/.backend.lock.yml"))

  formatted_region = var.region == "us-central1" || var.region == "europe-west1" ? substr(var.region, 0, length(var.region) - 1) : var.region
  project_id       = data.google_project.this.project_id
  access_token     = data.google_client_config.current.access_token

  feed_reader_iam_roles     = toset(["roles/editor"])
  feed_subscriber_iam_roles = toset(["roles/editor"])

  # Define and create cron jobs to schedule feed-reader invocation
  feeds = {
    for feed in var.feeds :
    feed.name => {
      "feed" : feed.url,
      "type" : "${lower(feed.type)}",
      "cachePath" : feed.name,
      "schedule" : feed.schedule
    }
  }

  # Get map of secret name => secret value
  secrets = {
    for secret in var.secrets :
    secret.name => secret.value
  }

  subscribers_dir = "${local.root_dir}/src/subscribers"

  # Get list of subscribers that exist in ./src/subscribers
  deployable_subscribers = toset([for dir in fileset(local.subscribers_dir, "**") : dirname(dir) if !startswith(dir, "_")])

  # Get flattened and unique list of subscribers that should be deployed for the web feeds
  subscribers = toset(flatten([for feed in var.feeds : feed.subscribers]))

  # Get flattened and unique list of subscribers that should be deployed for the web feeds
  subscriber_configs = {
    for s in var.subscribers :
    s.name => merge(s, {
      "src" : "${local.root_dir}/src/subscribers/${s.name}"
    })
  }

  # get list of cartesian product sets for every feed for feed.name -> feed.subscribers 
  feeds_subscribers_cartesian = [
    for feed in var.feeds :
    setproduct(toset([feed.name]), toset([for s in feed.subscribers : s]))
    if length(feed.subscribers) > 0
  ]

  # for each feed's cartesian product set:
  #   join feed.name to subscriber name with colon
  # flatten the list to get single global list of each eventarc trigger we need to create
  subscriber_triggers = toset(flatten([
    for feed in local.feeds_subscribers_cartesian : [
      for product in feed :
      join(":", product)
    ]
  ]))
}