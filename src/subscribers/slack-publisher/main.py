#!/usr/bin/env python3 

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

import json, base64, os, re
from datetime import date
import requests
import functions_framework

from htmlslacker import HTMLSlacker

SLACK_WEBHOOKS = ""

def get_slack_webhook_url():
    return json.loads(os.environ["SLACK_WEBHOOK_URLS"])

try:
    SLACK_WEBHOOKS = get_slack_webhook_url()
except Exception:
    raise Exception("This subscriber MUST be configured with a JSON encoded environment variable named SLACK_WEBHOOK_URLS")

@functions_framework.http
def handler(event):
    print(event)
    print(event.get_data())
    payload = parse_event(event)
    print(f"Received new feed event: {payload}")

    slack_payload = build_slack_alert(payload)
    print(slack_payload)

    for webhook in SLACK_WEBHOOKS["webhooks"]:
        res = requests.post(webhook, json=slack_payload)
        print(res.text)

    return {}

def parse_event(e):
    return json.loads(base64.b64decode(json.loads(e.get_data())["message"]["data"]))

def build_slack_alert(update):

    try:
        description = HTMLSlacker(update['description']).get_output()
    except:
        print("No description attribute found")
        description = "No Description"

    today = date.today()
    return {
        "blocks": [{
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": f"{update['title']}"
            }
        },
        {
            "type": "context",
            "elements": [{
                "type": "mrkdwn",
                "text": f"*<!date^{today.strftime('%s')}^{{date}}|{today.strftime('%B %d, %Y')}>* | <{update['link']}|Google Cloud Service Health>"
            }]
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": description
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"*Published:* {update.get('published', 'N/A')}\n*GUID:* `{update['guid']}`"
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "context",
            "elements": [{
                "type": "mrkdwn",
                "text": "\n".join(update['links'])
            }]
        }
        ]
    }