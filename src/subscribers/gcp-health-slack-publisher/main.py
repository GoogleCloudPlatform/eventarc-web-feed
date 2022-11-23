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
    print(f"Received new health event: {payload}")

    slack_payload = build_slack_alert(payload)
    print(slack_payload)

    for webhook in SLACK_WEBHOOKS["webhooks"]:
        res = requests.post(webhook, json=slack_payload)
        print(res.text)

    return {}

def parse_event(e):
    return json.loads(base64.b64decode(json.loads(e.get_data())["message"]["data"]))

def build_slack_alert(update):

    emoji = ":rotating_light:"
    links = [f"<{l}>" for l in update['links']]

    if 'UPDATE:' in update['title']:
        emoji = ":mega:"
    elif 'RESOLVED:' in update['title']:
        emoji = ":white_check_mark:"

    summary, regions, products = parse_description(update['description'])

    today = date.today()
    return {
        "blocks": [{
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "GCP Health Alerts"
            }
        },
        {
            "type": "context",
            "elements": [{
                "type": "mrkdwn",
                "text": f"*<!date^{today.strftime('%s')}^{{date}}|{today.strftime('%B %d, %Y')}>* | <https://status.cloud.google.com/|Google Cloud Service Health>"
            }]
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"{emoji} *{update['title']}* {emoji}"
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": summary
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*Affected Regions:*\n"
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": ", ".join(regions) if len(regions) > 0 else "N/A"
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*Affected Products:*\n"
            }
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": f"{product.strip()}"} for product in products
            ]
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"*Updated:* {update['updated']}\n*Published:* {update['published']}\n*GUID:* `{update['guid']}`"
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "context",
            "elements": [{
                "type": "mrkdwn",
                "text": "\n".join(links)
            }]
        }
        ]
    }

def parse_description(description):
    i = re.sub('\<\/{0,1}p\>|\<\/{0,1}span\>', '\n', description)
    # j = re.sub('\<\/{0,1}strong\>', '*', i)
    # k = j.replace("<hr>", "")
    k = HTMLSlacker(i).get_output()

    try:
        [t, r] = k.split("Affected locations:")
    except ValueError:
        t, r = k, ""

    try:
        [text, p] = t.split("Affected products:")
    except ValueError:
        text, p = t, ""

    regions = r.split(",") if r != "" else []
    products = p.split(",") if p != "" else []

    return text, regions, products
