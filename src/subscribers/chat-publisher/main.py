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
from uuid import uuid4 as guid

try:
    GOOGLE_CHAT_WEBHOOKS = json.loads(os.environ.get("CHAT_WEBHOOK_URLS"))
except ValueError:
    print(f"GOOGLE_CHAT_WEBHOOKS environment variable has not been set. This subscriber requires it in order to be deployed.")

@functions_framework.http
def handler(event):
    payload = parse_event(event)
    print(f"Received new feed event: {payload}")

    payload = build_chat_alert(payload)
    print(payload)

    for webhook in GOOGLE_CHAT_WEBHOOKS["webhooks"]:
        res = requests.post(webhook, json=payload)
        print(res.text)

    return {}

def parse_event(e):
    return json.loads(base64.b64decode(json.loads(e.get_data())["message"]["data"]))

def build_chat_alert(update):

    description = update.get('description', 'No Description')
    image_url = os.environ.get("IMAGE_URL", "https://banner2.cleanpng.com/20180424/qwq/kisspng-rss-web-feed-computer-icons-feed-5adf845abd7789.3234863615245978507761.jpg")
    today = date.today()

    return {
        "cards_v2": [
        {
            "card_id": f"{guid()}",
            "card": {
                "header": {
                    "title": f"{update['title']}",
                    "subtitle": f"{today.strftime('%B %d, %Y')}",
                    "imageUrl": image_url,
                    "imageType": "CIRCLE"
                },
                "sections": [
                    {
                        "widgets": [
                            {
                                "textParagraph": {
                                    "text": description
                                }
                            }
                        ]
                    },
                    {
                        "widgets": [
                            {
                                "textParagraph": {
                                    "text": f"<b>Published:</b> {update.get('published', 'N/A')}"
                                }
                            },
                            {
                                "buttonList": {
                                    "buttons": [
                                        {
                                        "text": "More Info",
                                        "onClick": {
                                            "openLink": {
                                            "url": f"{update['link']}",
                                            }
                                        }
                                        }
                                    ]
                                }
                            }
                        ]
                    }
                ]
            }
        }]
    }