module github.com/noahmercado/gcp-health-notifier/src/feed-reader

go 1.16

require (
	cloud.google.com/go/firestore v1.8.0
	cloud.google.com/go/pubsub v1.26.0
	github.com/GoogleCloudPlatform/functions-framework-go v1.6.1
	github.com/cloudevents/sdk-go/v2 v2.15.2
	github.com/mmcdole/gofeed v1.1.3
)
