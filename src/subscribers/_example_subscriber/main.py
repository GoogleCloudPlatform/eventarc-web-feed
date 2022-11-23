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

import json, base64
import functions_framework

@functions_framework.http
def handler(event):
    print(event.data)
    payload = parse_event(event)
    print(f"Received new event: {payload}")
    return {}

def parse_event(e):
    return json.loads(base64.b64decode(json.loads(e.get_data())["message"]["data"]))