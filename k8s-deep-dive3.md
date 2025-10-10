# Kubernetes Deep Dive Guide: Basic to Advanced

## Table of Contents
- [I. Basic Concepts](#i-basic-concepts)
- [II. Intermediate Concepts](#ii-intermediate-concepts)
- [III. Advanced Concepts](#iii-advanced-concepts)
- [IV. References](#iv-references)

---

## I. Basic Concepts

### 1. Introduction to Kubernetes

#### What is Kubernetes?
Kubernetes (K8s) is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications. It was originally designed by Google and is now maintained by the Cloud Native Computing Foundation (CNCF).

#### Why Kubernetes?
- **Automatic scaling**: Scale applications up or down based on demand
- **Self-healing**: Automatically restarts failed containers and replaces nodes
- **Load balancing**: Distributes traffic across containers
- **Rolling updates**: Deploy new versions without downtime
- **Service discovery**: Automatic DNS and load balancing for services
- **Storage orchestration**: Automatically mount local or cloud storage
- **Declarative configuration**: Define desired state, Kubernetes maintains it

#### Key Features and Benefits
- **Platform agnostic**: Runs on-premises, cloud, or hybrid environments
- **Portable**: Works across AWS, Azure, GCP, and bare metal
- **Extensible**: Add custom features through APIs
- **Large ecosystem**: Rich tooling and community support

---

### 2. Kubernetes Architecture

#### Control Plane Components

**kube-apiserver**
- The API server is the front end for the Kubernetes control plane
- Exposes the Kubernetes API
- All operations go through the API server
- Validates and processes REST requests

**etcd**
- Consistent and highly-available key-value store
- Stores all cluster data (configuration, state, metadata)
- Acts as Kubernetes' backing store

**kube-scheduler**
- Watches for newly created Pods with no assigned node
- Selects a node for them to run on based on:
  - Resource requirements
  - Hardware/software constraints
  - Affinity/anti-affinity specifications
  - Data locality

**kube-controller-manager**
- Runs controller processes
- Controllers include:
  - Node Controller: Monitors node health
  - Replication Controller: Maintains correct number of pods
  - Endpoints Controller: Populates Endpoints objects
  - Service Account Controller: Creates default accounts for namespaces

**cloud-controller-manager**
- Runs controllers specific to cloud providers
- Integrates Kubernetes with cloud provider APIs
- Manages load balancers, routes, and volumes

#### Node Components

**kubelet**
- Agent that runs on each node
- Ensures containers are running in Pods
- Takes PodSpecs and ensures containers described are running and healthy
- Doesn't manage containers not created by Kubernetes

**kube-proxy**
- Network proxy running on each node
- Maintains network rules for Pod communication
- Implements part of the Service concept
- Can use iptables, IPVS, or userspace proxy mode

**Container Runtime**
- Software responsible for running containers
- Supports containerd, CRI-O, Docker Engine (via dockershim in older versions)
- Must implement the Kubernetes Container Runtime Interface (CRI)

#### Cluster Communication
- All communication flows through the API server
- Components communicate using the API server's REST API
- Secured using TLS certificates
- Nodes communicate with control plane via kubelet

---

### 3. Kubernetes Objects

#### Overview of Kubernetes Objects
Kubernetes objects are persistent entities that represent:
- Running containerized applications
- Available resources for applications
- Policies around application behavior (restart, upgrades, fault-tolerance)

Every Kubernetes object includes:
- **Object Spec**: Describes desired state (you provide)
- **Object Status**: Current state (Kubernetes provides)

Common object fields:
- `apiVersion`: Kubernetes API version
- `kind`: Type of object (Pod, Service, Deployment, etc.)
- `metadata`: Data to identify the object (name, namespace, labels)
- `spec`: Desired state of the object

#### YAML for Object Definition

Basic structure:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  namespace: default
  labels:
    app: my-app
    environment: production
  annotations:
    description: "My application pod"
spec:
  # Object specification goes here
```

**Key YAML Concepts:**
- Indentation matters (use spaces, not tabs)
- Hyphens (-) denote list items
- Key-value pairs separated by colons
- Strings can be quoted or unquoted

---

### 4. Pods

#### What is a Pod?
- Smallest deployable unit in Kubernetes
- Encapsulates one or more containers
- Containers in a Pod share:
  - Network namespace (IP address and ports)
  - Storage volumes
  - IPC namespace
- Usually one container per Pod (single-container Pod)
- Multiple containers share resources (multi-container Pod)

#### Pod Lifecycle

**Pod Phases:**
1. **Pending**: Pod accepted but containers not yet running
2. **Running**: Pod bound to node, all containers created
3. **Succeeded**: All containers terminated successfully
4. **Failed**: All containers terminated, at least one failed
5. **Unknown**: Pod state cannot be determined

**Container States:**
- **Waiting**: Container not yet running (pulling image, applying secrets)
- **Running**: Container executing without issues
- **Terminated**: Container finished execution or failed

**Pod Conditions:**
- `PodScheduled`: Pod scheduled to a node
- `ContainersReady`: All containers in Pod are ready
- `Initialized`: All init containers completed successfully
- `Ready`: Pod able to serve requests

#### Multi-container Pods (Sidecar Pattern)

Common patterns:
- **Sidecar**: Helper container (logging, monitoring)
- **Ambassador**: Proxy container for external services
- **Adapter**: Standardizes output from main container

#### Hands-on: Deploying a Simple Pod

**Example 1: Single Container Pod**

```yaml
# simple-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
```

**Deploy the Pod:**
```bash
# Create the Pod
kubectl apply -f simple-pod.yaml

# Check Pod status
kubectl get pods

# Get detailed Pod information
kubectl describe pod nginx-pod

# View Pod logs
kubectl logs nginx-pod

# Execute command in Pod
kubectl exec -it nginx-pod -- /bin/bash

# Delete the Pod
kubectl delete pod nginx-pod
```

**Example 2: Multi-container Pod (Sidecar Pattern)**

```yaml
# multi-container-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-sidecar
spec:
  containers:
  - name: main-app
    image: nginx:1.21
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx
  
  - name: log-sidecar
    image: busybox:1.33
    command: ['sh', '-c', 'tail -f /var/log/nginx/access.log']
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx
  
  volumes:
  - name: shared-logs
    emptyDir: {}
```

**Deploy and test:**
```bash
# Create the multi-container Pod
kubectl apply -f multi-container-pod.yaml

# Check both containers are running
kubectl get pod app-with-sidecar

# View logs from main container
kubectl logs app-with-sidecar -c main-app

# View logs from sidecar
kubectl logs app-with-sidecar -c log-sidecar

# Execute command in specific container
kubectl exec -it app-with-sidecar -c main-app -- /bin/bash
```

**Example 3: Pod with Init Containers**

```yaml
# pod-with-init.yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  initContainers:
  - name: install
    image: busybox:1.33
    command: ['sh', '-c', 'echo "Initializing..." && sleep 5']
  
  containers:
  - name: main-app
    image: nginx:1.21
    ports:
    - containerPort: 80
```

**Init containers run before main containers and must complete successfully.**

```bash
# Watch the Pod initialization
kubectl apply -f pod-with-init.yaml
kubectl get pod init-demo -w

# Check init container logs
kubectl logs init-demo -c install
```

**Example 4: Pod with Resource Limits**

```yaml
# pod-with-resources.yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
  - name: app
    image: nginx:1.21
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
    ports:
    - containerPort: 80
```

**Resource units:**
- CPU: 1000m = 1 CPU core
- Memory: Ki, Mi, Gi (Kibibytes, Mebibytes, Gibibytes)

```bash
# Apply the Pod
kubectl apply -f pod-with-resources.yaml

# View resource usage
kubectl top pod resource-demo

# Describe to see resource allocation
kubectl describe pod resource-demo
```

---

### 5. Workloads

#### Deployments (Managing Stateless Applications)

**What is a Deployment?**
- Manages a replicated application
- Provides declarative updates for Pods and ReplicaSets
- Ensures specified number of Pod replicas are running
- Handles rolling updates and rollbacks

**Key Features:**
- Rolling updates with zero downtime
- Rollback to previous versions
- Scaling up or down
- Pausing and resuming deployments

#### ReplicaSets (Ensuring Desired Number of Pods)

**What is a ReplicaSet?**
- Maintains a stable set of replica Pods
- Ensures specified number of Pods are running at any time
- Usually created automatically by Deployments
- Uses label selectors to identify Pods to manage

**Note:** You typically don't create ReplicaSets directly; use Deployments instead.

#### Hands-on: Creating a Deployment

**Example 1: Basic Deployment**

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
```

**Deploy and manage:**
```bash
# Create Deployment
kubectl apply -f nginx-deployment.yaml

# Check Deployment status
kubectl get deployments
kubectl get rs  # ReplicaSet created by Deployment
kubectl get pods

# Get detailed information
kubectl describe deployment nginx-deployment

# Scale the Deployment
kubectl scale deployment nginx-deployment --replicas=5

# Check scaling
kubectl get pods -w

# Update the Deployment (rolling update)
kubectl set image deployment/nginx-deployment nginx=nginx:1.22

# Check rollout status
kubectl rollout status deployment/nginx-deployment

# View rollout history
kubectl rollout history deployment/nginx-deployment

# Rollback to previous version
kubectl rollout undo deployment/nginx-deployment

# Rollback to specific revision
kubectl rollout undo deployment/nginx-deployment --to-revision=1
```

**Example 2: Deployment with Rolling Update Strategy**

```yaml
# deployment-with-strategy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max pods above desired count during update
      maxUnavailable: 1  # Max pods unavailable during update
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web
        image: nginx:1.21
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
```

**Probes explained:**
- **Liveness Probe**: Checks if container is alive (restarts if fails)
- **Readiness Probe**: Checks if container is ready to serve traffic
- **Startup Probe**: Checks if application has started (for slow-starting containers)

```bash
# Apply deployment
kubectl apply -f deployment-with-strategy.yaml

# Watch the rollout
kubectl rollout status deployment/web-app

# Pause a rollout
kubectl rollout pause deployment/web-app

# Resume a rollout
kubectl rollout resume deployment/web-app
```

#### DaemonSets (Running a Pod on All/Selected Nodes)

**What is a DaemonSet?**
- Ensures all (or some) nodes run a copy of a Pod
- As nodes are added, Pods are added automatically
- Common uses: log collectors, monitoring agents, network plugins

**Example: DaemonSet**

```yaml
# daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-daemonset
  labels:
    app: fluentd
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      containers:
      - name: fluentd
        image: fluentd:v1.14
        volumeMounts:
        - name: varlog
          mountPath: /var/log
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
```

```bash
# Create DaemonSet
kubectl apply -f daemonset.yaml

# Check DaemonSet
kubectl get daemonsets
kubectl get pods -l app=fluentd -o wide

# DaemonSet with node selector (runs only on specific nodes)
```

**DaemonSet with Node Selector:**

```yaml
# daemonset-node-selector.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: monitoring-agent
spec:
  selector:
    matchLabels:
      app: monitoring
  template:
    metadata:
      labels:
        app: monitoring
    spec:
      nodeSelector:
        environment: production  # Only runs on nodes with this label
      containers:
      - name: agent
        image: monitoring-agent:v1
```

#### StatefulSets (Managing Stateful Applications)

**What is a StatefulSet?**
- Manages stateful applications
- Provides guarantees about ordering and uniqueness of Pods
- Each Pod has persistent identifier maintained across rescheduling
- Suitable for databases, distributed systems

**Key Features:**
- Stable network identity
- Stable persistent storage
- Ordered deployment and scaling
- Ordered automated rolling updates

**Example: StatefulSet**

```yaml
# statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-stateful
spec:
  serviceName: "nginx-service"
  replicas: 3
  selector:
    matchLabels:
      app: nginx-stateful
  template:
    metadata:
      labels:
        app: nginx-stateful
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

**Headless Service for StatefulSet:**

```yaml
# headless-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  clusterIP: None  # Headless service
  selector:
    app: nginx-stateful
  ports:
  - port: 80
    name: web
```

```bash
# Create headless service first
kubectl apply -f headless-service.yaml

# Create StatefulSet
kubectl apply -f statefulset.yaml

# Watch Pods being created in order
kubectl get pods -w

# Notice Pod names: web-stateful-0, web-stateful-1, web-stateful-2

# Check PersistentVolumeClaims
kubectl get pvc

# Scale StatefulSet
kubectl scale statefulset web-stateful --replicas=5

# Delete StatefulSet (keeps PVCs)
kubectl delete statefulset web-stateful

# Check PVCs still exist
kubectl get pvc
```

#### Jobs and CronJobs (Batch Processing)

**Jobs**
- Creates one or more Pods
- Ensures specified number complete successfully
- Tracks successful completions

**Example: Job**

```yaml
# job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-job
spec:
  completions: 5      # Number of successful completions needed
  parallelism: 2      # Number of Pods running in parallel
  template:
    spec:
      containers:
      - name: worker
        image: busybox:1.33
        command: ['sh', '-c', 'echo "Processing batch job" && sleep 30']
      restartPolicy: OnFailure
```

```bash
# Create Job
kubectl apply -f job.yaml

# Watch Job progress
kubectl get jobs -w

# Get Pods created by Job
kubectl get pods

# View Job logs
kubectl logs -l job-name=batch-job

# Delete Job
kubectl delete job batch-job
```

**CronJobs**
- Creates Jobs on a schedule
- Uses Cron format for scheduling

**Example: CronJob**

```yaml
# cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: scheduled-job
spec:
  schedule: "*/5 * * * *"  # Every 5 minutes
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: worker
            image: busybox:1.33
            command: ['sh', '-c', 'date; echo "Running scheduled task"']
          restartPolicy: OnFailure
```

**Cron schedule format:**
```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
│ │ │ │ │
* * * * *
```

**Examples:**
- `0 0 * * *` - Every day at midnight
- `*/15 * * * *` - Every 15 minutes
- `0 */2 * * *` - Every 2 hours

```bash
# Create CronJob
kubectl apply -f cronjob.yaml

# List CronJobs
kubectl get cronjobs

# View Jobs created by CronJob
kubectl get jobs

# View CronJob details
kubectl describe cronjob scheduled-job

# Manually trigger a CronJob
kubectl create job --from=cronjob/scheduled-job manual-trigger

# Delete CronJob
kubectl delete cronjob scheduled-job
```

---

## II. Intermediate Concepts

### 1. Services, Load Balancing, and Networking

#### Services (Exposing Applications)

**What is a Service?**
- Abstracts access to a set of Pods
- Provides stable endpoint (IP and DNS name)
- Load balances traffic across Pods
- Enables service discovery

**Service Types:**

**1. ClusterIP (Default)**
- Exposes Service on cluster-internal IP
- Only accessible within cluster
- Use for internal communication

**2. NodePort**
- Exposes Service on each Node's IP at a static port
- Accessible from outside cluster
- Port range: 30000-32767

**3. LoadBalancer**
- Creates external load balancer (cloud provider)
- Assigns external IP to Service
- Routes external traffic to Service

**4. ExternalName**
- Maps Service to DNS name
- Returns CNAME record
- No proxying, just DNS resolution

#### Hands-on: Service Examples

**Example 1: ClusterIP Service**

```yaml
# clusterip-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 80        # Service port
    targetPort: 8080 # Pod port
```

**Deploy backend application:**

```yaml
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: app
        image: hashicorp/http-echo:0.2.3
        args:
        - "-text=Hello from backend"
        ports:
        - containerPort: 8080
```

```bash
# Create Deployment and Service
kubectl apply -f backend-deployment.yaml
kubectl apply -f clusterip-service.yaml

# Check Service
kubectl get svc backend-service

# Get Service details
kubectl describe svc backend-service

# Test Service from within cluster
kubectl run test-pod --image=busybox:1.33 --rm -it --restart=Never -- sh
# Inside the pod:
wget -qO- backend-service
```

**Example 2: NodePort Service**

```yaml
# nodeport-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080  # Optional: specify port, or let K8s assign
```

```bash
# Create NodePort Service
kubectl apply -f nodeport-service.yaml

# Get node IP
kubectl get nodes -o wide

# Access service
# http://<NODE_IP>:30080
```

**Example 3: LoadBalancer Service**

```yaml
# loadbalancer-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

```bash
# Create LoadBalancer Service (requires cloud provider)
kubectl apply -f loadbalancer-service.yaml

# Get external IP (may take a few minutes)
kubectl get svc web-loadbalancer -w

# Access via external IP
# http://<EXTERNAL_IP>
```

**Example 4: Headless Service**

```yaml
# headless-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: database-headless
spec:
  clusterIP: None  # Headless
  selector:
    app: database
  ports:
  - port: 5432
```

Headless services return Pod IPs directly (no load balancing), useful for StatefulSets.

#### Ingress (External Access to Services)

**What is Ingress?**
- Manages external HTTP/HTTPS access to Services
- Provides URL routing, SSL/TLS termination, name-based virtual hosting
- Requires Ingress Controller (nginx, traefik, etc.)

**Example: Basic Ingress**

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

**Example: Ingress with Multiple Paths**

```yaml
# multi-path-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

**Example: Ingress with TLS**

```yaml
# tls-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: secure-ingress
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: tls-secret  # Contains TLS certificate
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

```bash
# Install NGINX Ingress Controller (for testing)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Create Ingress
kubectl apply -f ingress.yaml

# Check Ingress
kubectl get ingress

# Describe Ingress
kubectl describe ingress web-ingress

# Test (add entry to /etc/hosts or use IP)
curl http://myapp.example.com
```

#### DNS in Kubernetes

**Service DNS Format:**
```
<service-name>.<namespace>.svc.cluster.local
```

**Pod DNS Format:**
```
<pod-ip-with-dashes>.<namespace>.pod.cluster.local
```

**Examples:**
```bash
# Service in same namespace
backend-service

# Service in different namespace
backend-service.production

# Fully qualified domain name
backend-service.production.svc.cluster.local
```

**Testing DNS:**

```bash
# Create test pod
kubectl run dnsutils --image=gcr.io/kubernetes-e2e-test-images/dnsutils:1.3 --rm -it --restart=Never -- sh

# Inside pod, test DNS
nslookup backend-service
nslookup backend-service.default.svc.cluster.local
```

#### Network Policies

**What are Network Policies?**
- Control traffic flow between Pods
- Define ingress (incoming) and egress (outgoing) rules
- Implemented by network plugins (Calico, Cilium, Weave)

**Example: Deny All Ingress**

```yaml
# deny-all-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: production
spec:
  podSelector: {}  # Applies to all Pods
  policyTypes:
  - Ingress
```

**Example: Allow from Specific Pods**

```yaml
# allow-from-frontend.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-frontend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

**Example: Allow from Specific Namespace**

```yaml
# allow-from-namespace.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-monitoring
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 5432
```

**Example: Egress Policy**

```yaml
# egress-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: egress-policy
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53  # Allow DNS
```

```bash
# Apply Network Policy
kubectl apply -f deny-all-ingress.yaml

# Test connectivity (should be blocked)
kubectl run test --image=busybox --rm -it --restart=Never -- wget -qO- backend-service

# Apply allow policy
kubectl apply -f allow-from-frontend.yaml

# Label a pod as frontend
kubectl run frontend --image=busybox --labels="app=frontend" --rm -it --restart=Never -- wget -qO- backend-service
```

#### Hands-on: Exposing a Deployment with Service and Ingress

**Complete Example:**

```yaml
# complete-app.yaml
---
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80

---
# Service
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80

---
# Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: web.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

```bash
# Deploy complete application
kubectl apply -f complete-app.yaml

# Verify Deployment
kubectl get deployments
kubectl get pods

# Verify Service
kubectl get svc web-service

# Verify Ingress
kubectl get ingress web-ingress

# Test access
# Add to /etc/hosts: <INGRESS_IP> web.example.com
curl http://web.example.com
```

---

### 2. Storage

#### Volumes (Ephemeral and Persistent)

**Ephemeral Volumes:**
- Exist for Pod lifetime
- Deleted when Pod is removed
- Types: emptyDir, configMap, secret

**Persistent Volumes:**
- Exist beyond Pod lifetime
- Independent lifecycle from Pods
- Types: PersistentVolume (PV), PersistentVolumeClaim (PVC)

**Example: emptyDir Volume**

```yaml
# emptydir-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-demo
spec:
  containers:
  - name: writer
    image: busybox:1.33
    command: ['sh', '-c', 'while true; do echo $(date) >> /data/log.txt; sleep 5; done']
    volumeMounts:
    - name: cache-volume
      mountPath: /data
  
  - name: reader
    image: busybox:1.33
    command: ['sh', '-c', 'tail -f /data/log.txt']
    volumeMounts:
    - name: cache-volume
      mountPath: /data
  
  volumes:
  - name: cache-volume
    emptyDir: {}
```

```bash
# Create Pod with emptyDir
kubectl apply -f emptydir-pod.yaml

# View logs from reader container
kubectl logs emptydir-demo -c reader -f
```

**Example: hostPath Volume**

```yaml
# hostpath-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-demo
spec:
  containers:
  - name: app
    image: nginx:1.21
    volumeMounts:
    - name: host-volume
      mountPath: /usr/share/nginx/html
  
  volumes:
  - name: host-volume
    hostPath:
      path: /data/web-content
      type: DirectoryOrCreate
```

**Warning:** hostPath volumes are not recommended for production as they tie Pods to specific nodes.

#### PersistentVolumes (PV) and PersistentVolumeClaims (PVC)

**PersistentVolume (PV):**
- Storage resource in cluster
- Provisioned by admin or dynamically via StorageClass
- Independent lifecycle

**PersistentVolumeClaim (PVC):**
- Request for storage by user
- Claims consume PV resources
- Can request specific size and access modes

**Access Modes:**
- **ReadWriteOnce (RWO)**: Mounted read-write by single node
- **ReadOnlyMany (ROX)**: Mounted read-only by many nodes
- **ReadWriteMany (RWX)**: Mounted read-write by many nodes
- **ReadWriteOncePod (RWOP)**: Mounted read-write by single pod (K8s 1.22+)

**Example: PersistentVolume**

```yaml
# persistent-volume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-example
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data
```

**Reclaim Policies:**
- **Retain**: Manual reclamation (data preserved)
- **Delete**: Delete PV and underlying storage
- **Recycle**: Basic scrub (deprecated)

**Example: PersistentVolumeClaim**

```yaml
# persistent-volume-claim.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-example
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
  storageClassName: manual
```

**Example: Pod using PVC**

```yaml
# pod-with-pvc.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pvc-demo
spec:
  containers:
  - name: app
    image: nginx:1.21
    volumeMounts:
    - name: persistent-storage
      mountPath: /usr/share/nginx/html
  
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: pvc-example
```

```bash
# Create PV and PVC
kubectl apply -f persistent-volume.yaml
kubectl apply -f persistent-volume-claim.yaml

# Check PV and PVC status
kubectl get pv
kubectl get pvc

# PVC should be bound to PV
kubectl describe pvc pvc-example

# Create Pod using PVC
kubectl apply -f pod-with-pvc.yaml

# Verify Pod is running
kubectl get pod pvc-demo

# Write data to persistent volume
kubectl exec pvc-demo -- sh -c 'echo "Hello Persistent World" > /usr/share/nginx/html/index.html'

# Delete and recreate Pod
kubectl delete pod pvc-demo
kubectl apply -f pod-with-pvc.yaml

# Data should persist
kubectl exec pvc-demo -- cat /usr/share/nginx/html/index.html
```

#### StorageClasses

**What is a StorageClass?**
- Defines storage provisioner and parameters
- Enables dynamic provisioning of PVs
- Administrators define different classes of storage (fast SSD, slow HDD, etc.)

**Example: StorageClass**

```yaml
# storage-class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
  replication-type: regional-pd
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

**Volume Binding Modes:**
- **Immediate**: PV created as soon as PVC is created
- **WaitForFirstConsumer**: PV created when Pod using PVC is scheduled

**Example: PVC with StorageClass**

```yaml
# pvc-with-storageclass.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fast-storage-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 10Gi
```

**Example: Local StorageClass (for testing)**

```yaml
# local-storage-class.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

```bash
# Create StorageClass
kubectl apply -f storage-class.yaml

# List StorageClasses
kubectl get storageclass

# Create PVC using StorageClass
kubectl apply -f pvc-with-storageclass.yaml

# Check PVC (may be Pending until Pod is created)
kubectl get pvc fast-storage-claim

# Set default StorageClass
kubectl patch storageclass fast-ssd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

#### Hands-on: Using Persistent Storage with StatefulSet

**Complete Example:**

```yaml
# statefulset-with-storage.yaml
---
# Headless Service
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
  - port: 3306
    name: mysql

---
# StorageClass
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: mysql-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer

---
# StatefulSet with PVC
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql-service
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpassword"
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: mysql-data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: mysql-storage
      resources:
        requests:
          storage: 5Gi
```

**For testing with local storage, create PVs:**

```yaml
# local-pvs.yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv-0
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: mysql-storage
  hostPath:
    path: /tmp/mysql-data-0

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv-1
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: mysql-storage
  hostPath:
    path: /tmp/mysql-data-1

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv-2
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: mysql-storage
  hostPath:
    path: /tmp/mysql-data-2
```

```bash
# Create PVs (for testing)
kubectl apply -f local-pvs.yaml

# Create StatefulSet with storage
kubectl apply -f statefulset-with-storage.yaml

# Watch StatefulSet creation
kubectl get pods -w

# Check PVCs created by StatefulSet
kubectl get pvc

# Verify each Pod has its own PVC
kubectl get pvc -l app=mysql

# Connect to MySQL pod
kubectl exec -it mysql-0 -- mysql -uroot -prootpassword

# Create database
CREATE DATABASE testdb;
USE testdb;
CREATE TABLE users (id INT, name VARCHAR(50));
INSERT INTO users VALUES (1, 'Alice');
SELECT * FROM users;
exit

# Delete Pod (data should persist)
kubectl delete pod mysql-0

# After Pod recreates, verify data
kubectl exec -it mysql-0 -- mysql -uroot -prootpassword -e "SELECT * FROM testdb.users;"
```

---

### 3. Configuration

#### ConfigMaps (Storing Non-confidential Data)

**What is a ConfigMap?**
- Stores configuration data as key-value pairs
- Decouples configuration from container images
- Can be consumed as environment variables, command-line arguments, or config files

**Creating ConfigMaps:**

**Method 1: From literal values**
```bash
kubectl create configmap app-config \
  --from-literal=APP_ENV=production \
  --from-literal=APP_DEBUG=false
```

**Method 2: From file**
```bash
# Create config file
cat > app.properties <<EOF
database.host=mysql.example.com
database.port=3306
database.name=myapp
EOF

kubectl create configmap app-config --from-file=app.properties
```

**Method 3: From directory**
```bash
kubectl create configmap app-config --from-file=config-dir/
```

**Method 4: Using YAML**

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: "production"
  APP_DEBUG: "false"
  database.host: "mysql.example.com"
  app.properties: |
    database.host=mysql.example.com
    database.port=3306
    database.name=myapp
    cache.enabled=true
```

**Using ConfigMaps in Pods:**

**Example 1: As Environment Variables**

```yaml
# pod-with-configmap-env.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-config
spec:
  containers:
  - name: app
    image: busybox:1.33
    command: ['sh', '-c', 'echo "Environment: $APP_ENV, Debug: $APP_DEBUG" && sleep 3600']
    env:
    - name: APP_ENV
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_ENV
    - name: APP_DEBUG
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_DEBUG
```

**Example 2: All keys as Environment Variables**

```yaml
# pod-with-configmap-envfrom.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-all-config
spec:
  containers:
  - name: app
    image: busybox:1.33
    command: ['sh', '-c', 'env && sleep 3600']
    envFrom:
    - configMapRef:
        name: app-config
```

**Example 3: As Volume Mount**

```yaml
# pod-with-configmap-volume.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-config-file
spec:
  containers:
  - name: app
    image: busybox:1.33
    command: ['sh', '-c', 'cat /config/app.properties && sleep 3600']
    volumeMounts:
    - name: config-volume
      mountPath: /config
  
  volumes:
  - name: config-volume
    configMap:
      name: app-config
      items:
      - key: app.properties
        path: app.properties
```

```bash
# Create ConfigMap
kubectl apply -f configmap.yaml

# Verify ConfigMap
kubectl get configmap app-config
kubectl describe configmap app-config

# Create Pods using ConfigMap
kubectl apply -f pod-with-configmap-env.yaml

# Check environment variables
kubectl logs app-with-config

# View ConfigMap as volume
kubectl apply -f pod-with-configmap-volume.yaml
kubectl exec app-with-config-file -- cat /config/app.properties

# Update ConfigMap
kubectl edit configmap app-config

# Note: Environment variables don't update automatically
# But volume-mounted configs update (with a delay)

# Delete ConfigMap
kubectl delete configmap app-config
```

#### Secrets (Storing Sensitive Data)

**What is a Secret?**
- Stores sensitive information (passwords, tokens, keys)
- Base64 encoded (not encrypted by default)
- Should be encrypted at rest using encryption provider

**Secret Types:**
- **Opaque**: Arbitrary user-defined data (default)
- **kubernetes.io/service-account-token**: Service account token
- **kubernetes.io/dockerconfigjson**: Docker registry credentials
- **kubernetes.io/tls**: TLS certificate and key
- **kubernetes.io/basic-auth**: Basic authentication credentials
- **kubernetes.io/ssh-auth**: SSH credentials

**Creating Secrets:**

**Method 1: From literal values**
```bash
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=SuperSecret123
```

**Method 2: From files**
```bash
echo -n 'admin' > username.txt
echo -n 'SuperSecret123' > password.txt

kubectl create secret generic db-secret \
  --from-file=username=username.txt \
  --from-file=password=password.txt
```

**Method 3: Using YAML**

```yaml
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  username: YWRtaW4=        # base64 encoded 'admin'
  password: U3VwZXJTZWNyZXQxMjM=  # base64 encoded 'SuperSecret123'
```

**Encoding/Decoding Base64:**
```bash
# Encode
echo -n 'admin' | base64

# Decode
echo 'YWRtaW4=' | base64 --decode
```

**Using Secrets in Pods:**

**Example 1: As Environment Variables**

```yaml
# pod-with-secret-env.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-secret
spec:
  containers:
  - name: app
    image: busybox:1.33
    command: ['sh', '-c', 'echo "User: $DB_USERNAME, Pass: $DB_PASSWORD" && sleep 3600']
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
```

**Example 2: As Volume Mount**

```yaml
# pod-with-secret-volume.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-secret-file
spec:
  containers:
  - name: app
    image: busybox:1.33
    command: ['sh', '-c', 'cat /secrets/username && cat /secrets/password && sleep 3600']
    volumeMounts:
    - name: secret-volume
      mountPath: /secrets
      readOnly: true
  
  volumes:
  - name: secret-volume
    secret:
      secretName: db-secret
```

**Example 3: Docker Registry Secret**

```bash
# Create Docker registry secret
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myemail@example.com
```

```yaml
# pod-with-imagepull-secret.yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-image-pod
spec:
  containers:
  - name: app
    image: myregistry/private-image:v1
  imagePullSecrets:
  - name: regcred
```

**Example 4: TLS Secret**

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=myapp.example.com"

# Create TLS secret
kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key
```

```yaml
# ingress-with-tls.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: tls-secret
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

```bash
# Create Secret
kubectl apply -f secret.yaml

# View Secret (values are hidden)
kubectl get secret db-secret

# Describe Secret
kubectl describe secret db-secret

# Get Secret in YAML (shows base64 encoded values)
kubectl get secret db-secret -o yaml

# Decode Secret value
kubectl get secret db-secret -o jsonpath='{.data.password}' | base64 --decode

# Create Pod using Secret
kubectl apply -f pod-with-secret-env.yaml

# Verify (be careful in production!)
kubectl logs app-with-secret

# Volume-mounted secrets
kubectl apply -f pod-with-secret-volume.yaml
kubectl exec app-with-secret-file -- ls -la /secrets
```

#### Hands-on: Using ConfigMaps and Secrets

**Complete Application Example:**

```yaml
# complete-config-example.yaml
---
# ConfigMap for application configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: webapp-config
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  nginx.conf: |
    server {
      listen 80;
      server_name localhost;
      location / {
        root /usr/share/nginx/html;
        index index.html;
      }
    }

---
# Secret for sensitive data
apiVersion: v1
kind: Secret
metadata:
  name: webapp-secret
type: Opaque
data:
  db-password: U3VwZXJTZWNyZXQxMjM=
  api-key: YWJjZGVmMTIzNDU2Nzg5MA==

---
# Deployment using ConfigMap and Secret
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        # From ConfigMap
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: APP_ENV
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: LOG_LEVEL
        # From Secret
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: webapp-secret
              key: db-password
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: webapp-secret
              key: api-key
        volumeMounts:
        - name: config-volume
          mountPath: /etc/nginx/conf.d
        - name: secret-volume
          mountPath: /etc/secrets
          readOnly: true
      
      volumes:
      - name: config-volume
        configMap:
          name: webapp-config
          items:
          - key: nginx.conf
            path: default.conf
      - name: secret-volume
        secret:
          secretName: webapp-secret

---
# Service
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  selector:
    app: webapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

```bash
# Deploy complete application
kubectl apply -f complete-config-example.yaml

# Verify resources
kubectl get configmap webapp-config
kubectl get secret webapp-secret
kubectl get deployment webapp
kubectl get pods

# Check environment variables in Pod
kubectl exec -it deployment/webapp -- env | grep -E 'APP_ENV|LOG_LEVEL|DB_PASSWORD|API_KEY'

# View mounted ConfigMap
kubectl exec -it deployment/webapp -- cat /etc/nginx/conf.d/default.conf

# View mounted Secret
kubectl exec -it deployment/webapp -- ls /etc/secrets

# Update ConfigMap
kubectl edit configmap webapp-config
# Change LOG_LEVEL to "debug"

# For env vars, need to restart pods
kubectl rollout restart deployment webapp

# For volume mounts, changes propagate automatically (with delay)
```

---

### 4. Security

#### Authentication and Authorization (RBAC)

**Authentication Methods:**
- **X509 Client Certificates**: TLS certificates
- **Static Token File**: Bearer tokens in file
- **Bootstrap Tokens**: For node bootstrapping
- **Service Account Tokens**: For Pods
- **OpenID Connect (OIDC)**: Integration with identity providers
- **Webhook Token Authentication**: External authentication

**RBAC (Role-Based Access Control):**
- Regulates access to Kubernetes resources
- Uses `rbac.authorization.k8s.io` API group

**RBAC Objects:**
1. **Role**: Grants permissions within a namespace
2. **ClusterRole**: Grants permissions cluster-wide
3. **RoleBinding**: Binds Role to subjects in namespace
4. **ClusterRoleBinding**: Binds ClusterRole to subjects cluster-wide

**Example 1: Role and RoleBinding**

```yaml
# role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]  # "" indicates core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

**Verbs (Permissions):**
- `get`, `list`, `watch`: Read operations
- `create`, `update`, `patch`: Modify operations
- `delete`, `deletecollection`: Delete operations
- `*`: All verbs

```yaml
# rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**Example 2: ClusterRole and ClusterRoleBinding**

```yaml
# clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
```

```yaml
# clusterrolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
- kind: Group
  name: manager
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

**Example 3: ServiceAccount with RBAC**

```yaml
# serviceaccount-rbac.yaml
---
# ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: default

---
# Role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: configmap-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]

---
# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-configmap-reader
  namespace: default
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: default
roleRef:
  kind: Role
  name: configmap-reader
  apiGroup: rbac.authorization.k8s.io

---
# Pod using ServiceAccount
apiVersion: v1
kind: Pod
metadata:
  name: app-with-sa
  namespace: default
spec:
  serviceAccountName: app-sa
  containers:
  - name: app
    image: busybox:1.33
    command: ['sh', '-c', 'sleep 3600']
```

```bash
# Apply RBAC resources
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml

# View Roles and RoleBindings
kubectl get roles
kubectl get rolebindings

# Describe Role
kubectl describe role pod-reader

# Check permissions
kubectl auth can-i get pods --as=jane
kubectl auth can-i create pods --as=jane

# Apply ServiceAccount example
kubectl apply -f serviceaccount-rbac.yaml

# Verify ServiceAccount
kubectl get serviceaccount app-sa

# Test from within Pod
kubectl exec -it app-with-sa -- sh
# Inside pod, access Kubernetes API
# (requires appropriate RBAC and network policies)
```

**Example 4: Aggregated ClusterRoles**

```yaml
# aggregated-clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-role
  labels:
    rbac.example.com/aggregate-to-monitoring: "true"
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-aggregated
aggregationRule:
  clusterRoleSelectors:
  - matchLabels:
      rbac.example.com/aggregate-to-monitoring: "true"
rules: []  # Rules are automatically filled by controller
```

#### Pod Security Standards

**Pod Security Standards (PSS):**
- Defines security policies at namespace level
- Three levels: Privileged, Baseline, Restricted

**Security Levels:**

1. **Privileged**: Unrestricted (for system-level workloads)
2. **Baseline**: Minimally restrictive (prevents known privilege escalations)
3. **Restricted**: Heavily restricted (follows current Pod hardening best practices)

**Modes:**
- **enforce**: Policy violations reject the Pod
- **audit**: Policy violations logged but allowed
- **warn**: Policy violations send warning to user

**Example: Namespace with Pod Security Standards**

```yaml
# namespace-with-pss.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

**Example: Pod that violates restricted policy**

```yaml
# privileged-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
  namespace: secure-namespace
spec:
  containers:
  - name: app
    image: nginx:1.21
    securityContext:
      privileged: true  # Violates restricted policy
```

**Example: Compliant Pod for restricted policy**

```yaml
# compliant-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  namespace: secure-namespace
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx:1.21
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
    ports:
    - containerPort: 80
    volumeMounts:
    - name: cache
      mountPath: /var/cache/nginx
    - name: run
      mountPath: /var/run
  volumes:
  - name: cache
    emptyDir: {}
  - name: run
    emptyDir: {}
```

```bash
# Create namespace with PSS
kubectl apply -f namespace-with-pss.yaml

# Try to create privileged pod (should be rejected)
kubectl apply -f privileged-pod.yaml

# Create compliant pod (should succeed)
kubectl apply -f compliant-pod.yaml

# Check pod
kubectl get pod compliant-pod -n secure-namespace
```

**SecurityContext Options:**

```yaml
# pod-security-context.yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  securityContext:
    runAsUser: 1000              # Run as specific user
    runAsGroup: 3000             # Run as specific group
    fsGroup: 2000                # Volume ownership group
    fsGroupChangePolicy: "OnRootMismatch"
    seccompProfile:
      type: RuntimeDefault       # Seccomp profile
  containers:
  - name: sec-ctx-demo
    image: busybox:1.33
    command: [ "sh", "-c", "sleep 1h" ]
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      runAsUser: 2000
      capabilities:
        add: ["NET_ADMIN", "SYS_TIME"]
        drop: ["ALL"]
      readOnlyRootFilesystem: true