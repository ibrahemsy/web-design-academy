#!/usr/bin/env python3
# Copyright (c) 2026 Ibrahim Zainab. All rights reserved.
# GitHub: https://github.com/ibrahemsy

"""HTTP smoke test for the deployed Flutter web application.

This checks the public GitHub Pages document and the core Flutter runtime
assets. It is intentionally not described as a full browser/UI acceptance test.
"""
from __future__ import annotations

import os
import re
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin
from urllib.request import Request, urlopen

BASE_URL = os.environ.get("DEPLOYED_URL", "").strip()
if not BASE_URL:
    print("FAIL: DEPLOYED_URL is not set", file=sys.stderr)
    raise SystemExit(1)
if not BASE_URL.endswith("/"):
    BASE_URL += "/"

def fetch(url: str) -> tuple[bytes, str]:
    request = Request(url, headers={"User-Agent": "IZProgrammingAcademy-DeploymentSmokeTest/1.0"})
    with urlopen(request, timeout=20) as response:
        if response.status != 200:
            raise RuntimeError(f"{url} returned HTTP {response.status}")
        return response.read(), response.headers.get("Content-Type", "")

last_error: Exception | None = None
for attempt in range(12):
    try:
        html, content_type = fetch(BASE_URL)
        if "text/html" not in content_type.lower():
            raise RuntimeError(f"Expected HTML content type, received {content_type!r}")
        break
    except (HTTPError, URLError, TimeoutError, RuntimeError) as error:
        last_error = error
        if attempt == 11:
            print(f"FAIL: deployed page did not become healthy: {error}", file=sys.stderr)
            raise SystemExit(1)
        time.sleep(5)

document = html.decode("utf-8", errors="replace")
if "الأكاديمية البرمجية i.z" not in document:
    raise SystemExit("FAIL: deployed HTML does not contain the academy page title")
if "flutter_bootstrap.js" not in document:
    raise SystemExit("FAIL: Flutter bootstrap script is missing from deployed HTML")

base_match = re.search(r'<base href="([^"]*)"', document)
if not base_match or not base_match.group(1).startswith("/web-design-academy/"):
    raise SystemExit("FAIL: deployed Flutter base href does not match the GitHub Pages project path")

for asset in ("flutter_bootstrap.js", "flutter.js", "main.dart.js", "assets/AssetManifest.bin"):
    try:
        body, asset_type = fetch(urljoin(BASE_URL, asset))
    except Exception as error:
        raise SystemExit(f"FAIL: required Flutter asset {asset} could not be fetched: {error}")
    if not body:
        raise SystemExit(f"FAIL: required Flutter asset {asset} is empty")
    print(f"PASS: {asset} ({len(body)} bytes; {asset_type or 'content type unavailable'})")

print(f"PASS: deployed Flutter web page is responding at {BASE_URL}")
