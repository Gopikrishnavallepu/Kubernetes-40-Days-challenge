# Day 16/40 - Kubernetes Requests and Limits

## Check out the video below for Day16 👇

[![Day12/40 - Kubernetes Requests and Limits](https://img.youtube.com/vi/Q-mk6EZVX_Q/sddefault.jpg)](https://youtu.be/Q-mk6EZVX_Q)


# Understanding Kubernetes Requests & Limits 🚀🔧

Welcome to the Kubernetes Requests & Limits guide! This document complements our video explaining managing resource allocation in your Kubernetes cluster. Let’s explore the essentials of Requests and Limits, why they matter, and how to use them effectively.

---

## 🏙️ What's the Deal with Requests & Limits?

Think of your Kubernetes cluster as a bustling city and pods as tenants in an apartment building. Each tenant (pod) requires specific resources like CPU and memory to function:

- **Requests**: This is the minimum amount of resources a pod needs to operate smoothly. Think of it as a guaranteed reservation for the pod.
- **Limits**: This is the maximum amount of resources a pod can use. It acts as a safety cap to prevent any pod from consuming more than its fair share and disrupting others.

---

## 🧐 Why are Requests & Limits Important?

- **Resource Control**: By setting limits, you prevent a single pod from monopolizing resources, which can lead to issues like out-of-memory (OOM) kills or CPU starvation. ☠️ Why OOM can be a good thing? Because it kills the pod; otherwise, the container would have consumed all the memory and could kill the node. Killing the pod is a better option than killing a node itself.
- **Predictability**: Requests help the scheduler allocate resources efficiently and ensure pods have the necessary resources to run effectively.

---

## 🔍 Exploring Resource Management in Action

In our video, we demonstrated some practical examples using YAML files and Kubernetes commands:

1. **Exceeding Available Memory**:
   - A pod requesting more memory than is available will be killed due to an OOM (Out of Memory) error.
     
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo-2
  namespace: mem-example
spec:
  containers:
  - name: memory-demo-2-ctr
    image: polinux/stress
    resources:
      requests:
        memory: "50Mi"
      limits:
        memory: "100Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "250M", "--vm-hang", "1"]
```

2. The Below pod will be scheduled

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo
  namespace: mem-example
spec:
  containers:
  - name: memory-demo-ctr
    image: polinux/stress
    resources:
      requests:
        memory: "100Mi"
      limits:
        memory: "200Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
```


Of course. Here is a comprehensive guide to help you complete the task on **Resource Requests and Limits** in Kubernetes, which appears to be Day 16 of the #40DaysOfKubernetes series. This guide synthesizes information from the provided sources to explain the concepts and walk you through the required steps.

### Prerequisites: Kubernetes Cluster Setup

Before starting, you need a multi-node Kubernetes cluster. The sources recommend setting one up locally using **Kind (Kubernetes in Docker)**, as it provides a realistic environment for learning.

*   **Cluster Creation**: The **Day 6 video** provides a step-by-step guide on installing Kind and creating a multi-node cluster (e.g., one control plane, two worker nodes) using a `config.yaml` file.
*   **Port Binding (for Kind users)**: For some tasks, you may need to expose ports from your Kind cluster to your local machine (localhost). This is done by adding an `extraPortMappings` section to your Kind configuration YAML, as explained in the **Day 9 video**. This step is not strictly necessary for this specific exercise but is a good practice for accessing services externally.
*   **Set Alias (Optional but Recommended)**: To save time, you can create a shell alias for `kubectl`. For example, `alias k=kubectl`. This is a common practice that makes running commands much faster.

### Understanding Resource Requests and Limits

In Kubernetes, you can specify how much CPU and memory (RAM) each container in a pod needs. This is a crucial concept for cluster resource management and pod scheduling.

*   **Requests**: This is the **minimum amount** of a resource (like CPU or memory) that a container is guaranteed to get. The Kubernetes Scheduler uses the request value to decide which node to place a pod on. A pod will only be scheduled on a node that can satisfy the total resource requests of all its containers.
*   **Limits**: This is the **maximum amount** of a resource that a container is allowed to use. If a container exceeds its memory limit, it will be terminated with an "Out of Memory" (OOM) error. If it tries to exceed its CPU limit, its CPU usage will be throttled.

**Why is this important?**
If you don't set limits, a single faulty or resource-intensive pod could consume all the resources on a node, potentially causing the node itself to crash and affecting all other pods running on it. Setting requests and limits ensures predictable performance and prevents one pod from starving others of resources.

Now, let's walk through the task details step by step.

### 1. Create a New Namespace

Namespaces provide a way to logically isolate groups of resources within a single cluster. This is useful for separating environments (like dev and prod) or different applications.

You can create a namespace using an imperative command, which is often faster for simple tasks.

```bash
# Use your alias 'k' if you have set it, otherwise use 'kubectl'
kubectl create namespace mem-example
```

You can verify that the namespace was created with `kubectl get namespace` or its shorter alias `kubectl get ns`.

### 2. Install the Metrics Server

To observe resource usage with commands like `kubectl top`, you need the **Metrics Server**. This component collects resource metrics like CPU and memory utilization from the nodes and pods in your cluster. It's a Kubernetes add-on that typically runs in the `kube-system` namespace.

1.  **Download the Manifest**: The task requires you to use the `metrics-server.yaml` file provided in the repository for the series (likely in the `day16` folder).
2.  **Apply the Manifest**:
    ```bash
    # Navigate to the folder containing the yaml file
    kubectl apply -f metrics-server.yaml
    ```
    This will create several Kubernetes objects, including a Deployment, Service, and necessary RBAC roles.

3.  **Verify Installation**: After a minute or two, check if the Metrics Server pod is running in the `kube-system` namespace.
    ```bash
    kubectl get pods -n kube-system
    ```
    Once the pod is running, you can test it by running `kubectl top nodes`, which should show you the current CPU and memory usage for each node in your cluster.

### 3. Perform the Steps from the Kubernetes Documentation

The final part of the task is to follow the official Kubernetes documentation for assigning memory resources. This involves creating pods with different memory request and limit configurations and observing the outcome. The documentation you were pointed to covers three main scenarios.

**Scenario 1: Specify a Memory Request and a Memory Limit**

This is the standard, recommended practice. You create a pod where the container requests a certain amount of memory and is limited to a slightly higher amount.

1.  **Create the YAML Manifest**: Create a file named `memory-request-limit.yaml`. The YAML defines a pod that requests **100 MiB** of memory and is limited to **200 MiB**.
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: memory-demo
      namespace: mem-example # Ensure the pod is created in the correct namespace
    spec:
      containers:
      - name: memory-demo-ctr
        image: polinux/stress # This image is designed for stress testing
        resources:
          requests:
            memory: "100Mi"
          limits:
            memory: "200Mi"
        args:
        - --vm
        - "1"
        - --vm-bytes
        - "150M" # The pod's process will try to allocate 150MB of RAM
        - --vm-hang
        - "1"
    ```
2.  **Apply and Verify**:
    *   `kubectl apply -f memory-request-limit.yaml`
    *   Check the pod's status with `kubectl get pod memory-demo -n mem-example`. It should be `Running`.
    *   Use `kubectl top pod memory-demo -n mem-example` to see its memory consumption. It will be around 150 MiB, which is within its 200 MiB limit.

**Scenario 2: Exceed a Container's Memory Limit**

Here, you'll create a pod that tries to allocate more memory than its limit, causing it to be terminated.

1.  **Create the YAML Manifest**: Create `memory-request-limit-2.yaml`. This pod is limited to **100 MiB** but its process tries to allocate **250 MiB**.
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: memory-demo-2
      namespace: mem-example
    spec:
      containers:
      - name: memory-demo-2-ctr
        image: polinux/stress
        resources:
          limits:
            memory: "100Mi" # The limit is 100 MiB
        args:
        - --vm
        - "1"
        - --vm-bytes
        - "250M" # The process attempts to use 250 MB
        - --vm-hang
        - "1"
    ```
2.  **Apply and Observe**:
    *   `kubectl apply -f memory-request-limit-2.yaml`
    *   Check the pod's status with `kubectl get pod memory-demo-2 -n mem-example`. You will see its status as **`OOMKilled`** (Out of Memory Killed).
    *   Use `kubectl describe pod memory-demo-2 -n mem-example` to see the events. It will show that the container was killed because it exceeded its memory limit.

**Scenario 3: Specify a Memory Request that is Too Big for the Nodes**

In this final scenario, you'll create a pod that requests more memory than any single node has available, so it will never be scheduled.

1.  **Create the YAML Manifest**: Create `memory-request-limit-3.yaml`. This pod requests an impossibly large amount of memory, such as **1000 GiB**.
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: memory-demo-3
      namespace: mem-example
    spec:
      containers:
      - name: memory-demo-3-ctr
        image: polinux/stress
        resources:
          requests:
            memory: "1000Gi" # Requesting an amount larger than any node's capacity
        args:
        - --vm
        - "1"
        - --vm-bytes
        - "150M"
        - --vm-hang
        - "1"
    ```
2.  **Apply and Observe**:
    *   `kubectl apply -f memory-request-limit-3.yaml`
    *   Check the pod's status with `kubectl get pod memory-demo-3 -n mem-example`. It will remain in the **`Pending`** state indefinitely.
    *   Use `kubectl describe pod memory-demo-3 -n mem-example` to see why. The events will show an "insufficient memory" error, indicating that the scheduler could not find a node with enough allocatable memory to satisfy the pod's request.

This exercise provides a practical demonstration of how requests and limits are enforced by Kubernetes, which is fundamental to running stable and reliable applications.