# Kubernetes Deployment Guide for STM32-URAT

## What is Kubernetes?

Kubernetes (K8s) is an orchestration platform that:
- Manages containers across multiple machines
- Automatically scales applications
- Handles load balancing
- Provides self-healing (restarts failed containers)
- Manages storage and networking

## Files Created

1. **k8s-deployment.yaml** - Defines how to run your Docker container
2. **k8s-service.yaml** - Exposes your application to the network
3. **k8s-configmap.yaml** - Configuration data for your application

---

## Prerequisites

### Install Kubernetes Tools

**Windows PowerShell:**

```powershell
# Install Kubernetes CLI (kubectl)
choco install kubernetes-cli

# Or download from: https://kubernetes.io/docs/tasks/tools/

# Verify installation
kubectl version --client
```

### Set up Kubernetes Cluster

**Option 1: Docker Desktop (Easiest)**
- Open Docker Desktop
- Settings → Kubernetes → Enable Kubernetes
- Wait for it to start

**Option 2: Minikube (For learning)**
```powershell
choco install minikube

minikube start

# Use Docker inside minikube
minikube docker-env
```

**Option 3: Cloud Kubernetes**
- AWS EKS
- Google GKE
- Azure AKS

---

## Step-by-Step Deployment

### Step 1: Verify Your Image is Available

```powershell
docker images | findstr stm32-urat
```

If not found, rebuild:
```powershell
docker build -t stm32-urat:latest .
```

### Step 2: Deploy to Kubernetes

```powershell
# Apply the deployment
kubectl apply -f k8s-deployment.yaml

# Check deployment status
kubectl get deployment stm32-urat-deployment

# Watch pods being created
kubectl get pods -w

# See detailed pod information
kubectl describe pod <pod-name>
```

### Step 3: Create the Service

```powershell
# Apply the service
kubectl apply -f k8s-service.yaml

# Check service status
kubectl get service stm32-urat-service

# Get the external IP (may take a minute)
kubectl get svc stm32-urat-service --watch
```

### Step 4: Access Your Application

```powershell
# Get the external IP or port
kubectl get svc stm32-urat-service

# For LoadBalancer: Use the EXTERNAL-IP
# Example: http://192.168.1.100:8000

# For NodePort: Use node IP + NodePort
# Example: http://localhost:30001

# For ClusterIP: Port-forward instead
kubectl port-forward service/stm32-urat-service 8000:8000
# Then access: http://localhost:8000
```

---

## Understanding the YAML Files

### k8s-deployment.yaml

```yaml
replicas: 3  # Number of copies running
```
- Creates 3 identical containers
- If one fails, Kubernetes restarts it
- Distributes load across 3 pods

```yaml
imagePullPolicy: Never
```
- Uses local Docker image
- Change to `IfNotPresent` to pull from registry

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```
- **Requests** - Resources needed to start
- **Limits** - Maximum resources allowed
- Kubernetes won't schedule if resources unavailable

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 8000
```
- Checks if container is alive
- Restarts if unhealthy

### k8s-service.yaml

```yaml
type: LoadBalancer
```
- **LoadBalancer** - External IP (for cloud)
- **NodePort** - Fixed port on each node
- **ClusterIP** - Internal only (default)

---

## Common kubectl Commands

```powershell
# View deployments
kubectl get deployments

# View pods (containers)
kubectl get pods

# View services
kubectl get svc

# View everything
kubectl get all

# Describe a resource (detailed info)
kubectl describe deployment stm32-urat-deployment
kubectl describe service stm32-urat-service

# View logs from a pod
kubectl logs <pod-name>

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/bash

# Port forward (access container)
kubectl port-forward pod/<pod-name> 8000:8000

# Scale deployment (change replicas)
kubectl scale deployment stm32-urat-deployment --replicas=5

# Delete deployment
kubectl delete deployment stm32-urat-deployment

# Delete service
kubectl delete service stm32-urat-service

# Delete using yaml file
kubectl delete -f k8s-deployment.yaml
kubectl delete -f k8s-service.yaml

# Watch resources in real-time
kubectl get pods -w
```

---

## Complete Deployment Steps (Copy & Paste)

```powershell
# 1. Check kubectl is configured
kubectl cluster-info

# 2. Deploy your application
kubectl apply -f k8s-deployment.yaml
kubectl apply -f k8s-service.yaml

# 3. Check status
kubectl get all

# 4. Watch pods starting
kubectl get pods -w

# 5. Get service IP/Port
kubectl get svc stm32-urat-service

# 6. Access the app
# Open browser: http://<EXTERNAL-IP>:8000
```

---

## Troubleshooting

### Pods not starting?

```powershell
# Check pod status
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>

# Check if image exists locally
docker images | findstr stm32-urat
```

### Service shows pending external IP?

```powershell
# For Docker Desktop, use localhost:port
kubectl port-forward service/stm32-urat-service 8000:8000

# Then access: http://localhost:8000
```

### ImagePullBackOff error?

The image can't be found. Solutions:
```powershell
# Option 1: Rebuild the image
docker build -t stm32-urat:latest .

# Option 2: Change imagePullPolicy in deployment.yaml to "Never"
# (Already done in our file)

# Option 3: Push to Docker Hub and change image path
docker tag stm32-urat:latest yourname/stm32-urat:latest
docker push yourname/stm32-urat:latest
# Then update image: in deployment.yaml
```

---

## Production Best Practices

1. **Use specific image tags** (not `latest`)
   ```yaml
   image: stm32-urat:v1.0
   ```

2. **Set resource requests/limits** (already done)

3. **Use health checks** (already done)

4. **Use Secrets for sensitive data**
   ```powershell
   kubectl create secret generic db-credentials --from-literal=password=mysecret
   ```

5. **Use ConfigMaps for configuration** (we created one)

6. **Enable RBAC** for security

7. **Use namespaces** to organize apps
   ```powershell
   kubectl create namespace production
   kubectl apply -f k8s-deployment.yaml -n production
   ```

---

## Summary

| Command | Purpose |
|---------|---------|
| `kubectl apply -f file.yaml` | Deploy to Kubernetes |
| `kubectl get pods` | List running containers |
| `kubectl logs pod-name` | View container output |
| `kubectl delete -f file.yaml` | Remove deployment |
| `kubectl port-forward` | Access container locally |

Your STM32-URAT application is now ready for Kubernetes deployment!
