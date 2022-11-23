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

variable "region" {
  description = "The GCP region to deploy resources into [Default = us-central]"
  type        = string
  default     = "us-central1"
}

variable "secrets" {
  description = "Map of secret name to secret value to store in Secrets Manager"
  type = list(object({
    name  = string
    value = string
  }))
  default   = []
  sensitive = true

  validation {
    condition     = alltrue([for secret in var.secrets : length(regexall("^[a-zA-Z0-9_-]*$", secret.name)) > 0])
    error_message = "Secret names must match regex '^[a-zA-Z0-9_-]*$'"
  }
}

variable "subscribers" {
  description = "List of subscriber configuration objects"
  type = list(object({
    name                  = string
    secrets               = optional(list(string), []) # List of Secret Manager secret names to expose to subscriber as environment variables. Must match an actual secret name listed in the `secrets` variable 
    available_memory      = optional(string, "128Mi")  # The amount of memory to allocate to the subscrier
    timeout_seconds       = optional(number, 60)       # The timeout, in seconds
    max_instance_count    = optional(number, 100)      # Max number of concurrent instances of the subscriber
    environment_variables = optional(map(string), {})  # Additional environment variables to pass to the subscriber
  }))
  default = []
}

variable "create_firestore" {
  description = "Boolean to control creation of Firestore Database as only one App Engine application can exist per project. Set to false if you're already setup Firestore in this project."
  type        = bool
  default     = true
}

variable "feeds" {
  description = "A list of Feed config options"
  type = list(object({
    url         = string
    type        = string
    name        = string
    subscribers = optional(list(string), []) # A list of subscriber names (custom processors) to subscribe to this feed. Must actually exist as directory in /src/subscribers/ which will automatically get deployed as a python310 cloud function v2 when configured via the `subscribers` variable
    schedule    = optional(string, "*/5 * * * *")
  }))

  validation {
    condition     = alltrue([for feed in var.feeds : length(regexall("RSS|ATOM|JSON", feed.type)) > 0])
    error_message = ".type attribute must be either RSS, ATOM, or JSON"
  }

  validation {
    condition     = length(var.feeds) == length(toset([for feed in var.feeds : feed.name]))
    error_message = "All feeds in var.feeds must have a unique name"
  }

  default = []
}