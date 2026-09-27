# Démo K8s : to-do list (backend Java + frontend JS)

- **backend/** : API REST Spring Boot (Java 21) — liste de tâches en mémoire.
- **frontend/** : page HTML/JS statique servie par nginx, qui proxy les appels
  `/api/...` vers le service `backend-svc` à l'intérieur du cluster.
- **k8s/** : manifestes Kubernetes (namespace, Deployments, Services).

## Prérequis sur ta machine Windows

Docker Desktop installé (pour builder les images) et un compte sur un
registre d'images (Docker Hub est le plus simple : https://hub.docker.com,
gratuit).

## 1. Builder et pousser les images

Depuis le dossier `k8s-demo-app`, remplace `TON_USER_DOCKERHUB` par ton
identifiant Docker Hub partout ci-dessous :

```powershell
docker login

docker build -t TON_USER_DOCKERHUB/k8s-demo-backend:1.0 ./backend
docker push TON_USER_DOCKERHUB/k8s-demo-backend:1.0

docker build -t TON_USER_DOCKERHUB/k8s-demo-frontend:1.0 ./frontend
docker push TON_USER_DOCKERHUB/k8s-demo-frontend:1.0
```

## 2. Adapter les manifestes

Dans `k8s/backend.yaml` et `k8s/frontend.yaml`, remplace `REGISTRY_USER` par
ton identifiant Docker Hub (même valeur que ci-dessus), par exemple :

```
image: TON_USER_DOCKERHUB/k8s-demo-backend:1.0
```

## 3. Déployer sur le cluster

Depuis le dossier `k8s-demo-app`, avec ton kubeconfig du cluster kubeadm :

```powershell
kubectl --kubeconfig=..\terraform-k8s-azure-v2\kubeconfig apply -f k8s/namespace.yaml
kubectl --kubeconfig=..\terraform-k8s-azure-v2\kubeconfig apply -f k8s/backend.yaml
kubectl --kubeconfig=..\terraform-k8s-azure-v2\kubeconfig apply -f k8s/frontend.yaml
```

(adapte le chemin vers ton fichier `kubeconfig` si besoin)

## 4. Vérifier

```powershell
kubectl --kubeconfig=...\kubeconfig -n demo-app get pods,svc
```

Les pods `backend-xxx` et `frontend-xxx` doivent passer en `Running`.

## 5. Accéder à l'application

Le frontend est exposé en NodePort 30080 sur les 3 nœuds. Ouvre dans ton
navigateur, en remplaçant par l'IP publique d'un de tes nœuds (master ou
worker, peu importe) :

```
http://<IP_PUBLIQUE_D_UN_NOEUD>:30080
```

Le port 30080 est déjà autorisé dans le NSG Azure (plage NodePort
30000-32767 ouverte à ton IP), donc pas de configuration réseau
supplémentaire nécessaire.

## Mettre à jour l'application

Après une modification du code : rebuild + push l'image concernée avec un
nouveau tag (ou le même tag suivi de `kubectl rollout restart deployment/backend -n demo-app`
pour forcer les pods à re-tirer l'image).
