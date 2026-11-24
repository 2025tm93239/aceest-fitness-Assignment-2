# Assignment 2 Report — ACEest CI/CD

**Student:** _(your name)_  
**BITS ID:** _(id)_  
**Repo:** https://github.com/2025tm93239/aceest-fitness-Assignment-2  
**Evidence folder:** [`../Screenshots and Video/`](../Screenshots%20and%20Video/) (30 PNG screenshots; no video file was present at time of report update)

## Architecture

I continued from Assignment 1 tkinter code in `versions/` and refactored the same program rules into Flask (`app.py` / `ACEest_Fitness.py`) with package `aceest/`.

Pipeline on the Linux VM:

1. Git push to GitHub  
2. Jenkins polls SCM every ~15 min (or manual Build Now)  
3. pip install → compileall → pytest  
4. docker build + pytest inside container  
5. optional sonar-scanner  
6. optional push to Docker Hub  
7. optional `kubectl apply` on Minikube  

GitHub Actions (`.github/workflows/main.yml`) still runs the same checks on each push for backup CI.

## Tools mapping

| Assignment item | What I used |
|-----------------|-------------|
| Git / GitHub | This repo, feature commits for k8s and Jenkins CD |
| Jenkins | `Jenkinsfile` on lab VM |
| Pytest | `tests/test_app.py`, `tests/test_services.py` |
| SonarQube | `sonar-project.properties` + scanner on VM |
| Docker | `Dockerfile`, local + Hub tags |
| Kubernetes | `k8s/*.yaml` on Minikube |

## Deployment strategies (k8s folder)

- **Rolling** — `deployment-rolling.yaml` + `service.yaml` (main demo)  
- **Blue-Green** — blue/green deployments; patch service selector  
- **Canary** — 3 stable + 1 canary replica, separate service for canary  
- **Shadow** — extra deployment for mirrored traffic lab setup  
- **A/B** — two variant deployments with different `APP_VERSION`  
- **Rollback** — `kubectl rollout undo deployment/aceest-rolling -n aceest`

## Problems I hit

1. Jenkins user could not talk to Docker — fixed with `usermod -aG docker jenkins` (documented in README).  
2. Minikube needed images built *inside* minikube docker env — `eval $(minikube docker-env)` before build.  
3. Port 5000 busy on VM when Flask dev server and container both running — used different host port or stopped old container.  
4. Sonar scanner not installed first time — Jenkins stage skips with a log message until scanner is on PATH.  
5. Direct `wget` of Sonar scanner zip returned **403 Forbidden** from lab network; used copy/unzip from workspace instead and fixed `PATH` to `~/workspace/Assignment2/sonar-scanner-5.0.1.3006-linux/bin`.  
6. First Sonar scan failed with **Not authorized** until a valid project token and `sonar.host.url=http://127.0.0.1:9000` were used.  
7. One GitHub Actions run failed on **Python 3.9 not found on Ubuntu 20.04** runner after a merge; earlier runs succeeded with the same workflow.

## Outcomes

- 8 automated tests on every build  
- Docker image is reproducible (`python:3.9-slim`, gunicorn)  
- Multiple k8s manifests ready for strategy demonstration  
- Jenkins can push tagged images when `DOCKER_PUSH=true`  
- Docker Hub: `2025tm93239/aceest-fitness:2.0.0` and `:latest`  
- SonarQube dashboard: `http://127.0.0.1:9000/dashboard?id=aceest-fitness` (analysis successful)

---

## Screenshot evidence (chronological workflow)

Paths are relative to this `docs/` file. Image filenames match the folder on disk.

### 1. GitHub — repository, commits, and pull requests

Public repository on `main` with CI (`Jenkinsfile`, `k8s/`, `tests/`, `sonar-project.properties`, etc.).

![GitHub repo main branch](../Screenshots%20and%20Video/Screenshot%202026-11-24%20185250.png)

*Figure 1 — Repository landing page: `aceest-fitness-Assignment-2` (Python ~98.5%).*

![GitHub commit history](../Screenshots%20and%20Video/Screenshot%202026-11-24%20185356.png)

*Figure 2 — Recent commits (k8s, Jenkins CD, Linux runbook, report/README updates, merges).*

![GitHub closed pull requests](../Screenshots%20and%20Video/Screenshot%202026-11-24%20185444.png)

*Figure 3 — Seven closed PRs covering Sonar props, k8s rolling deploy, deployment strategies, Jenkins pipeline, and docs.*

### 2. BITS Prayogshala Linux VM — clone and project layout

Lab VM (Rocky/Xfce) via Prayogshala RDP; workspace under `~/workspace/Assignment2/`.

![Git clone on lab VM](../Screenshots%20and%20Video/Screenshot%202026-11-24%20190610.png)

*Figure 4 — `git clone` of the Assignment 2 repo (2726 objects received).*

![Project directory in Thunar](../Screenshots%20and%20Video/Screenshot%202026-11-24%20190639.png)

*Figure 5 — Cloned tree: `aceest/`, `k8s/`, `tests/`, `Jenkinsfile`, `Dockerfile`, `docs/`, etc.*

### 3. Python environment, Flask app, and Pytest

![venv and pip install](../Screenshots%20and%20Video/Screenshot%202026-11-24%20190854.png)

*Figure 6 — Python **3.9.21**; `venv` + `pip install -r requirements.txt` (Flask 3.0.3, pytest 8.3.3).*

![pytest 8 passed](../Screenshots%20and%20Video/Screenshot%202026-11-24%20191120.png)

*Figure 7 — `python3 -m pytest -v`: **8 passed** (API + service tests).*

![Flask dev server running](../Screenshots%20and%20Video/Screenshot%202026-11-24%20191551.png)

*Figure 8 — `python3 app.py` listening on `0.0.0.0:5000` (dev server warning shown).*

![Flask server logs GET /](../Screenshots%20and%20Video/Screenshot%202026-11-24%20191629.png)

*Figure 9 — Successful `GET /` (200) and expected `favicon.ico` 404.*

![Health JSON in browser port 5000](../Screenshots%20and%20Video/Screenshot%202026-11-24%20191726.png)

*Figure 10 — `http://127.0.0.1:5000/`: `service`, `status: ok`, `version: 2.0.0`.*

### 4. Docker build, run, and in-container tests

![Docker build run curl pytest](../Screenshots%20and%20Video/Screenshot%202026-11-24%20192336.png)

*Figure 11 — `docker build`, `docker run -p 5001:5000`, `curl` health check, `docker exec … pytest -v` (8 passed), image ~130MB.*

![Docker Hub phase commands reference](../Screenshots%20and%20Video/Screenshot%202026-11-24%20193333.png)

*Figure 12 — Runbook snippet: tag/push `2.0.0` and `latest` to Docker Hub.*

![docker images and login attempt](../Screenshots%20and%20Video/Screenshot%202026-11-24%20193418.png)

*Figure 13 — Verify `aceest-fitness:latest`; web-based `docker login` canceled (later used `docker login -u`).*

![Health JSON via container port 5001](../Screenshots%20and%20Video/Screenshot%202026-11-24%20192500.png)

*Figure 14 — API via mapped port **5001** (avoids conflict with dev server on 5000).*

### 5. Docker Hub — login and push

![Docker login and push success](../Screenshots%20and%20Video/Screenshot%202026-11-24%20194816.png)

*Figure 15 — `docker login -u 2025tm93239`; push `2025tm93239/aceest-fitness:2.0.0` and `:latest` (shared digest).*

### 6. SonarQube scanner setup and analysis

![sonar-scanner not on PATH](../Screenshots%20and%20Video/Screenshot%202026-11-24%20195153.png)

*Figure 16 — Initial failure: `sonar-scanner: command not found`.*

![wget 403 Forbidden](../Screenshots%20and%20Video/Screenshot%202026-11-24%20195739.png)

*Figure 17 — Official zip URL blocked (403) from lab; used local scanner tree instead.*

![Scanner install PATH troubleshooting](../Screenshots%20and%20Video/Screenshot%202026-11-24%20201803.png)

*Figure 18 — Extracted scanner; PATH/`bashrc` adjustments until binary invoked by full path.*

![Placeholder host token failure](../Screenshots%20and%20Video/Screenshot%202026-11-24%20202338.png)

*Figure 19 — Scan failed: `YOUR_SONAR_HOST` / invalid token (UnknownHostException).*

![Unauthorized scan attempt](../Screenshots%20and%20Video/Screenshot%202026-11-24%20223324.png)

*Figure 20 — Scan reached SonarQube 9.9.8 but failed **Not authorized** until correct token/login.*

![ANALYSIS SUCCESSFUL](../Screenshots%20and%20Video/Screenshot%202026-11-24%20225420.png)

*Figure 21 — Successful analysis: project `aceest-fitness`, dashboard link on `127.0.0.1:9000`.*

### 7. Jenkins (Rocky Linux lab) — pipeline job and green build

![Jenkins sign-in](../Screenshots%20and%20Video/Picture4.png)

*Figure 22 — Jenkins UI at `localhost:8080` (login as `cloud`).*

![New Pipeline item](../Screenshots%20and%20Video/Picture5.png)

*Figure 23 — Create Pipeline job `aceest fitness build`.*

![Build #2 status page](../Screenshots%20and%20Video/Picture6.png)

*Figure 24 — Build **#2** success (~24s); SCM revision from `aceest-fitness` GitHub repo.*

![Pipeline stage graph](../Screenshots%20and%20Video/Picture1.png)

*Figure 25 — All stages green: Checkout → Install deps → Compile → Pytest → Docker build → Push (when enabled) → Post Actions.*

![Pipeline console Post Actions](../Screenshots%20and%20Video/Picture2.png)

*Figure 26 — Post stage: workspace cleanup; log `BUILD passed on Linux agent`.*

![Pipeline Steps table](../Screenshots%20and%20Video/Picture3.png)

*Figure 27 — Declarative pipeline step list (checkout, `pip install`, compileall, pytest, docker stages).*

### 8. GitHub Actions CI

![Actions workflow success](../Screenshots%20and%20Video/Picture7.png)

*Figure 28 — Workflow **Aceest Fitness CI/CD** run #3: job `build-lint-docker-test` succeeded (~23s) on push.*

![Actions workflow failure after merge](../Screenshots%20and%20Video/Screenshot%202026-11-24%20230340.png)

*Figure 29 — Run #2 after merge PR #8: **failed** — Python 3.9 not available on Ubuntu 20.04 runner (annotation); requires runner/image fix.*

### 9. Lab quota extension request

![Prayogshala lab extension](../Screenshots%20and%20Video/Screenshot%202026-11-24%20202952.png)

*Figure 30 — DevOps lab (Docker, Git, Jenkins, SonarQube stack): **92% quota used**; extension request submitted for Assignment 2 completion.*

---

## Screenshot index (file name → topic)

| File | Topic |
|------|--------|
| `Screenshot 2026-11-24 185250.png` | GitHub repo home |
| `Screenshot 2026-11-24 185356.png` | Commit history |
| `Screenshot 2026-11-24 185444.png` | Closed pull requests |
| `Screenshot 2026-11-24 190610.png` | `git clone` on VM |
| `Screenshot 2026-11-24 190639.png` | Project folder listing |
| `Screenshot 2026-11-24 190854.png` | venv + dependencies |
| `Screenshot 2026-11-24 191120.png` | Pytest 8/8 passed |
| `Screenshot 2026-11-24 191551.png` | Flask `app.py` running |
| `Screenshot 2026-11-24 191629.png` | Flask access logs |
| `Screenshot 2026-11-24 191726.png` | Health API :5000 |
| `Screenshot 2026-11-24 192336.png` | Docker build/run/tests |
| `Screenshot 2026-11-24 192500.png` | Health API :5001 |
| `Screenshot 2026-11-24 193333.png` | Docker Hub command reference |
| `Screenshot 2026-11-24 193418.png` | Image list + login |
| `Screenshot 2026-11-24 194816.png` | Docker Hub push |
| `Screenshot 2026-11-24 195153.png` | Sonar CLI missing |
| `Screenshot 2026-11-24 195739.png` | Sonar wget 403 |
| `Screenshot 2026-11-24 201803.png` | Sonar PATH setup |
| `Screenshot 2026-11-24 202338.png` | Sonar bad host/token |
| `Screenshot 2026-11-24 202952.png` | Lab extension request |
| `Screenshot 2026-11-24 223324.png` | Sonar auth error |
| `Screenshot 2026-11-24 225420.png` | Sonar analysis OK |
| `Screenshot 2026-11-24 230340.png` | GHA Python 3.9 failure |
| `Picture1.png` | Jenkins pipeline graph |
| `Picture2.png` | Jenkins post-actions log |
| `Picture3.png` | Jenkins pipeline steps |
| `Picture4.png` | Jenkins login |
| `Picture5.png` | Jenkins new Pipeline job |
| `Picture6.png` | Jenkins build #2 summary |
| `Picture7.png` | GitHub Actions success |

---

## Video

No screen-recording file was found under `Screenshots and Video/` (PNG evidence only). If a demo video is recorded later, add it here:

```markdown
![Demo video](../Screenshots%20and%20Video/your-demo.mp4)
```

Or link an external upload (YouTube/Drive) in the deliverable DOCX.