# Day 10/40 - Kubernetes Namespace Explained - CKA Full Course 2024


## Check out the video below for Day10 👇

[![Day10/40 - Kubernetes Namespace Explained - CKA Full Course 2024](https://img.youtube.com/vi/yVLXIydlU_0/sddefault.jpg)](https://youtu.be/yVLXIydlU_0)

### What is a Namespace in Kubernetes

- Provides isolation of resources
- Avoid accidental deletion/modification
- Separated by resource type or environment or domain and so on
- Resources can access each other in the same namespace with their first name by the DNS name for other namespaces


![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/d9ae95d5-7224-4d5b-b260-ed09fc53c6fd)


Of course! Here is a detailed walkthrough of the namespace exercise, documented in a blog post format as a continuation of my Kubernetes learning journey.

***

## Kubernetes Namespaces: Achieving Isolation and Order in Your Cluster

Welcome back to my **"40 Days of Kubernetes"** blog! In previous entries, we've created Pods, Deployments, and Services, but so far, all our resources have been created in the `default` namespace. While this is fine for a small cluster or simple projects, real-world Kubernetes environments can become crowded and chaotic without proper organization.

This is where **Namespaces** come in. A Namespace provides a layer of isolation within a single Kubernetes cluster, allowing you to partition cluster resources into logically named groups. Think of it as creating virtual sub-clusters. This is crucial for:

*   **Avoiding Naming Conflicts**: You can have resources with the same name (e.g., `nginx-deployment`) in different namespaces without any issues.
*   **Access Control**: You can assign different permissions and RBAC (Role-Based Access Control) policies to different namespaces, ensuring teams only have access to the resources they need.
*   **Resource Management**: You can set resource quotas on a per-namespace basis to manage CPU and memory usage.
*   **Logical Separation**: It allows you to separate environments like `dev`, `test`, and `prod` within the same physical cluster.

When you provision a Kubernetes cluster, it comes with a few default namespaces, such as `default`, `kube-system` (for control plane components), `kube-public`, and `kube-node-lease`. Any resource you create without specifying a namespace goes into the `default` one.

Today's hands-on exercise will explore how namespaces work and, more importantly, how resources in different namespaces communicate with each other.

### Note on the Lab Environment

As always, I am using a local multi-node cluster created with **kind (Kubernetes in Docker)**. The setup steps are detailed in the Day 6 video of the series. I've also set up an alias `k=kubectl` in my bash profile to speed up my commands, a handy tip from the Day 10 video.

### Task 1: Create Namespaces and Deployments

The first step is to create two namespaces and deploy a simple Nginx application in each.

1.  **Create Two Namespaces:**
    I'll use the imperative `kubectl create namespace` command, which is much faster for simple tasks like this than writing a YAML file.
    ```bash
    k create namespace ns1
    k create namespace ns2
    ```
    To verify, I can list all the namespaces in the cluster.
    ```bash
    k get ns
    # NAME              STATUS   AGE
    # default           Active   2d
    # ns1               Active   10s
    # ns2               Active   9s
    # ... (other system namespaces)
    ```

2.  **Create Deployments in Each Namespace:**
    Now, I'll create an Nginx deployment in each namespace. It's crucial to use the `-n` (or `--namespace`) flag to specify the target namespace. If I forget this flag, the deployment will be created in the `default` namespace.

    ```bash
    # Create deployment in ns1
    k create deployment deploy-ns1 --image=nginx --replicas=1 -n ns1

    # Create deployment in ns2
    k create deployment deploy-ns2 --image=nginx --replicas=1 -n ns2
    ```

3.  **Verify the Deployments and Pods:**
    To see the resources, I again need to specify the namespace.
    ```bash
    # Check pods in ns1
    k get pods -n ns1
    # NAME                          READY   STATUS    RESTARTS   AGE
    # deploy-ns1-6d4b95d6c5-abcde   1/1     Running   0          45s

    # Check pods in ns2
    k get pods -n ns2
    # NAME                          READY   STATUS    RESTARTS   AGE
    # deploy-ns2-5f85f7f8f9-fghij   1/1     Running   0          40s
    ```
    Success! I have a running pod in each of my new namespaces.

### Task 2: Pod-to-Pod Communication using IP Addresses

Next, let's test if a pod in one namespace can directly communicate with a pod in another namespace using its IP address.

1.  **Get the IP Addresses of the Pods:**
    The `-o wide` flag provides extended information, including the pod's IP address and the node it's running on.
    ```bash
    # Get IP for the pod in ns1
    k get pod -n ns1 -o wide
    # NAME                          ...   IP            NODE
    # deploy-ns1-6d4b95d6c5-abcde   ...   10.244.1.4    cka-cluster-3-worker

    # Get IP for the pod in ns2
    k get pod -n ns2 -o wide
    # NAME                          ...   IP            NODE
    # deploy-ns2-5f85f7f8f9-fghij   ...   10.244.2.5    cka-cluster-3-worker2
    ```
    So, the IP for the pod in `ns1` is `10.244.1.4` and for `ns2` is `10.244.2.5`.

2.  **Test Connectivity with `curl`:**
    I'll use `kubectl exec` to run a `curl` command from inside the `ns1` pod, targeting the IP of the `ns2` pod.
    ```bash
    # Get the pod name in ns1
    POD_NS1=$(k get pods -n ns1 -o jsonpath='{.items.metadata.name}')

    # Exec into the pod and curl the IP of the other pod
    k exec -it $POD_NS1 -n ns1 -- curl 10.244.2.5
    ```
    **Result:** It works! The command returns the "Welcome to nginx!" HTML page. This confirms that **pod IP addresses are cluster-wide and directly reachable from any other pod**, regardless of the namespace.

### Task 3: Service-to-Service Communication

While pod IPs work, they are not static; a pod gets a new IP every time it restarts. For stable communication, we need Services. Now, let's explore how services communicate across namespaces.

1.  **Scale the Deployments:**
    First, I'll scale both deployments to 3 replicas.
    ```bash
    k scale deployment deploy-ns1 --replicas=3 -n ns1
    k scale deployment deploy-ns2 --replicas=3 -n ns2
    ```

2.  **Expose Deployments as Services:**
    I'll use the `kubectl expose` command to create a `ClusterIP` service for each deployment.
    ```bash
    # Expose deployment in ns1
    k expose deployment deploy-ns1 --name=svc-ns1 --port=80 -n ns1

    # Expose deployment in ns2
    k expose deployment deploy-ns2 --name=svc-ns2 --port=80 -n ns2
    ```

3.  **Check Service IPs:**
    ```bash
    k get svc -n ns1
    # NAME      TYPE        CLUSTER-IP      PORT(S)
    # svc-ns1   ClusterIP   10.96.123.100   80/TCP

    k get svc -n ns2
    # NAME      TYPE        CLUSTER-IP      PORT(S)
    # svc-ns2   ClusterIP   10.96.200.220   80/TCP
    ```

4.  **Test Service Communication with IP Address:**
    Let's exec into a pod in `ns1` again and try to curl the *ClusterIP* of the service in `ns2`.
    ```bash
    k exec -it $POD_NS1 -n ns1 -- curl 10.96.200.220
    ```
    **Result:** Success again! This shows that service IPs, like pod IPs, are also cluster-wide and can be accessed from any namespace.

5.  **Test Service Communication with Service Name:**
    Now for the interesting part. What if I try to use the service *name* (`svc-ns2`) instead of its IP?
    ```bash
    k exec -it $POD_NS1 -n ns1 -- curl http://svc-ns2
    ```
    **Result:** It fails! The command returns an error: `curl: (6) Could not resolve host: svc-ns2`. This happens because **service hostnames are namespace-scoped, not cluster-wide**. The internal DNS service (`CoreDNS`) in the `ns1` namespace does not know about a service named `svc-ns2`.

6.  **Test Service Communication with FQDN:**
    To resolve a service in another namespace, you must use its **Fully Qualified Domain Name (FQDN)**. The FQDN for a Kubernetes service follows this pattern: `<service-name>.<namespace-name>.svc.cluster.local`.

    Let's try the `curl` command one last time with the FQDN of `svc-ns2`.
    ```bash
    k exec -it $POD_NS1 -n ns1 -- curl http://svc-ns2.ns2.svc.cluster.local
    ```
    **Result:** It works perfectly! The request is successfully resolved and routed to the service in the `ns2` namespace. You can inspect the `/etc/resolv.conf` file inside a pod to see how Kubernetes configures DNS search domains to make this possible.

### Final Step: Cleanup

To clean up all the resources I created, I can simply delete the namespaces. Deleting a namespace will cascade and delete all the objects (Deployments, ReplicaSets, Pods, Services) within it.

```bash
k delete ns ns1 ns2
```

### Key Learnings

This was a fantastic exercise to solidify my understanding of namespaces. My main takeaways are:
*   **IP Addresses are Cluster-Wide**: Both Pod and Service IP addresses are unique across the entire cluster and can be accessed from any namespace.
*   **Hostnames are Namespace-Wide**: Service DNS names (hostnames) are only unique *within* their namespace. To communicate across namespaces, you must use the service's FQDN.
*   **Namespaces Provide Essential Isolation**: They are a fundamental tool for organizing resources, controlling access, and managing multi-tenant or multi-environment clusters effectively.

This concludes today's hands-on lab. Join me next time as we dive into multi-container pods! #40DaysOfKubernetes #CKA #Kubernetes #DevOps

***

Perfect ✅ — here’s a **high-level, real-world structure** to create **test** and **prod** environments running NGINX pods (the DevOps-way).

We’ll do this **declaratively (YAML manifests)** — the professional and scalable approach — but I’ll also show you the quick **imperative method** at the end.

---

## 🧭 Overall Architecture

```
cluster
├── Namespace: test
│   └── Deployment: nginx-test
│       └── Pods (nginx-test-xxxx)
│   └── Service: nginx-test-svc
│
└── Namespace: prod
    └── Deployment: nginx-prod
        └── Pods (nginx-prod-xxxx)
    └── Service: nginx-prod-svc
```

Each environment (test, prod) is isolated in its own namespace.

---

## 🧩 Step 1: Create namespaces

```bash
kubectl create namespace test
kubectl create namespace prod
```

Or declaratively (in YAML):

```yaml
# namespaces.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: test
---
apiVersion: v1
kind: Namespace
metadata:
  name: prod
```

Apply:

```bash
kubectl apply -f namespaces.yaml
```

---

## 🧩 Step 2: Create NGINX Deployments for both environments

```yaml
# nginx-envs.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  namespace: test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-prod
  namespace: prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-prod
  template:
    metadata:
      labels:
        app: nginx-prod
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
```

Apply:

```bash
kubectl apply -f nginx-envs.yaml
```

---

## 🧩 Step 3: Create Services for both

```yaml
# nginx-services.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-test-svc
  namespace: test
spec:
  selector:
    app: nginx-test
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-prod-svc
  namespace: prod
spec:
  selector:
    app: nginx-prod
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

Apply:

```bash
kubectl apply -f nginx-services.yaml
```

---

## 🧩 Step 4: Verify Everything

```bash
kubectl get all -n test
kubectl get all -n prod
```

You should see:

```
NAME                           READY   STATUS    RESTARTS   AGE
pod/nginx-test-xxxxx           1/1     Running   0          2m
...
service/nginx-test-svc         ClusterIP   10.x.x.x   <none>   80/TCP
```

---

## 🧩 Step 5: (Optional) Expose externally (for browser access)

If you’re testing locally:

```bash
kubectl expose deployment nginx-test -n test --type=NodePort --port=80
kubectl expose deployment nginx-prod -n prod --type=NodePort --port=80
```

Then find ports:

```bash
kubectl get svc -A | grep nginx
```

and access:

```
http://<node-ip>:<nodeport>
```

---

## 🧩 Quick Imperative Shortcut (if you just want to test fast)

```bash
kubectl create namespace test
kubectl create namespace prod

kubectl run nginx-test --image=nginx -n test
kubectl expose pod nginx-test --port=80 --type=NodePort -n test

kubectl run nginx-prod --image=nginx -n prod
kubectl expose pod nginx-prod --port=80 --type=NodePort -n prod
```

---

Would you like me to make this more **production-style**, with configs (like ConfigMap + resource limits + different index pages per environment)? That’s the next level for real-world dev/test/prod setups.


Perfect 👌 let’s walk through how **to properly test internal Pod-to-Pod and Pod-to-Service connectivity in Kubernetes** — this is a **real-world troubleshooting workflow** used by DevOps/SRE/SOC teams.

---

## 🧠 Why Do This?

Sometimes your app Pod (like NGINX or Flask) can’t reach another Pod or service (like Redis, API, or DB). Instead of guessing, we use a **debug Pod** to test networking *inside* the cluster.

---

## ⚙️ Step 1: Create a Temporary Debug Pod

You’ll run a simple container (with tools like `curl`, `ping`, and `nslookup`) to test connectivity.

```bash
kubectl run net-debug --rm -it \
  --image=busybox:1.35 \
  --restart=Never \
  -- sh
```

👉 What happens:

* `--rm`: removes the pod after you exit
* `--it`: opens an interactive shell
* `--restart=Never`: runs it as a one-off pod
* `--image=busybox:1.35`: small Linux image with basic tools
* You’ll land inside the container shell (`/ #` prompt)

---

## 🧰 Step 2: Test Pod-to-Pod Connectivity

### 🔹 Find the target Pod

```bash
kubectl get pods -A -o wide
```

Example output:

```
NAMESPACE   NAME                     IP           NODE
dev         nginx-dev-75bcbd7dc4-z9r7k   10.244.1.5   kind-worker
prod        nginx-prod-d7cdd969f-7ccsw   10.244.3.4   kind-worker2
```

### 🔹 From inside your debug Pod, test:

```bash
# Check ping
ping -c 3 10.244.3.4

# Try connecting via HTTP
curl -v http://10.244.3.4
```

✅ If successful:

* You’ll get an HTTP response (like `200 OK`)
  ❌ If it fails:
* You’ll see timeout — meaning pod networking or service exposure is misconfigured.

---

## 🧭 Step 3: Test Pod-to-Service Connectivity

### 🔹 List services:

```bash
kubectl get svc -A -o wide
```

Example:

```
NAMESPACE   NAME             CLUSTER-IP     PORT(S)
dev         nginx-dev-svc    10.96.129.249  80/TCP
prod        nginx-prod-svc   10.96.174.142  80/TCP
```

### 🔹 Inside the debug pod:

You can test DNS-based service access:

```bash
nslookup nginx-prod-svc.prod.svc.cluster.local
```

Then access via cluster DNS name:

```bash
curl -v http://nginx-prod-svc.prod.svc.cluster.local
```

✅ Expected:
You should see an HTML response or “Welcome to nginx”.

---

## 🧩 Step 4: Cross-Check Network Policy (if used)

If ping/curl works from same namespace but fails across namespaces, a **NetworkPolicy** might block traffic.

```bash
kubectl get networkpolicy -A
```

If any exist, describe them:

```bash
kubectl describe networkpolicy -n <namespace> <policy-name>
```

Check if ingress/egress allows connections between those namespaces.

---

## 🧹 Step 5: Cleanup (Optional)

When done, simply exit:

```bash
exit
```

The `--rm` flag automatically deletes your `net-debug` pod.

---

## 🧾 Bonus: Create a Permanent Debug Pod

If you often debug clusters, deploy a full-featured “toolbox” pod:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: net-tools
  namespace: default
spec:
  containers:
  - name: net-tools
    image: praqma/network-multitool
    command: ["/bin/bash"]
    tty: true
EOF
```

Then use:

```bash
kubectl exec -it net-tools -- bash
```

It comes with `curl`, `wget`, `dig`, `nslookup`, `ping`, `traceroute`, `netcat`, etc.

---

## ✅ Summary Table

| Step | What It Tests    | Command                                                                     |
| ---- | ---------------- | --------------------------------------------------------------------------- |
| 1    | Create debug pod | `kubectl run net-debug --rm -it --image=busybox:1.35 --restart=Never -- sh` |
| 2    | Pod-to-Pod       | `curl 10.244.x.x`                                                           |
| 3    | Pod-to-Service   | `curl http://<svc>.<namespace>.svc.cluster.local`                           |
| 4    | DNS resolution   | `nslookup <svc>.<namespace>.svc.cluster.local`                              |
| 5    | Network policy   | `kubectl get networkpolicy -A`                                              |
| 6    | Cleanup          | `exit`                                                                      |

---

| Step | Check                  | Command                                               |           |
| ---- | ---------------------- | ----------------------------------------------------- | --------- |
| 1    | CoreDNS pods running   | `kubectl get pods -n kube-system -l k8s-app=kube-dns` |           |
| 2    | CoreDNS service exists | `kubectl get svc -n kube-system`                      |           |
| 3    | Pod DNS config         | `cat /etc/resolv.conf`                                |           |
| 4    | CNI plugin healthy     | `kubectl get pods -n kube-system                      | grep cni` |
| 5    | Verify via another pod | `nslookup kube-dns.kube-system.svc.cluster.local`     |           |
| 6    | KIND/Windows DNS fix   | Restart CoreDNS + Kind cluster                        |           |
| 7    | Retest                 | `nslookup` + `curl` to service                        |           |


Would you like me to give you a **hands-on YAML + commands mini lab** (like “Deploy nginx in `prod`, redis in `dev`, and use a debug Pod to verify connectivity between them”)?
That’s a common **Kubernetes network troubleshooting interview exercise.**
