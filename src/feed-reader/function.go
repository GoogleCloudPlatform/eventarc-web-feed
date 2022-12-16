package reader

// Copyright 2022 Google LLC

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     https://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/url"
	"os"
	"sync"
	"sync/atomic"
	"time"

	b64 "encoding/base64"

	firestore "cloud.google.com/go/firestore"
	"cloud.google.com/go/pubsub"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/cloudevents/sdk-go/v2/event"
	"github.com/mmcdole/gofeed"
)

// MessagePublishedData contains the full Pub/Sub message
// See the documentation for more details:
// https://cloud.google.com/eventarc/docs/cloudevents#pubsub
type MessagePublishedData struct {
	Message PubSubMessage
}

type PubSubMessage struct {
	Data []byte `json:"data"`
}

type FeedReaderPayload struct {
	Feed      string `json:"feed"`
	TopicId   string `json:"topicId"`
	Type      string `json:"type"`
	CachePath string `json:"cachePath"`
}

type NewEvents []*gofeed.Item

var dbClient *firestore.Client
var projectId string

func init() {
	var err error
	projectId = os.Getenv("FIRESTORE_PROJECT_ID")

	ctx := context.Background()
	dbClient, err = firestore.NewClient(ctx, projectId)
	if err != nil {
		log.Fatalf("firebase.Firestore: %v", err)
	}

	functions.CloudEvent("Handler", handler)
}

// Handler consumes a Pub/Sub message.
func handler(ctx context.Context, e event.Event) error {

	var msg MessagePublishedData
	if err := e.DataAs(&msg); err != nil {
		return fmt.Errorf("event.DataAs: %v", err)
	}

	feedConfig, err := msg.Message.Decode()
	if err != nil {
		log.Fatal(err)
		return err
	}

	fmt.Printf("Starting polling for %s...", feedConfig.CachePath)

	newItems, err := feedConfig.Poll()
	if err != nil {
		log.Fatal(err)
		return err
	}

	err = feedConfig.Publish(newItems)
	if err != nil {
		log.Fatal(err)
		return err
	}
	return err
}

func (p *PubSubMessage) Decode() (*FeedReaderPayload, error) {
	var payload FeedReaderPayload
	if err := json.Unmarshal(p.Data, &payload); err != nil {
		log.Println(err)
		return nil, err
	}
	return &payload, nil
}

func (p *FeedReaderPayload) Poll() (NewEvents, error) {
	ctx := context.Background()
	var wg sync.WaitGroup
	var events NewEvents

	fp := gofeed.NewParser()

	eventCollection := dbClient.Collection(p.CachePath)

	feed, err := fp.ParseURL(p.Feed)
	if err != nil {
		fmt.Println(err)
		return nil, err
	}

	for _, item := range feed.Items {
		wg.Add(1)
		go func(i *gofeed.Item) {
			defer wg.Done()
			eventId := url.PathEscape(b64.StdEncoding.EncodeToString([]byte(i.GUID)))
			if _, err := eventCollection.Doc(eventId).Get(ctx); err != nil {
				fmt.Printf(err.Error())
				fmt.Printf("Writing new event to cache: %s", eventId)
				var docData map[string]interface{}
				data, _ := json.Marshal(i)
				json.Unmarshal(data, &docData)
				// Set document to expire 30 days from now
				docData["expireAt"] = time.Now().Add((time.Hour * 24 * 30))
				eventCollection.Doc(eventId).Set(ctx, docData)
				events = append(events, i)
			} else {
				fmt.Println("Feed item already exists in cache. Skipping...")
				return
			}
		}(item)
	}
	wg.Wait()
	return events, nil
}

func (p *FeedReaderPayload) Publish(e NewEvents) error {
	ctx := context.Background()
	var wg sync.WaitGroup
	var totalErrors uint64

	client, err := pubsub.NewClient(ctx, projectId)
	if err != nil {
		return err
	}
	defer client.Close()
	t := client.Topic(p.TopicId)

	for _, event := range e {
		data, err := json.Marshal(event)
		if err != nil {
			return err
		}
		fmt.Printf("Publishing %s ...", data)
		result := t.Publish(ctx, &pubsub.Message{
			Data: data,
			Attributes: map[string]string{
				"origin": p.CachePath,
				"feed":   p.Feed,
			},
		})

		wg.Add(1)
		go func(res *pubsub.PublishResult) {
			defer wg.Done()
			id, err := res.Get(ctx)
			if err != nil {
				fmt.Printf("Failed to publish: %v", err)
				atomic.AddUint64(&totalErrors, 1)
				return
			}
			fmt.Printf("Successfully published %s", id)
		}(result)
	}

	wg.Wait()
	if totalErrors > 0 {
		return fmt.Errorf("%d of %d messages did not publish successfully", totalErrors, len(e))
	}
	return nil
}
