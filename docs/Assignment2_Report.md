# Assignment 2 Report — ACEest CI/CD

**Course:** Introduction to DevOps (CSI ZG514 / SEZG514)  
**Name:** Sheetal Prasad Sahu  
**ID:** 2025tm93239  
**Repo:** https://github.com/2025tm93239/aceest-fitness-Assignment-2  
**Assignment2_Deliverables:** https://github.com/2025tm93239/aceest-fitness-Assignment-2/blob/main/ACEest_Assignment2_Deliverables.docx

**Screenshots:** folder `Screenshots and Video/` (also attached in Appendix A)

**README.md:** https://github.com/2025tm93239/aceest-fitness-Assignment-2/blob/main/README.md

---

## Table of contents

1. [Introduction](#1-introduction)  
2. [How the pipeline is set up](#2-how-the-pipeline-is-set-up)  
3. [Task 1 — Application](#3-task-1--application)  
4. [Task 2 — Git / GitHub](#4-task-2--git--github)  
5. [Task 3 — Pytest](#5-task-3--pytest)  
6. [Task 4 — Jenkins](#6-task-4--jenkins)  
7. [Task 5 — Docker and Docker Hub](#7-task-5--docker-and-docker-hub)  
8. [Task 6 — Kubernetes deployments](#8-task-6--kubernetes-deployments)  
9. [Task 7 — Build + test + Sonar together](#9-task-7--build--test--sonar-together)  
10. [Tools used](#10-tools-used)  
11. [Problems faced](#11-problems-faced)  
12. [What worked at the end](#12-what-worked-at-the-end)  
13. [What I am submitting](#13-what-i-am-submitting)  
[Appendix A — Screenshots](#appendix-a--screenshots)  
[Appendix B — Screenshot list](#appendix-b--screenshot-list)  

---

## 1. Introduction

For Assignment 2 I acted as the DevOps person for ACEest Fitness & Gym. The business logic is the same family as Assignment 1, but I moved it into a Flask web API instead of only desktop tkinter. Most of the work was done on the Prayogshala Linux VM: cloning the repo, running tests, Docker, Jenkins, SonarQube, and preparing Kubernetes YAMLs for Minikube as mentioned in the assignment PDF (v1.1).

---

## 2. How the pipeline is set up

In simple terms: I push code to GitHub. Two things can react to that — GitHub Actions (workflow in `.github/workflows/main.yml`) and Jenkins on the lab machine (`Jenkinsfile`, polls every 15 min or manual build). Both install dependencies, check syntax, build a Docker image, and run pytest. Jenkins can go further if configured: Sonar scan, push to Docker Hub, and apply rolling deploy on Minikube.

Images I built locally were tagged and pushed to Docker Hub as `2025tm93239/aceest-fitness:2.0.0` and `:latest`. For k8s I kept separate YAML files under `k8s/` for rolling update and the other strategies the sheet asks for.

---

## 3. Task 1 — Application

I kept old tkinter files in `versions/`. The actual service runs from `app.py`; `ACEest_Fitness.py` is the same app (filename for submission). Code is split into `aceest/programs.py`, `services.py`, and `storage.py`. The health route on `/` returns JSON with version `2.0.0` unless `APP_VERSION` is set in the environment.

Screenshots: Appendix A, figures 8–10 (running Flask and checking `/` in the browser).

---

## 4. Task 2 — Git / GitHub

Repository is public: https://github.com/2025tm93239/aceest-fitness-Assignment-2

I committed in steps — tests first, then Docker/Jenkins, then k8s manifests, Sonar file, docs — and used pull requests to merge branches into `main`. Commit history and closed PRs are in the appendix.

Screenshots: figures 1–5.

---

## 5. Task 3 — Pytest

There are 8 tests total: five hit the HTTP API in `test_app.py`, three test service functions in `test_services.py`. On the VM I always got `8 passed`. The same tests run on the Jenkins agent and again inside the Docker image so the container is validated before we treat the build as good.

Screenshots: figures 6–7.

---

## 6. Task 4 — Jenkins

I configured a Pipeline job from SCM (`aceest-fitness-build`) on the lab Jenkins (`localhost:8080`, user `cloud`). Script path is `Jenkinsfile` on branch `main`. Build #2 completed successfully in about 24 seconds — checkout, pip, compileall, pytest, docker build, tests in container, post cleanup.

Screenshots: figures 22–27 (Jenkins UI and pipeline views).

---

## 7. Task 5 — Docker and Docker Hub

`Dockerfile` uses `python:3.9-slim`, installs requirements, and starts gunicorn on port 5000. On the VM I built `aceest-fitness:latest`, ran it (sometimes on host port 5001 because 5000 was already used), and ran pytest inside the container.

I logged into Docker Hub and pushed tags `2.0.0` and `latest` under username `2025tm93239`.

Screenshots: figures 11–15.

---

## 8. Task 6 — Kubernetes deployments

All manifests are in `k8s/` with namespace `aceest`. Rolling deploy + service is the main one I used for demo (`deployment-rolling.yaml`, `service.yaml`). I also added YAML for blue-green, canary, shadow, and A/B (`APP_VERSION` differs between variants). Rollback for rolling is `kubectl rollout undo deployment/aceest-rolling -n aceest`. Helper script: `scripts/minikube-deploy.sh`.

Minikube service URL for evaluation: *(paste output of `minikube service aceest-api -n aceest --url` here before final submission)*

---

## 9. Task 7 — Build + test + Sonar together

Jenkins ties the steps in one file: after unit tests pass, it builds Docker, tests inside the image, then tries Sonar if `sonar-scanner` exists on the machine. I ran Sonar manually on the VM using `sonar-project.properties`; it failed a few times until PATH and token were correct, then analysis succeeded (dashboard project `aceest-fitness`).

GitHub Actions gives a second CI path when I push to `main`; one run failed on runner Python version, later workflow uses ubuntu-22.04 — see figure 29.

Screenshots: figures 16–21 (Sonar), 28–29 (Actions).

---

## 10. Tools used

Git/GitHub for source control, Jenkins for build server, Pytest for tests, SonarQube for static analysis, Docker for packaging, Docker Hub for registry, Minikube/kubernetes YAMLs for deployment strategies. That matches the tool list in the assignment handout.

---

## 11. Problems faced

- Jenkins could not run `docker` until `jenkins` user was added to the docker group and Jenkins was restarted.
- Port 5000 was already in use when Flask and Docker both wanted it — used `5001:5000` mapping.
- Minikube needed the image built after `eval $(minikube docker-env)`.
- Sonar: `sonar-scanner` not found at first; wget of official zip gave 403 on lab network; wrong token/host gave “not authorized” until fixed.
- GitHub Actions once failed because Python 3.9 was not on the runner image — adjusted workflow to 22.04.

---

## 12. What worked at the end

- 8/8 tests green in venv, Jenkins, and inside Docker.
- Jenkins pipeline green build with all main stages.
- Images on Docker Hub (`2.0.0`, `latest`).
- Sonar analysis completed (see appendix).
- k8s manifests present for all required deployment types; rolling deploy documented in README/runbook.

---

## 13. What I am submitting

- Public GitHub link (above)
- This report + `Assignment2_Report.pdf`
- `ACEest_Fitness.py`, `versions/`, `Jenkinsfile`, `Dockerfile`, `k8s/`, `tests/`, `sonar-project.properties`
- Screenshots in repo folder and Appendix A
- Jenkins and Sonar screenshots as proof
- Docker Hub tags screenshot (figure 15)
- Cluster URL — to be filled after final minikube test

---

## Appendix A — Screenshots

I stored these under `Screenshots and Video/`. Below is roughly the order I ran things on the lab VM.

### GitHub

Repo on `main` with Jenkinsfile, k8s, tests, etc.

![GitHub repo main branch](../Screenshots%20and%20Video/Screenshot%202026-11-24%20185250.png)

*Fig. 1 — GitHub repo page.*

![GitHub commit history](../Screenshots%20and%20Video/Screenshot%202026-11-24%20185356.png)

*Fig. 2 — Commit history.*

![GitHub closed pull requests](../Screenshots%20and%20Video/Screenshot%202026-11-24%20185444.png)

*Fig. 3 — Closed pull requests.*

### Lab VM — clone

Prayogshala Rocky VM, path `~/workspace/Assignment2/`.

![Git clone on lab VM](../Screenshots%20and%20Video/Screenshot%202026-11-24%20190610.png)

*Fig. 4 — git clone.*

![Project directory in Thunar](../Screenshots%20and%20Video/Screenshot%202026-11-24%20190639.png)

*Fig. 5 — project folders after clone.*

### Python, Flask, pytest

![venv and pip install](../Screenshots%20and%20Video/Screenshot%202026-11-24%20190854.png)

*Fig. 6 — Python **3.9.21**; `venv` + `pip install -r requirements.txt` (Flask 3.0.3, pytest 8.3.3).*

![pytest 8 passed](../Screenshots%20and%20Video/Screenshot%202026-11-24%20191120.png)

*Fig. 7 — `python3 -m pytest -v`: **8 passed** (API + service tests).*

![Flask dev server running](../Screenshots%20and%20Video/Screenshot%202026-11-24%20191551.png)

*Fig. 8 — `python3 app.py` listening on `0.0.0.0:5000` (dev server warning shown).*

![Flask server logs GET /](../Screenshots%20and%20Video/Screenshot%202026-11-24%20191629.png)

*Fig. 9 — Successful `GET /` (200) and expected `favicon.ico` 404.*

![Health JSON in browser port 5000](../Screenshots%20and%20Video/Screenshot%202026-11-24%20191726.png)

*Fig. 10 — `http://127.0.0.1:5000/`: `service`, `status: ok`, `version: 2.0.0`.*

### Docker

![Docker build run curl pytest](../Screenshots%20and%20Video/Screenshot%202026-11-24%20192336.png)

*Fig. 11 — `docker build`, `docker run -p 5001:5000`, `curl` health check, `docker exec … pytest -v` (8 passed), image ~130MB.*

![Docker Hub phase commands reference](../Screenshots%20and%20Video/Screenshot%202026-11-24%20193333.png)

*Fig. 12 — Runbook snippet: tag/push `2.0.0` and `latest` to Docker Hub.*

![docker images and login attempt](../Screenshots%20and%20Video/Screenshot%202026-11-24%20193418.png)

*Fig. 13 — Verify `aceest-fitness:latest`; web-based `docker login` canceled (later used `docker login -u`).*

![Health JSON via container port 5001](../Screenshots%20and%20Video/Screenshot%202026-11-24%20192500.png)

*Fig. 14 — API via mapped port **5001** (avoids conflict with dev server on 5000).*

### Docker Hub

![Docker login and push success](../Screenshots%20and%20Video/Screenshot%202026-11-24%20194816.png)

*Fig. 15 — `docker login -u 2025tm93239`; push `2025tm93239/aceest-fitness:2.0.0` and `:latest` (shared digest).*

### SonarQube

![sonar-scanner not on PATH](../Screenshots%20and%20Video/Screenshot%202026-11-24%20195153.png)

*Fig. 16 — Initial failure: `sonar-scanner: command not found`.*

![wget 403 Forbidden](../Screenshots%20and%20Video/Screenshot%202026-11-24%20195739.png)

*Fig. 17 — Official zip URL blocked (403) from lab; used local scanner tree instead.*

![Scanner install PATH troubleshooting](../Screenshots%20and%20Video/Screenshot%202026-11-24%20201803.png)

*Fig. 18 — Extracted scanner; PATH/`bashrc` adjustments until binary invoked by full path.*

![Placeholder host token failure](../Screenshots%20and%20Video/Screenshot%202026-11-24%20202338.png)

*Fig. 19 — Scan failed: `YOUR_SONAR_HOST` / invalid token (UnknownHostException).*

![Unauthorized scan attempt](../Screenshots%20and%20Video/Screenshot%202026-11-24%20223324.png)

*Fig. 20 — Scan reached SonarQube 9.9.8 but failed **Not authorized** until correct token/login.*

![ANALYSIS SUCCESSFUL](../Screenshots%20and%20Video/Screenshot%202026-11-24%20225420.png)

*Fig. 21 — Successful analysis: project `aceest-fitness`, dashboard link on `127.0.0.1:9000`.*

### Jenkins

![Jenkins sign-in](../Screenshots%20and%20Video/Picture4.png)

*Fig. 22 — Jenkins UI at `localhost:8080` (login as `cloud`).*

![New Pipeline item](../Screenshots%20and%20Video/Picture5.png)

*Fig. 23 — Create Pipeline job `aceest fitness build`.*

![Build #2 status page](../Screenshots%20and%20Video/Picture6.png)

*Fig. 24 — Build **#2** success (~24s); SCM revision from `aceest-fitness` GitHub repo.*

![Pipeline stage graph](../Screenshots%20and%20Video/Picture1.png)

*Fig. 25 — All stages green: Checkout → Install deps → Compile → Pytest → Docker build → Push (when enabled) → Post Actions.*

![Pipeline console Post Actions](../Screenshots%20and%20Video/Picture2.png)

*Fig. 26 — Post stage: workspace cleanup; log `BUILD passed on Linux agent`.*

![Pipeline Steps table](../Screenshots%20and%20Video/Picture3.png)

*Fig. 27 — Declarative pipeline step list (checkout, `pip install`, compileall, pytest, docker stages).*

### GitHub Actions

![Actions workflow success](../Screenshots%20and%20Video/Picture7.png)

*Fig. 28 — Workflow **Aceest Fitness CI/CD** run #3: job `build-lint-docker-test` succeeded (~23s) on push.*

![Actions workflow failure after merge](../Screenshots%20and%20Video/Screenshot%202026-11-24%20230340.png)

*Fig. 29 — Run #2 after merge PR #8: **failed** — Python 3.9 not available on Ubuntu 20.04 runner (annotation); requires runner/image fix.*


---