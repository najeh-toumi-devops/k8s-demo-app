#!/bin/bash
# À exécuter SUR LE MASTER (k8sm), depuis le dossier k8s-demo-app une fois copié dessus.
# Usage: sudo bash deploy.sh
set -euxo pipefail

NERDCTL_VERSION="1.7.7"
BUILDKIT_VERSION="0.15.2"
BUILDKIT_SOCK="unix:///run/buildkit/buildkitd.sock"

# --- 1. Installer nerdctl si absent -----------------------------------------
if ! command -v nerdctl &>/dev/null; then
  echo ">>> Installation de nerdctl..."
  wget -O /tmp/nerdctl.tar.gz \
    "https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz"
  tar -C /usr/local/bin -xzf /tmp/nerdctl.tar.gz nerdctl
fi

# --- 2. Installer buildkit si absent -----------------------------------------
if ! command -v buildkitd &>/dev/null; then
  echo ">>> Installation de buildkit..."
  wget -O /tmp/buildkit.tar.gz \
    "https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/buildkit-v${BUILDKIT_VERSION}.linux-amd64.tar.gz"
  tar -C /usr/local -xzf /tmp/buildkit.tar.gz
fi

# --- 3. Démarrer buildkitd s'il ne tourne pas déjà ---------------------------
mkdir -p /run/buildkit
if ! pgrep -f buildkitd >/dev/null; then
  echo ">>> Démarrage de buildkitd..."
  nohup buildkitd --containerd-worker=true --containerd-worker-namespace=k8s.io \
    --addr "${BUILDKIT_SOCK}" > /var/log/buildkitd.log 2>&1 &
  sleep 3
fi

buildctl --addr "${BUILDKIT_SOCK}" debug workers

# --- 4. Builder les 2 images directement dans le containerd du cluster ------
echo ">>> Build backend..."
BUILDKIT_HOST="${BUILDKIT_SOCK}" nerdctl --namespace k8s.io build -t k8s-demo-backend:1.0 ./backend

echo ">>> Build frontend..."
BUILDKIT_HOST="${BUILDKIT_SOCK}" nerdctl --namespace k8s.io build -t k8s-demo-frontend:1.0 ./frontend

nerdctl --namespace k8s.io images | grep k8s-demo

# --- 5. Déployer sur le cluster ----------------------------------------------
# Le build (étapes 1-4) a besoin de root, mais kubectl doit utiliser le
# ~/.kube/config de l'utilisateur qui a lancé le script (via sudo), pas celui
# de root qui n'en a pas.
echo ">>> Déploiement Kubernetes..."
TARGET_USER="${SUDO_USER:-$USER}"
sudo -u "${TARGET_USER}" kubectl apply -f k8s/namespace.yaml
sudo -u "${TARGET_USER}" kubectl apply -f k8s/backend.yaml
sudo -u "${TARGET_USER}" kubectl apply -f k8s/frontend.yaml

echo ">>> Terminé. Vérifie avec: kubectl -n demo-app get pods,svc -o wide"
