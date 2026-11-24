# ACEest Fitness & Gym — Assignment 2

**Course:** CSI ZG514 / SEZG514 (Intro to DevOps)  
**GitHub:** https://github.com/2025tm93239/aceest-fitness-Assignment-2

This is my Assignment 2 submission for ACEest Fitness & Gym. I took the same logic from Assignment 1 (the `versions/` tkinter scripts) and built a Flask API in `app.py` with supporting code under `aceest/`. The rest of the work is CI/CD on the BITS Prayogshala Linux lab: Git, Pytest, Jenkins, Docker, Docker Hub, SonarQube, and Kubernetes YAMLs for Minikube.

Detailed write-up and screenshots are in [`docs/Assignment2_Report.md`](docs/Assignment2_Report.md). Step-by-step VM notes are in [`docs/LINUX-VM-ASSIGNMENT2.md`](docs/LINUX-VM-ASSIGNMENT2.md).

---

## What is in this repo

- `app.py` and `ACEest_Fitness.py` — main Flask entry (marker asked for `ACEest_Fitness.py` name)
- `aceest/` — programs, calorie logic, in-memory clients
- `tests/` — 8 pytest cases
- `versions/` — older tkinter files from Assignment 1
- `Dockerfile`, `Jenkinsfile`, `sonar-project.properties`
- `k8s/` — rolling, blue-green, canary, shadow, A/B YAMLs
- `scripts/linux-smoke-test.sh`, `scripts/minikube-deploy.sh`
- `docs/` — report, Jenkins setup, lab runbook
- `Screenshots and Video/` — proof for submission
- `.github/workflows/main.yml` — extra CI on GitHub when I push

---

## Prerequisites (lab VM)

- Python 3.9.x (on lab I had 3.9.21)
- Git, Docker
- Jenkins for the pipeline exercise
- SonarQube + sonar-scanner, kubectl, Minikube when you do those parts

```bash
python3 --version
docker --version
```

---

## Clone and run locally

```bash
git clone https://github.com/2025tm93239/aceest-fitness-Assignment-2.git
cd aceest-fitness-Assignment-2

python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
```

Run the app:

```bash
python3 app.py
```

Open http://127.0.0.1:5000/ — you should see JSON with `"status": "ok"` and version `2.0.0` (unless you set `APP_VERSION`).

Quick check on the VM (does venv, pytest, docker build, and a short curl):

```bash
chmod +x scripts/linux-smoke-test.sh
./scripts/linux-smoke-test.sh
```

---

## API endpoints (short list)

| Method | Path | What it does |
|--------|------|----------------|
| GET | `/` | Health check |
| GET | `/metrics` | Gym metrics |
| GET | `/programs` | List programs |
| GET | `/programs/<name>` | One program detail |
| POST | `/calories` | Calorie estimate (JSON body) |
| GET/POST | `/clients` | List or save clients |
| GET | `/clients/<name>` | One client |

---

## Tests

From repo root, with venv on:

```bash
python3 -m pytest -v
python3 -m compileall -q app.py aceest tests
```

I get **8 passed** (5 in `test_app.py`, 3 in `test_services.py`). Jenkins uses the same `python3 -m pytest` style.

If pytest cannot find `app`, make sure you are inside this folder and not running system Python without the venv.

---

## Docker

```bash
docker build -t aceest-fitness:latest .
docker run -d -p 5000:5000 --name aceest aceest-fitness:latest
curl http://127.0.0.1:5000/
docker run --rm aceest-fitness:latest python3 -m pytest -v
```

On my VM, port 5000 was often busy because Flask was already running, so I used:

```bash
docker run -d -p 5001:5000 --name aceest aceest-fitness:latest
```

Image is based on `python:3.9-slim` and runs with gunicorn inside the container.

---

## Docker Hub

I pushed to my account `2025tm93239`:

```bash
export DOCKERHUB_USER=2025tm93239
docker login -u 2025tm93239
docker tag aceest-fitness:latest ${DOCKERHUB_USER}/aceest-fitness:2.0.0
docker tag aceest-fitness:latest ${DOCKERHUB_USER}/aceest-fitness:latest
docker push ${DOCKERHUB_USER}/aceest-fitness:2.0.0
docker push ${DOCKERHUB_USER}/aceest-fitness:latest
```

In Jenkins, push only runs if you set `DOCKER_PUSH=true` and add the `dockerhub-aceest` credential (see `Jenkinsfile`).

---

## SonarQube

Config file is `sonar-project.properties` in the repo root. On the lab VM I ran something like:

```bash
sonar-scanner \
  -Dproject.settings=sonar-project.properties \
  -Dsonar.host.url=http://127.0.0.1:9000 \
  -Dsonar.token=<your-token>
```

It took a few tries to get scanner on PATH and the token right; Jenkins has a stage that runs scan only if `sonar-scanner` is installed.

---

## Kubernetes / Minikube

YAML files are in `k8s/`. Rolling deploy is the one I used first (`deployment-rolling.yaml` + `service.yaml`). Others are for blue-green, canary, shadow, and A/B as required in the assignment sheet.

```bash
minikube start --driver=docker
chmod +x scripts/minikube-deploy.sh
./scripts/minikube-deploy.sh
kubectl get pods -n aceest
minikube service aceest-api -n aceest --url
```

Remember to build the image inside minikube’s docker when needed:

```bash
eval $(minikube docker-env)
docker build -t aceest-fitness:latest .
```

Rollback example:

```bash
kubectl rollout undo deployment/aceest-rolling -n aceest
```

---

## GitHub Actions

File: `.github/workflows/main.yml`. On each push/PR to `main` it installs deps, runs `compileall`, builds the docker image, and runs pytest inside the container. I also kept Jenkins as the main build server for the assignment.

---

## Jenkins

I created a Pipeline job (`aceest-fitness-build`) pointing at this repo, branch `main`, script `Jenkinsfile`. The pipeline polls Git every 15 minutes or you can click Build Now.

Stages: checkout → pip install → compileall → pytest → docker build → pytest in container → sonar (if installed) → optional docker push → optional minikube deploy.

**First-time issue:** build failed because Jenkins could not access Docker. Fix on the server:

```bash
sudo systemctl enable --now docker
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
sudo -u jenkins docker ps
```

More detail: [`docs/JENKINS-SETUP.md`](docs/JENKINS-SETUP.md).

---

## GitHub Actions vs Jenkins (how I used both)

GitHub Actions runs when I push code — good for quick feedback. Jenkins on the lab VM is what I configured for the assignment build server, Sonar step, optional Hub push, and k8s deploy flags (`DOCKER_PUSH`, `K8S_DEPLOY`).