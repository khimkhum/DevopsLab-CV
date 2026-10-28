#!/usr/bin/env python3
"""Validate the served release and its actual container HTTP protections."""
import argparse
import json
import urllib.error
import urllib.request
import http.client
import io
import sys
import time

parser = argparse.ArgumentParser()
parser.add_argument("base", nargs="?", default="http://127.0.0.1:8080")
parser.add_argument("--host", help="HTTP Host used to select an Ingress")
parser.add_argument("--timeout", type=float, default=10)
parser.add_argument("--retries", type=int, default=0)
args = parser.parse_args()
if args.timeout <= 0 or not 0 <= args.retries <= 3:
    parser.error("--timeout must be positive; --retries must be 0..3")

base = args.base.rstrip("/")
request_headers = {"User-Agent": "Khimkum-CV-SmokeTest/1.0"}
if args.host:
    request_headers["Host"] = args.host

class BufferedResponse(io.BytesIO):
    def __init__(self, response):
        self.status = response.status
        self.headers = response.headers
        super().__init__(response.read())


def get(path, method='GET'):
    for attempt in range(args.retries + 1):
        req = urllib.request.Request(
            base + path,
            method=method,
            headers=request_headers,
        )

        try:
            try:
                response = urllib.request.urlopen(
                    req, timeout=args.timeout
                )
            except urllib.error.HTTPError as error:
                response = error

            with response:
                return BufferedResponse(response)

        except (
            TimeoutError,
            ConnectionError,
            urllib.error.URLError,
            http.client.IncompleteRead,
        ) as error:
            reason = getattr(error, 'reason', error)

            if method not in ('GET', 'HEAD'):
                raise

            if not isinstance(reason, (
                TimeoutError,
                ConnectionError,
                http.client.IncompleteRead,
            )):
                raise

            if attempt == args.retries:
                raise

            print(
                f'RETRY {attempt + 1}/{args.retries}: '
                f'{method} {path}: '
                f'{type(reason).__name__}: {reason}',
                file=sys.stderr,
            )

            time.sleep(min(2 ** attempt, 4))

home = get('/')
assert home.status == 200, f'Home returned {home.status}'
html = home.read().decode('utf-8')
assert 'Lê Văn Khiêm' in html, 'Wrong site served'
assert home.headers.get('X-Content-Type-Options') == 'nosniff', 'Missing nosniff'
assert 'frame-ancestors' in home.headers.get('Content-Security-Policy', ''), 'Missing CSP'

pdf = get('/cv/le-van-khiem-devops.pdf')
assert pdf.status == 200 and pdf.read(5) == b'%PDF-', 'CV download failed'
assert get('/healthz').read().strip() == b'ok', 'Health endpoint failed'

release = get('/version.json')
metadata = json.load(release)
assert set(metadata) == {'version', 'commit', 'builtAt'}, 'Unexpected release metadata'
assert 'no-cache' in release.headers.get('Cache-Control', ''), 'Revision endpoint is cached'

assert get('/not-a-real-route/').status == 404, 'Unknown route should return 404'
assert get('/.env').status in (403, 404), 'Dotfiles are exposed'
assert get('/', method='POST').status == 405, 'Write methods should not be accepted'
assert get('/', method='HEAD').status == 200, 'HEAD should work'
print('PASS: page, CV download, health, release metadata, security headers, 404 and method restrictions')
