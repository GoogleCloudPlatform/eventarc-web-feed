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

# List of feed configuration objects
feeds = []

# List of subscriber configuration objects
subscribers = []

# List of secret configuration objects
# The `secrets` list(string) variable should ideally be set using the TF_VAR_ syntax to avoid committing it to version control
# https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#private_cp
secrets = []