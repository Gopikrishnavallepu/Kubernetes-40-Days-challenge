# Day 15/40 - Kubernetes node affinity explained

## Check out the video below for Day12 👇

[![Day15/40 - Kubernetes node affinity explained](https://img.youtube.com/vi/5vimzBRnoDk/sddefault.jpg)](https://youtu.be/5vimzBRnoDk)


## Beyond Node Selectors: Introducing Affinity 🚀

Node Selectors are great for basic pod placement based on node labels. But what if you need more control over where your pods land? Enter **Node Affinity**! This feature offers advanced capabilities to fine-tune pod scheduling in your Kubernetes cluster.

---

## Node Affinity: The Powerhouse 🔥

Node Affinity lets you define complex rules for where your pods can be scheduled based on node labels. Think of it as creating a wishlist for your pod's ideal home!

### Key Features:
- **Flexibility**: Define precise conditions for pod placement.
- **Control**: Decide where your pods can and cannot go with greater granularity.
- **Adaptability**: Allow pods to stay on their nodes even if the labels change after scheduling.

---

## Properties in Node Affinity
- requiredDuringSchedulingIgnoredDuringExecution
- preferredDuringSchedulingIgnoredDuringExecution

## Required During Scheduling, Ignored During Execution 🛠️

This is the strictest type of Node Affinity. Here's how it works:

1. **Specify Node Labels**: Define a list of required node labels (e.g., `disktype=ssd`) in your pod spec.
2. **Exact Match Requirement**: The scheduler only places the pod on nodes with those exact labels.
3. **Execution Consistency**: Once scheduled, the pod remains on the node even if the label changes.

### Example: Targeting SSD Nodes 💾

Suppose your pod needs high-speed storage. You can create a deployment with a Node Affinity rule that targets nodes labeled `disktype=ssd`.

**YAML Configuration:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: redis
  name: redis-3
spec:
  containers:
  - image: redis
    name: redis
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
              - key: disktype
                operator: In
                values:
                - ssd
```

Of course. Here is a comprehensive guide to help you complete the exercise on **Node Affinity** in Kubernetes, which appears to be the next task in the #40DaysOfKubernetes series. This guide draws upon the concepts discussed in the provided sources, including Taints and Tolerations, which share similarities with Node Affinity, and the necessary prerequisites for setting up your cluster.

### Prerequisites: Kubernetes Cluster Setup

To perform this exercise, you'll need a running multi-node Kubernetes cluster. The sources recommend setting one up locally using **Kind (Kubernetes in Docker)**.

*   **Cluster Creation**: The **Day 6 video** provides detailed, step-by-step instructions on how to install Kind and create a multi-node cluster (e.g., one control plane, two worker nodes) using a YAML configuration file.
*   **Port Binding (for Kind users)**: If you plan to expose services to your local machine (localhost), the **Day 9 video** explains how to add an `extraPortMappings` section to your Kind configuration YAML. This step is crucial for making services like NodePort accessible from outside the Kind Docker network but is not strictly required for this specific Node Affinity task.

### Understanding Node Affinity

In the previous exercise, you explored Taints and Tolerations, where a **node** repels pods, and pods must have a toleration to be scheduled on that node. You also looked at Node Selectors, where a **pod** specifies a label that a node must have.

**Node Affinity** is an advanced and more flexible version of Node Selector. It allows you to create more complex scheduling rules based on node labels. Unlike Node Selectors which use simple key=value matching, Node Affinity supports more expressive rules like `In`, `NotIn`, and `Exists`.

Node Affinity comes in two main types:

1.  **`requiredDuringSchedulingIgnoredDuringExecution`**: This is a "hard" requirement. The pod **will not be scheduled** unless a node meets the specified affinity rules. If the node's labels change after the pod is scheduled, the pod will continue running on that node (hence `IgnoredDuringExecution`).
2.  **`preferredDuringSchedulingIgnoredDuringExecution`**: This is a "soft" requirement. The scheduler will **try to find a node** that meets the affinity rules. If it can't find one, it will schedule the pod on any available node.

Now, let's walk through the task details.

### 1. Create a Pod with a "Hard" Node Affinity Rule

Your first task is to create a pod that requires a node with the label `disktype=ssd`.

1.  **Create the Pod Manifest**: Generate a YAML file for an Nginx pod and add the `affinity` spec.
    ```yaml
    # pod1.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx-affinity-pod
    spec:
      containers:
      - name: nginx
        image: nginx
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: disktype
                operator: In
                values:
                - ssd
    ```
    *   `affinity.nodeAffinity`: Specifies the node affinity rules.
    *   `requiredDuringSchedulingIgnoredDuringExecution`: Enforces a strict scheduling rule.
    *   `matchExpressions`: Defines the conditions. Here, the node must have a label with the `key` "disktype" and its value must be `In` the list of `values` (in this case, just "ssd").

2.  **Apply and Check Pod Status**: Apply the manifest and then check why the pod isn't running.
    ```bash
    kubectl apply -f pod1.yaml
    kubectl get pods
    ```
    The pod will be stuck in the **Pending** state. To see why, use `kubectl describe`:
    ```bash
    kubectl describe pod nginx-affinity-pod
    ```
    In the `Events` section, you'll see a message similar to "0/3 nodes are available: 2 node(s) didn't match pod's node affinity/selector, 1 node(s) had untolerated taint". This confirms that no node has the required `disktype=ssd` label.

3.  **Label a Worker Node**: Add the required label to one of your worker nodes (e.g., `cka-cluster-3-worker`).
    ```bash
    # First, get your node names
    kubectl get nodes

    # Apply the label to worker01
    kubectl label node <your-worker01-name> disktype=ssd
    ```
    You can verify the label was added with `kubectl get nodes --show-labels`.

4.  **Check Pod Status Again**:
    ```bash
    kubectl get pods -o wide
    ```
    Almost immediately after you apply the label, the scheduler will find a matching node, and the pod will transition to the **Running** state. The `-o wide` flag will show that it has been scheduled on the worker node you just labeled.

### 2. Create a Pod with an "Exists" Operator

Your next task is to schedule a Redis pod on a node that simply has the `disktype` label, regardless of its value.

1.  **Create the Pod Manifest**: Create a new YAML file for a Redis pod. This time, you will use the `Exists` operator, which only checks for the presence of a key and doesn't require any values.
    ```yaml
    # pod2.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: redis-affinity-pod
    spec:
      containers:
      - name: redis
        image: redis
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: disktype
                operator: Exists
    ```
    The `Exists` operator checks if a node has a label with the specified `key` (`disktype`). The `values` field should be omitted when using this operator.

2.  **Label the Second Worker Node**: Apply the `disktype` label to your second worker node without assigning it a value.
    ```bash
    kubectl label node <your-worker02-name> disktype=
    ```
    Adding an equals sign with no value creates a label with an empty string as its value, which satisfies the `Exists` condition.

3.  **Apply and Verify**:
    ```bash
    kubectl apply -f pod2.yaml
    kubectl get pods -o wide
    ```
    The `redis-affinity-pod` should quickly enter the **Running** state and be scheduled on your second worker node, as it now meets the `Exists` criteria.

