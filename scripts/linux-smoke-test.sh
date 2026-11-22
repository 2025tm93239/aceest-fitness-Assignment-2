#!/bin/bash
# Quick checks on the course Linux VM — run from repo root.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== venv + pytest =="
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -q -r requirements.txt
python3 -m pytest -v
python3 -m compileall -q app.py aceest tests

echo "== docker build =="
docker build -t aceest-fitness:latest .
docker run --rm aceest-fitness:latest python3 -m pytest -v

echo "== smoke curl (background app 5 sec) =="
docker run -d --rm -p 5099:5000 --name aceest-smoke aceest-fitness:latest
sleep 3
curl -sf http://127.0.0.1:5099/ | head -c 200
docker stop aceest-smoke

echo "OK — local smoke test passed"