#!/usr/bin/env python3
"""Validate the served release and its actual container HTTP protections."""
import argparse
import json
import urllib.error
import urllib.request

parser = argparse.ArgumentParser()
parser.add_argument("base", nargs="?", default="http://127.0.0.1:8080")
parser.add_argument("--host", help="HTTP Host used to select an Ingress")
args = parser.parse_args()

base = args.base.rstrip("/")
request_headers = {"User-Agent": "Khimkum-CV-SmokeTest/1.0"}
if args.host:
    request_headers["Host"] = args.host

def get(path, method='GET'):
    req = urllib.request.Request(
        base + path,
        method=method,
        headers=request_headers,
    )
    try:
        return urllib.request.urlopen(req, timeout=10)
    except urllib.error.HTTPError as error:
        return error

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
