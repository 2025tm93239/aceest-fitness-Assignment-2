# Linux VM — Assignment 2 runbook

Tested flow for BITS DevOps lab VM (Ubuntu + Python **3.9.21**).

Repo: `https://github.com/2025tm93239/aceest-fitness-Assignment-2`

## 0. One-time packages

```bash
sudo apt-get update
sudo apt-get install -y git python3-venv python3-pip docker.io

# optional but needed for assignment: minikube, kubectl
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

sudo usermod -aG docker "$USER"
newgrp docker
```

SonarQube (if your eval needs it): run the course SonarQube container or use the shared lab URL, then install scanner:

```bash
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
unzip sonar-scanner-cli-*-linux.zip
sudo mv sonar-scanner-*-linux /opt/sonar-scanner
echo 'export PATH="/opt/sonar-scanner/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## 1. Clone and run app

```bash
git clone https://github.com/2025tm93239/aceest-fitness-Assignment-2.git
cd aceest-fitness-Assignment-2

python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt

python3 app.py
# other terminal:
curl http://127.0.0.1:5000/
curl http://127.0.0.1:5000/programs
```

## 2. Pytest

```bash
source .venv/bin/activate
python3 -m pytest -v
```

Expected: **8 passed**.

Shortcut:

```bash
chmod +x scripts/linux-smoke-test.sh
./scripts/linux-smoke-test.sh
```

## 3. Docker

```bash
docker build -t aceest-fitness:latest .
docker run -d -p 5000:5000 --name aceest aceest-fitness:latest
curl http://127.0.0.1:5000/
docker exec aceest python3 -m pytest -v
docker stop aceest && docker rm aceest
```

## 4. Docker Hub (versioned images)

```bash
export DOCKERHUB_USER=your_user
docker login
docker tag aceest-fitness:latest ${DOCKERHUB_USER}/aceest-fitness:2.0.0
docker tag aceest-fitness:latest ${DOCKERHUB_USER}/aceest-fitness:latest
docker push ${DOCKERHUB_USER}/aceest-fitness:2.0.0
docker push ${DOCKERHUB_USER}/aceest-fitness:latest
```

Jenkins job env vars (Manage job → Configure):

- `DOCKER_PUSH=true`
- `DOCKERHUB_REPO=your_user/aceest-fitness`
- Credentials: `DOCKERHUB_USER`, `DOCKERHUB_PASS`

## 5. SonarQube scan (manual)

```bash
sonar-scanner -Dsonar.host.url=http://YOUR_SONAR_HOST:9000 -Dsonar.login=YOUR_TOKEN
```

Properties file is `sonar-project.properties` in repo root.

## 6. Minikube + Kubernetes

```bash
minikube start --driver=docker
chmod +x scripts/minikube-deploy.sh
./scripts/minikube-deploy.sh
```

Check pods:

```bash
kubectl get pods -n aceest
kubectl get svc -n aceest
minikube service aceest-api -n aceest --url
curl "$(minikube service aceest-api -n aceest --url)/"
```

### Other deployment YAMLs (demo)

```bash
kubectl apply -f k8s/deployment-blue-green.yaml
kubectl apply -f k8s/deployment-canary.yaml
kubectl apply -f k8s/deployment-shadow.yaml
kubectl apply -f k8s/deployment-ab.yaml
```

Blue-green switch (after green pods healthy):

```bash
kubectl patch svc aceest-blue-green -n aceest -p '{"spec":{"selector":{"color":"green"}}}'
```

Rollback rolling deploy:

```bash
kubectl rollout undo deployment/aceest-rolling -n aceest
```

## 7. Jenkins on VM

See `docs/JENKINS-SETUP.md`. Linux agent fix for docker:

```bash
sudo systemctl enable --now docker
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
sudo -u jenkins docker ps
```

Pipeline from SCM → branch `main` → script `Jenkinsfile`.

For Minikube deploy from Jenkins set `K8S_DEPLOY=true` on the job.

## 8. What to submit

- GitHub link (public)
- Cluster/service URL from `minikube service ... --url`
- Jenkins green build screenshot
- SonarQube dashboard screenshot
- Docker Hub tags screenshot
- `docs/Assignment2_Report.md` exported to PDF