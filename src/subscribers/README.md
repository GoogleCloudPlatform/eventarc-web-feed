# Subscribers
Feed subscribers are pieces of custom logic that are invoked for every new update to a web feed. A single web feed can target _multiple_ subscribers. In addition, multiple web feeds can target the same subscriber. By default, we provide some pre-packaged subscribers for common use cases. You can consume these subscribers as is, extend upon them, or create entirely new ones.

## Configuring Subscribers
Subscribers can be configured using the `subscribers` Terraform variable. This variable is a list of subscriber configuration objects. At a minimum, every subscriber config object requires a `name` attribute, which must match the name of a directory located in [the subscribers directory](./). Additionally, subscribers can optionally be configured with the attributes listed below:

```hcl
variable "subscribers" {
  description = "List of subscriber configuration objects"
  type = list(object({
    name                  = string
    secrets               = optional(list(string), []) # List of Secret Manager secret names to expose to subscriber as environment variables. Must match an actual secret name listed in the `secrets` variable 
    available_memory      = optional(string, "128Mi") # The amount of memory to allocate to the subscrier
    timeout_seconds       = optional(number, 60) # The timeout, in seconds
    max_instance_count    = optional(number, 100) # Max number of concurrent instances of the subscriber
    environment_variables = optional(map(string), {}) # Additional environment variables to pass to the subscriber
  }))
  default = []
}
```

### Passing sensitive values to subscribers
The Terraform module supports the storage of sensitive values as [Secret Manager](https://cloud.google.com/secret-manager) secrets. When specifying a subscriber's configuration via the `subscribers` TF variable, the optional `secrets` list attribute takes a list of Secret Manager secret names to expose to the subscriber via environment variables. The environment variable naming convention takes the name of the Secrets Manager secret, converts it to uppercase, and replaces all `-` characters with `_`. The methods used to format the environment variable name is `upper(replace(secret.name, "-", "_"))`. For example ->
  - A value of a Secret Manager secret named `my-secret` is exposed to the subscriber as an environment variable named `MY_SECRET`


## Included subscribers
### `slack-publisher`
A generic subscriber which will publish RSS feed events to Slack channels via webhooks. This subscriber requires that a secret with a name of `slack-webhook-urls` whose value is a json encoded object with a root attribute of "webhooks" whose value is a list of valid Slack webhooks (see below)
```json
{
    "webhooks": ["https://hooks.slack.com/services/${WEBHOOK_PATH}"]
}
```

### `gcp-health-slack-publisher`
A fork of the `slack-publisher` which has logic to parse the opinionated structure of the Google Cloud Service Health RSS Feed events and publish them to a defined Slack webhook (hosted in Secret Manager). This subscribers requires that a secret with a name of `slack-webhook-urls` whose value is a json encoded object with a root attribute of "webhooks" whose value is a list of valid Slack webhooks (see below)
```json
{
    "webhooks": ["https://hooks.slack.com/services/${WEBHOOK_PATH}"]
}
```

### `chat-publisher`
A generic subscriber which will publish RSS feed events to Google Chat Spaces via webhooks. This subscriber requires that a secret with a name of `chat-webhook-urls` whose value is a json encoded object with a root attribute of "webhooks" whose value is a list of valid Google Chat webhooks (see below)
```json
{
    "webhooks": ["https://chat.googleapis.com/v1/spaces/${YOUR_CHAT_SPACE_ID}/messages?key=${YOUR_WEBHOOK_KEY}"]
}
```
  
### Creating a custom feed subscriber
This project was designed to be extensible so that users can create their own custom integrations from the web feeds they choose to scrape. In order to create a new subscriber, run `make new.subscriber name=${YOUR_NEW_SUBSCRIBER_NAME}` from the root of the repository and subscriber scaffolding will be generated in the [./src/subscribers/](./src/subscribers/) directory.


### The Subscriber Protocol
Custom built subscribers must adhere to the following protocol:

- Written in Python 3.10 
- Located in it's own subdirectory of [./src/subscribers/](./src/subscribers/) that is named after the subscriber name (subscribers in this directory whose names begin with `_` will be ignored).
- Subscriber entrypoint is located in `./src/subscribers/{subscriber-name}/main.py`, in a method named `handler`.
- Subscriber dependencies defined in `./src/subscribers/{subscriber-name}/requirements.txt` and ideally should be pinned
- Handler must adhere to the [functions_framework.http](https://github.com/GoogleCloudPlatform/functions-framework-python) event protocols