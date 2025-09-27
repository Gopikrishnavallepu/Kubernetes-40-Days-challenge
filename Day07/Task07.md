## Check out the task.md file for day07 task details

## Different ways of creating a Kubernetes object
- Imperative way ( Through command or API calls)
- Declarative way ( By creating manifest files)

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/b038c4d3-87b7-474d-a3aa-5983d978f885)


## Below is the sample pod YAML used in the video:

```YAML
# This is a sample pod yaml

apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    env: demo
    type: frontend
spec:
  containers:
  - name: nginx-container
    image: nginx
    ports:
    - containerPort: 80
```
Of course! Here is a blog post documenting the key learnings from the video, including the solutions to the tasks you've outlined.

***

## My Kubernetes Journey: Mastering Pods with Imperative and Declarative Commands

Welcome to my blog! I've recently started the **"40 Days of Kubernetes"** challenge and have been following the CKA Full Course 2025 series from "Tech Tutorials with Piyush". The series is designed to cover the entire curriculum for the Certified Kubernetes Administrator (CKA) exam as per the latest 2024 guidelines. The instructor emphasizes a hands-on approach, which is fantastic for learning. Today, I'm diving into one of the most fundamental objects in Kubernetes: the **Pod**.

A Pod is the smallest deployable unit in Kubernetes. It acts as an encapsulation for one or more containers, allowing them to share resources. While you can run containers standalone, Kubernetes manages them within Pods to provide features like auto-healing and high availability.

Kubernetes offers two main ways to interact with the cluster and manage resources: the **imperative** and **declarative** methods. The imperative approach involves running direct commands (like `kubectl run`), which is great for quick tasks and troubleshooting. The declarative approach uses configuration files, typically in YAML, to define the desired state of an object. This method is preferred for production environments and fits well with practices like GitOps.

Let's put this theory into practice!

### Watch The Video

Before we start, here's the video that guided me through these tasks. I highly recommend watching it to follow along.

**(Video Embedded Here)**
`[Link to relevant video from "Tech Tutorials with Piyush"]`

### Task 1: Create an Nginx Pod Imperatively

The first task is to create a simple Nginx pod using an imperative command. This is a straightforward way to get a workload running on the cluster quickly.

1.  **Command to create the pod:**
    The `kubectl run` command is used for this purpose. You specify a name for the pod and the container image to use.

    ```bash
    kubectl run nginx-pod --image=nginx
    ```

2.  **Verify the pod's status:**
    After running the command, you can check if the pod was created and is running using `kubectl get pods`.

    ```bash
    kubectl get pods
    ```
    You should see an output like this, indicating the pod is in the `Running` state.
    ```
    NAME        READY   STATUS    RESTARTS   AGE
    nginx-pod   1/1     Running   0          25s
    ```

### Task 2: Create a New Pod from Existing YAML

Next, we'll use the declarative approach. The goal is to generate a YAML file from the pod we just created, modify it, and then use that file to create a new pod. This is a powerful technique because you don't have to write YAML from scratch; you can generate a template and then customize it.

1.  **Generate YAML from the existing pod:**
    We can use the `kubectl get pod` command with the `-o yaml` flag to output the pod's configuration in YAML format. The `--dry-run=client` flag ensures that the command doesn't actually create a resource but just generates its configuration. We'll redirect this output to a new file named `pod.yaml`.

    ```bash
    kubectl get pod nginx-pod -o yaml > pod.yaml
    ```
    *Note: A more common practice for generating fresh YAML is `kubectl run nginx-pod --image=nginx --dry-run=client -o yaml > pod.yaml`. Both achieve a similar outcome for this task.*

2.  **Update the pod name in the YAML file:**
    Now, open the `pod.yaml` file with an editor like `vi` or `nano`. Find the `metadata` section and change the `name` field from `nginx-pod` to `nginx-new`. I also cleaned up the file by removing system-generated fields like `creationTimestamp`, `resourceVersion`, and `uid` to keep it clean.

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      labels:
        run: nginx-pod # You can change this too if you like!
      name: nginx-new # Changed this line
    spec:
      containers:
      - image: nginx
        name: nginx-pod
        resources: {}
    ```

3.  **Create the new pod using the updated YAML:**
    With the modified YAML file, we can create the new pod using the `kubectl apply` command.

    ```bash
    kubectl apply -f pod.yaml
    ```

4.  **Verify the new pod:**
    Check the pods again. You should now see both `nginx-pod` and the newly created `nginx-new` running.

    ```bash
    kubectl get pods
    ```
    ```
    NAME        READY   STATUS    RESTARTS   AGE
    nginx-pod   1/1     Running   0          5m
    nginx-new   1/1     Running   0          30s
    ```

### Task 3: Troubleshoot and Fix a Broken YAML

This final task is a common real-world scenario: you're given a YAML file that has an error, and you need to fix it.

Here is the initial broken YAML:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: test
  name: redis
spec:
  containers:
  - image: rediss
    name: redis
```

1.  **Attempt to apply the YAML:**
    First, I saved this content to a file called `redis-broken.yaml` and tried to apply it.

    ```bash
    kubectl apply -f redis-broken.yaml
    ```

2.  **Observe the error:**
    The pod gets created, but it won't run successfully. Checking its status reveals the problem.

    ```bash
    kubectl get pods
    ```
    The output shows an `ImagePullBackOff` error, which means Kubernetes is having trouble pulling the container image.
    ```
    NAME    READY   STATUS             RESTARTS   AGE
    redis   0/1     ImagePullBackOff   0          15s
    ```

3.  **Troubleshoot with `kubectl describe`:**
    To get more details, the `kubectl describe pod` command is invaluable. It provides a detailed log of events related to the pod.

    ```bash
    kubectl describe pod redis
    ```
    Scrolling down to the `Events` section, the error message is clear:
    ```
    Events:
      ...
      Warning  Failed   ...   Failed to pull image "rediss": rpc error: code = Unknown desc = repository docker.io/library/rediss not found
    ```
    The message "repository... not found" confirms that the image name `rediss` is incorrect.

4.  **Fix the YAML and re-apply:**
    The correct image name for Redis is `redis`. I edited the pod's configuration directly using `kubectl edit pod redis`. This opens the pod's live configuration in an editor. I corrected the `image` field from `rediss` to `redis` and saved the changes.

    ```bash
    kubectl edit pod redis
    ```
    After saving, Kubernetes automatically applies the changes.

5.  **Verify the fix:**
    Checking the pods one last time shows that the `redis` pod is now running correctly.
    ```bash
    kubectl get pods
    ```
    ```
    NAME    READY   STATUS    RESTARTS   AGE
    redis   1/1     Running   0          2m
    ```

And that's it! These simple exercises are a great way to understand the core concepts of Kubernetes Pods and how to manage them using both imperative and declarative methods.

Ah! I see — you **edited a Pod YAML live in the cluster** (using `kubectl edit pod`) and now want to **reflect those changes back into your original YAML file**. Let me explain clearly.

---

## 🔹 Understanding the Situation

1. **`kubectl edit pod <pod-name>`**

   * Opens the Pod manifest from the **live cluster** in your editor.
   * Any changes you save **apply directly to the cluster**.
   * **Does NOT update your original local YAML file**.

2. **Why?**

   * Kubernetes stores resources in its **API server**, not your local files.
   * Editing in-cluster modifies the live object; your YAML on disk is **still the old version**.

---

## 🔹 How to Update Your Original YAML

### 1️⃣ Export the current live YAML from the cluster

```bash
kubectl get pod <pod-name> -o yaml > pod.yaml
```

* This **overwrites** or creates a file `pod.yaml` with the **current live state** of the Pod.
* Now your local YAML reflects **all live changes**, including edits made via `kubectl edit`.

---

### 2️⃣ Optional: Merge with original YAML

If you want to **preserve some original comments/structure**:

```bash
kubectl get pod <pod-name> -o yaml > pod-live.yaml
# Then manually diff & merge with your original YAML
diff pod.yaml pod-live.yaml
```

* Use `vimdiff` or VS Code to **merge changes**.

---

### 3️⃣ Best Practices

* Avoid live edits in production — instead:

  1. Edit **local YAML**.
  2. Apply with:

     ```bash
     kubectl apply -f pod.yaml
     ```
* If you **must edit live**, always **export afterward** to keep your YAML up-to-date.

---

### 4️⃣ Interview Explanation

If asked:

> *“You edited a pod live. How do you update the YAML file?”*

You can answer:

> “`kubectl edit` modifies the live cluster only. To reflect changes back, I use `kubectl get pod <pod-name> -o yaml > pod.yaml` to export the current live state into my original YAML. This keeps my files version-controlled and consistent with the cluster.”

---

If you want, I can also show a **quick trick to auto-sync live cluster YAML to your local folder** for multiple resources, so you never lose changes made live.

Do you want me to show that?



***


### References

*   "Day 1/40 - Docker Tutorial For Beginners - Docker Fundamentals - CKA Full Course 2025" - Tech Tutorials with Piyush
*   "Day 5/40 - What is Kubernetes - Kubernetes Architecture Explained" - Tech Tutorials with Piyush
*   "Day 7/40 - Pod In Kubernetes Explained | Imperative VS Declarative Way | YAML Tutorial" - Tech Tutorials with Piyush
*   "Day 8/40 - Kubernetes Deployment, Replication Controller and ReplicaSet Explained" - Tech Tutorials with Piyush
*   "FREE Kubernetes Full Course (Day 0/40) | Certified Kubernetes Administrator (CKA) Tutorial + Roadmap" - Tech Tutorials with Piyush

Perfect 🚀 — here’s a **`kubectl explain` Cheat Sheet** you can use in **interviews and real-time**.
This shows how to explore **common Kubernetes objects** step by step.

---

# 📝 `kubectl explain` Cheat Sheet

| Resource                        | Command                                             | Why Useful                                       |
| ------------------------------- | --------------------------------------------------- | ------------------------------------------------ |
| **Pod**                         | `kubectl explain pod`                               | Top-level description of Pod object.             |
|                                 | `kubectl explain pod.spec`                          | Explore spec fields (containers, volumes, etc.). |
|                                 | `kubectl explain pod.spec.containers`               | Shows container settings (image, ports, probes). |
|                                 | `kubectl explain pod.spec.containers.livenessProbe` | Learn readiness/liveness probe fields.           |
|                                 | `kubectl explain pod.spec.affinity`                 | Discover node/pod affinity rules.                |
| **Deployment**                  | `kubectl explain deployment`                        | Learn about Deployment resource (apps/v1).       |
|                                 | `kubectl explain deployment.spec`                   | Fields like replicas, selector, template.        |
|                                 | `kubectl explain deployment.spec.strategy`          | Shows RollingUpdate/Recreate strategies.         |
| **Service**                     | `kubectl explain service`                           | Understand ClusterIP/NodePort/LoadBalancer.      |
|                                 | `kubectl explain service.spec`                      | Explore ports, selectors, type fields.           |
|                                 | `kubectl explain service.spec.ports`                | See port/protocol/targetPort details.            |
| **Ingress**                     | `kubectl explain ingress`                           | Shows networking.k8s.io/v1 API group.            |
|                                 | `kubectl explain ingress.spec`                      | Rules, TLS, backend configs.                     |
|                                 | `kubectl explain ingress.spec.rules.http.paths`     | Path-based routing details.                      |
| **ConfigMap**                   | `kubectl explain configmap`                         | Understand ConfigMap structure.                  |
|                                 | `kubectl explain configmap.data`                    | How key-value pairs are stored.                  |
| **Secret**                      | `kubectl explain secret`                            | Shows Secret structure.                          |
|                                 | `kubectl explain secret.data`                       | Base64 encoded key-value pairs.                  |
| **PersistentVolumeClaim (PVC)** | `kubectl explain pvc`                               | Learn about PVC definition.                      |
|                                 | `kubectl explain pvc.spec.resources`                | Request/limit storage details.                   |
|                                 | `kubectl explain pvc.spec.accessModes`              | Shows ReadWriteOnce, ReadOnlyMany, etc.          |
| **Node**                        | `kubectl explain node`                              | Understand Node API fields.                      |
|                                 | `kubectl explain node.status`                       | Status conditions, capacity, addresses.          |

---

# 🔹 Pro Tips (Interview-Worthy)

* Use `--recursive` to see all fields in one shot:

  ```bash
  kubectl explain pod.spec --recursive
  ```
* Use it as a **YAML reference** when writing manifests without docs.
* Always mention:
  **“kubectl explain queries the live API server, so it’s always version-accurate to my cluster.”**

---

⚡ This shows interviewers you can **self-document Kubernetes** without relying on Google.

👉 Do you want me to also prepare **real-world YAML writing + kubectl explain mapping** (like Pod with probes, Deployment with strategy, Service with multiple ports) so you can demonstrate both theory + practice?

Great question 👍 — in **Kubernetes** you’ll often need to check **how many Pods are running on a worker node** and also see their **containers at that time**.

Here’s how you can do it 👇

---

# 🔹 1. List Pods by Node (to see which worker node they are on)

```bash
kubectl get pods -o wide
```

👉 Output:

```
NAME                          READY   STATUS    RESTARTS   AGE   IP          NODE
nginx-deployment-6d4cf56db6   1/1     Running   0          20m   10.244.0.5  worker-node1
myapp-7d89f4c9b7              2/2     Running   1          10m   10.244.1.8  worker-node2
```

* `NODE` column shows which worker node the pod is running on.
* `READY` shows containers inside (e.g., `2/2` = 2 containers running).

---

# 🔹 2. Count Pods per Worker Node

```bash
kubectl get pods -o wide --all-namespaces | awk '{print $8}' | sort | uniq -c
```

👉 Output:

```
5 worker-node1
3 worker-node2
2 control-plane
```

This means:

* 5 Pods on worker-node1
* 3 Pods on worker-node2
* 2 Pods on control-plane

---

# 🔹 3. Check Containers in Each Pod

```bash
kubectl describe pod <pod-name> -n <namespace>
```

* Shows all containers running inside the Pod.
* Example fields:

  ```
  Containers:
    app-container:
      Image: nginx:1.21
      State: Running
    sidecar:
      Image: busybox
      State: Running
  ```

---

# 🔹 4. Directly Check Node for Pods/Containers (with crictl or docker/podman)

If you SSH into a **worker node**:

* For containerd runtime:

  ```bash
  crictl ps
  ```
* For Docker runtime:

  ```bash
  docker ps
  ```

This shows all running containers inside that node.

---

# 🔹 5. Watch Pods in Real Time

```bash
kubectl get pods -o wide -w
```

This continuously shows Pods starting/stopping and where they are scheduled.

---

✅ **Interview Tip**
If asked: *“How do you check what’s running on worker nodes?”*
You can say:

* “I use `kubectl get pods -o wide` to see Pod-to-Node mapping.”
* “To check container details, I use `kubectl describe pod`.”
* “If I need to go deeper inside the node, I use `crictl ps` or `docker ps` depending on runtime.”

---

👉 Do you want me to also give you a **one-liner script/command** that directly shows *Pods + Containers grouped by worker node* (so you can use it in real troubleshooting)?
Perfect 🔥 — in real troubleshooting, you want **a single one-liner** that gives you **Pods + Containers grouped by Worker Node** without manual counting. Here are ready-to-use commands:

---

## ✅ One-liner: Pods per Worker Node

```bash
kubectl get pods -A -o wide --no-headers | awk '{print $8}' | sort | uniq -c
```

🔹 Output Example:

```
  5 worker-1
  3 worker-2
  7 master
```

* `5` = Number of pods running on `worker-1`.
* `3` = Pods on `worker-2`.
* `7` = Pods on control-plane/master node.

---

## ✅ One-liner: Pods + Containers per Worker Node

```bash
kubectl get pods -A -o json | jq -r '.items[] | "\(.spec.nodeName) \(.spec.containers | length)"' \
 | awk '{pods[$1]++; containers[$1]+=$2} END {for (n in pods) print n, "Pods="pods[n], "Containers="containers[n]}'
```

🔹 Output Example:

```
worker-1 Pods=5 Containers=8
worker-2 Pods=3 Containers=5
master   Pods=7 Containers=10
```

* `Pods=5` → total pods scheduled.
* `Containers=8` → total containers across those pods.

---

## ✅ Bonus (Quick Check via Node Describe)

```bash
kubectl describe node worker-1 | grep "Non-terminated Pods"
```

Example:

```
Non-terminated Pods:  15 (10 running, 5 pending)
```

---

⚡ **Interview Pro Tip**:
If asked *“How would you quickly know pods & containers per worker node?”*
You can say:

> “I use a JSONPath + jq one-liner that summarizes pods and container counts per node. For example, it will show `worker-1 Pods=5 Containers=8`. This is super useful in real troubleshooting when checking workload distribution.”

---

Do you want me to also give you a **Bash script version** (with colors + formatted output) that you can keep handy in your toolbox for interviews/demos?

Perfect! 🚀 Let’s extend the previous script to also include **CPU & Memory usage per node** along with **Pods & Containers counts**.
This will act like a **mini monitoring summary** without needing Prometheus.

---

## 🔹 Script: `node-workload-summary.sh`

```bash
#!/bin/bash
# Script: node-workload-summary.sh
# Shows Pods, Containers, CPU & Memory usage per Kubernetes Node
# Requires metrics-server to be installed in cluster

echo -e "\033[1;34m=== Node Workload Summary ===\033[0m"

# Get Pod & Container counts per node
declare -A pod_count
declare -A container_count

kubectl get pods -A -o json | jq -r '
  .items[] | "\(.spec.nodeName) \(.spec.containers | length)"' \
| awk '{pods[$1]++; containers[$1]+=$2} END {for (n in pods) print n, pods[n], containers[n]}' \
> /tmp/node_pods_containers.txt

# Get CPU & Memory usage from kubectl top nodes
kubectl top nodes --no-headers | awk '{print $1, $2, $3}' > /tmp/node_resources.txt

# Print summary
printf "\n%-20s %-10s %-12s %-12s %-12s\n" "NODE" "PODS" "CONTAINERS" "CPU(cores)" "MEMORY"
echo "---------------------------------------------------------------"

while read -r line; do
    node=$(echo $line | awk '{print $1}')
    pods=$(echo $line | awk '{print $2}')
    containers=$(echo $line | awk '{print $3}')
    # Match CPU/Memory usage
    cpu=$(grep "^$node" /tmp/node_resources.txt | awk '{print $2}')
    mem=$(grep "^$node" /tmp/node_resources.txt | awk '{print $3}')
    printf "\033[1;32m%-20s %-10s %-12s %-12s %-12s\033[0m\n" "$node" "$pods" "$containers" "$cpu" "$mem"
done < /tmp/node_pods_containers.txt
```

---

## 🔹 Usage

1. Save script:

```bash
nano node-workload-summary.sh
```

(Paste the code above)

2. Make executable:

```bash
chmod +x node-workload-summary.sh
```

3. Run it:

```bash
./node-workload-summary.sh
```

---

## 🔹 Sample Output

```
=== Node Workload Summary ===

NODE                 PODS       CONTAINERS   CPU(cores)   MEMORY      
---------------------------------------------------------------
worker-1             7          10           500m         1024Mi
worker-2             4          6            300m         512Mi
master               5          7            400m         768Mi
```

---

## 🔹 Interview Tip

* Shows **real-time Pods + Containers + CPU & Memory usage** per node.
* Demonstrates your **hands-on cluster monitoring skills** without external tools.
* You can say:

> “I can quickly summarize node workloads and resource usage with a small script using `kubectl get pods`, `kubectl top nodes`, and `jq` — helpful during troubleshooting and capacity planning.”

---

If you want, I can **also extend this script to show Pods per Namespace per Node**, so it becomes a **full mini cluster overview tool** for interviews or demo purposes.

Do you want me to do that next?
Perfect! 🚀 Let’s extend the script to show a **full cluster overview** including:

* Pods **per node**
* Containers per pod
* CPU & Memory usage per node
* Pods **per namespace per node**

This gives a **comprehensive snapshot** of cluster workload — very interview/demo-friendly.

---

## 🔹 Script: `cluster-overview.sh`

```bash
#!/bin/bash
# Script: cluster-overview.sh
# Shows Node summary with Pods, Containers, CPU/Memory, and Pods per Namespace

echo -e "\033[1;34m=== Kubernetes Cluster Overview ===\033[0m"

# Temporary files
POD_CONTAINER_FILE=/tmp/node_pods_containers.txt
NODE_RES_FILE=/tmp/node_resources.txt
POD_NS_FILE=/tmp/node_pods_namespace.txt

# 1️⃣ Pods & Containers per Node
kubectl get pods -A -o json | jq -r '.items[] | "\(.spec.nodeName) \(.spec.containers | length) \(.metadata.namespace)"' \
| awk '{pods[$1]++; containers[$1]+=$2; ns[$1,$3]++} END {
    for (n in pods) print n, pods[n], containers[n];
}' > $POD_CONTAINER_FILE

# 2️⃣ CPU & Memory per Node
kubectl top nodes --no-headers | awk '{print $1, $2, $3}' > $NODE_RES_FILE

# 3️⃣ Pods per Namespace per Node
kubectl get pods -A -o json | jq -r '.items[] | "\(.spec.nodeName) \(.metadata.namespace)"' \
| sort | uniq -c > $POD_NS_FILE

# 4️⃣ Print Node Summary
printf "\n%-20s %-10s %-12s %-12s %-12s\n" "NODE" "PODS" "CONTAINERS" "CPU(cores)" "MEMORY"
echo "---------------------------------------------------------------"

while read -r line; do
    node=$(echo $line | awk '{print $1}')
    pods=$(echo $line | awk '{print $2}')
    containers=$(echo $line | awk '{print $3}')
    cpu=$(grep "^$node" $NODE_RES_FILE | awk '{print $2}')
    mem=$(grep "^$node" $NODE_RES_FILE | awk '{print $3}')
    printf "\033[1;32m%-20s %-10s %-12s %-12s %-12s\033[0m\n" "$node" "$pods" "$containers" "$cpu" "$mem"
done < $POD_CONTAINER_FILE

# 5️⃣ Print Pods per Namespace per Node
echo -e "\n\033[1;34m=== Pods per Namespace per Node ===\033[0m"
awk '{count[$2,$3]=$1} END {for (k in count) {split(k,a,SUBSEP); printf "%-20s %-20s %s\n", a[1], a[2], count[k]}}' $POD_NS_FILE
```

---

## 🔹 Usage

1. Save script:

```bash
nano cluster-overview.sh
```

(Paste code above)

2. Make it executable:

```bash
chmod +x cluster-overview.sh
```

3. Run it:

```bash
./cluster-overview.sh
```

---

## 🔹 Sample Output

```
=== Kubernetes Cluster Overview ===

NODE                 PODS       CONTAINERS   CPU(cores)   MEMORY
---------------------------------------------------------------
worker-1             7          10           500m         1024Mi
worker-2             4          6            300m         512Mi
master               5          7            400m         768Mi

=== Pods per Namespace per Node ===
worker-1             default              5
worker-1             kube-system          2
worker-2             default              3
worker-2             kube-system          1
master               kube-system          5
```

---

### 🔹 Interview Tip

* Demonstrates **hands-on Kubernetes cluster monitoring**.
* Shows **pods distribution per node**, **containers**, **resource usage**, and **namespace-level visibility**.
* You can confidently say:

> “I can quickly assess node workloads, container counts, CPU/Memory usage, and pod distribution per namespace using a single script without installing extra tools.”

---

If you want, I can **also add live updates (`watch` style)** to this script so it **auto-refreshes every 5 seconds**, which is very handy for **real-time cluster monitoring** during demos or troubleshooting.

Do you want me to do that next?
Perfect! 🚀 Let’s enhance the script to **auto-refresh every few seconds**, giving you a **real-time cluster monitoring dashboard** directly in the terminal.

---

## 🔹 Script: `cluster-overview-live.sh`

```bash
#!/bin/bash
# Script: cluster-overview-live.sh
# Real-time Kubernetes Cluster Overview (Pods, Containers, CPU/Memory, Pods per Namespace)
# Auto-refreshes every 5 seconds
# Requires metrics-server installed

INTERVAL=5  # refresh interval in seconds

while true; do
    clear
    echo -e "\033[1;34m=== Kubernetes Cluster Live Overview ===\033[0m"
    echo "Updated: $(date)"
    
    # Temporary files
    POD_CONTAINER_FILE=$(mktemp)
    NODE_RES_FILE=$(mktemp)
    POD_NS_FILE=$(mktemp)
    
    # Pods & Containers per Node
    kubectl get pods -A -o json | jq -r '.items[] | "\(.spec.nodeName) \(.spec.containers | length) \(.metadata.namespace)"' \
    | awk '{pods[$1]++; containers[$1]+=$2; ns[$1,$3]++} END {for (n in pods) print n, pods[n], containers[n]}' > $POD_CONTAINER_FILE

    # CPU & Memory per Node
    kubectl top nodes --no-headers | awk '{print $1, $2, $3}' > $NODE_RES_FILE

    # Pods per Namespace per Node
    kubectl get pods -A -o json | jq -r '.items[] | "\(.spec.nodeName) \(.metadata.namespace)"' | sort | uniq -c > $POD_NS_FILE

    # Print Node Summary
    printf "\n%-20s %-10s %-12s %-12s %-12s\n" "NODE" "PODS" "CONTAINERS" "CPU(cores)" "MEMORY"
    echo "---------------------------------------------------------------"
    while read -r line; do
        node=$(echo $line | awk '{print $1}')
        pods=$(echo $line | awk '{print $2}')
        containers=$(echo $line | awk '{print $3}')
        cpu=$(grep "^$node" $NODE_RES_FILE | awk '{print $2}')
        mem=$(grep "^$node" $NODE_RES_FILE | awk '{print $3}')
        printf "\033[1;32m%-20s %-10s %-12s %-12s %-12s\033[0m\n" "$node" "$pods" "$containers" "$cpu" "$mem"
    done < $POD_CONTAINER_FILE

    # Print Pods per Namespace per Node
    echo -e "\n\033[1;34m=== Pods per Namespace per Node ===\033[0m"
    awk '{count[$2,$3]=$1} END {for (k in count) {split(k,a,SUBSEP); printf "%-20s %-20s %s\n", a[1], a[2], count[k]}}' $POD_NS_FILE

    # Wait before refreshing
    sleep $INTERVAL
done
```

---

## 🔹 Usage

1. Save the script:

```bash
nano cluster-overview-live.sh
```

2. Make executable:

```bash
chmod +x cluster-overview-live.sh
```

3. Run it:

```bash
./cluster-overview-live.sh
```

* The output **refreshes every 5 seconds**.
* Shows **Pods, Containers, CPU & Memory**, and **Pods per Namespace per Node** live.

---

## 🔹 Sample Output (auto-refreshing)

```
=== Kubernetes Cluster Live Overview ===
Updated: Tue Sep 24 20:30:05 IST 2025

NODE                 PODS       CONTAINERS   CPU(cores)   MEMORY
---------------------------------------------------------------
worker-1             7          10           500m         1024Mi
worker-2             4          6            300m         512Mi
master               5          7            400m         768Mi

=== Pods per Namespace per Node ===
worker-1             default              5
worker-1             kube-system          2
worker-2             default              3
worker-2             kube-system          1
master               kube-system          5
```

---

### 🔹 Interview Tip

* Shows **real-time monitoring skills** without Prometheus/Grafana.
* You can say:

> “I can continuously monitor pods, containers, node CPU/memory, and namespace distribution using a simple script with `kubectl` and `jq`, which is handy for troubleshooting and capacity planning.”

---

If you want, I can **also make a version with color-coded alerts** (e.g., highlight nodes with CPU > 80% or pods pending) — this looks **super impressive in interviews**.

Ah! I see exactly what’s happening — let me break it down and give you a **step-by-step fix**.

Your errors:

1. `./cluster-overview-live.sh: line 20: jq: command not found`
2. `error: Metrics API not available`

---

## 🔹 Problem 1: `jq: command not found`

* The script uses `jq` to parse JSON from `kubectl get pods -o json`.
* `jq` is **not installed** on your system.

### ✅ Solution:

* Install `jq` depending on your OS:

**Ubuntu / Debian:**

```bash
sudo apt update
sudo apt install -y jq
```

**CentOS / RHEL / Fedora:**

```bash
sudo yum install -y epel-release
sudo yum install -y jq
```

**MacOS (Homebrew):**

```bash
brew install jq
```

* After installing, run:

```bash
jq --version
```

* Then rerun your script.

---

## 🔹 Problem 2: `Metrics API not available`

* The script uses `kubectl top nodes` to get CPU/Memory usage.
* This requires **metrics-server** installed in your cluster.

### ✅ Solution:

1. Check if metrics-server is installed:

```bash
kubectl get deployment metrics-server -n kube-system
```

* If it shows `NotFound`, install it.

2. Install metrics-server (example):

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

3. Wait a minute and test:

```bash
kubectl top nodes
kubectl top pods
```

* Now CPU & Memory usage should be visible.

---

## 🔹 Quick Fix if You Just Want Pod + Container Count

* If you **don’t care about CPU/Memory yet**, you can **comment out the `kubectl top nodes` part** in the script:

```bash
# kubectl top nodes --no-headers | awk '{print $1, $2, $3}' > $NODE_RES_FILE
```

* The script will still show **Pods + Containers + Pods per Namespace**.

---

✅ **Summary**

1. Install `jq` → fixes JSON parsing errors.
2. Install `metrics-server` → fixes CPU/Memory errors.
3. Optional: Comment out metrics section if you only want Pod/Container info.

---

If you want, I can **give you a fully fixed version of `cluster-overview-live.sh`** that **checks for `jq` and metrics-server**, and **gracefully skips metrics if not available**, so it runs without errors immediately.



