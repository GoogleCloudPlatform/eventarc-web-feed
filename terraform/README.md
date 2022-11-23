<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.2.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.41.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | ~> 4.26.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.2.0 |
| <a name="provider_google"></a> [google](#provider\_google) | 4.41.0 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | 4.26.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.4.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google-beta_google_project_service_identity.pubsub](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_project_service_identity) | resource |
| [google_app_engine_application.firestore](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/app_engine_application) | resource |
| [google_cloud_scheduler_job.feed_reader](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_scheduler_job) | resource |
| [google_cloudfunctions2_function.feed_reader](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function) | resource |
| [google_cloudfunctions2_function.subscribers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function) | resource |
| [google_eventarc_trigger.subscribers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/eventarc_trigger) | resource |
| [google_project_iam_member.event_arc_sub_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.feed_reader](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.feed_subscriber](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.pubsub_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_pubsub_topic.feed_reader](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic.feeds](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_secret_manager_secret.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_iam_policy.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_policy) | resource |
| [google_secret_manager_secret_version.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_service_account.event_arc_sub_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account.feed_reader](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account.feed_subscriber](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_storage_bucket.gcf_artifacts](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_object.feed_reader](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_storage_bucket_object.subscribers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [null_resource.firestore_ttl](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [archive_file.feed_reader](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.subscribers](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_iam_policy.secrets](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_project.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_firestore"></a> [create\_firestore](#input\_create\_firestore) | Boolean to control creation of Firestore Database as only one App Engine application can exist per project. Set to false if you're already setup Firestore in this project. | `bool` | `true` | no |
| <a name="input_feeds"></a> [feeds](#input\_feeds) | A list of Feed config options | <pre>list(object({<br>    url         = string<br>    type        = string<br>    name        = string<br>    subscribers = optional(list(string), []) # A list of subscriber names (custom processors) to subscribe to this feed. Must actually exist as directory in /src/subscribers/ which will automatically get deployed as a python310 cloud function v2 when configured via the `subscribers` variable<br>    schedule    = optional(string, "*/5 * * * *")<br>  }))</pre> | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | The GCP region to deploy resources into [Default = us-central] | `string` | `"us-central1"` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | Map of secret name to secret value to store in Secrets Manager | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_subscribers"></a> [subscribers](#input\_subscribers) | List of subscriber configuration objects | <pre>list(object({<br>    name                  = string<br>    secrets               = optional(list(string), []) # List of Secret Manager secret names to expose to subscriber as environment variables. Must match an actual secret name listed in the `secrets` variable <br>    available_memory      = optional(string, "128Mi")  # The amount of memory to allocate to the subscrier<br>    timeout_seconds       = optional(number, 60)       # The timeout, in seconds<br>    max_instance_count    = optional(number, 100)      # Max number of concurrent instances of the subscriber<br>    environment_variables = optional(map(string), {})  # Additional environment variables to pass to the subscriber<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_feed_topics"></a> [feed\_topics](#output\_feed\_topics) | n/a |
<!-- END_TF_DOCS -->