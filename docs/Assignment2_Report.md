# Assignment 2 Report — ACEest CI/CD

**Student:** _(your name)_  
**BITS ID:** _(id)_  
**Repo:** https://github.com/2025tm93239/aceest-fitness-Assignment-2

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

## Outcomes

- 8 automated tests on every build  
- Docker image is reproducible (`python:3.9-slim`, gunicorn)  
- Multiple k8s manifests ready for strategy demonstration  
- Jenkins can push tagged images when `DOCKER_PUSH=true`

## Evidence checklist

- [ ] GitHub commit history  
- [ ] Jenkins successful build  
- [ ] SonarQube project dashboard  
- [ ] Docker Hub repository tags  
- [ ] `minikube service` URL responds with JSON health  

---

_Export this file to PDF/Word for portal upload (2–3 pages with screenshots)._