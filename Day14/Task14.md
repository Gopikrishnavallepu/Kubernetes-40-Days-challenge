# Day 14/40 - Taints and Tolerations in Kubernetes 📘🚀

## Check out the video below for Day14 👇

[![Day14/40 - Taints and Tolerations in Kubernetes](https://img.youtube.com/vi/nwoS2tK2s6Q/sddefault.jpg)](https://youtu.be/nwoS2tK2s6Q)

# Taints and Tolerations in Kubernetes 🚧📜

In this guide, we'll explore taints and tolerations in Kubernetes, essential tools for managing where pods can be scheduled in your cluster.

---

## Taints: Putting Up Fences 🚫

Think of taints as "only you are allowed" signs on your Kubernetes nodes. A taint marks a node with a specific characteristic, such as `"gpu=true"`. By default, pods cannot be scheduled on tainted nodes unless they have a special permission called toleration. When a toleration on a pod matches with the taint on the node then only that pod will be scheduled on that node.

---

## Tolerations: Permission Slips for Pods ✅

Toleration allows a pod to say, "Hey, I can handle that taint. Schedule me anyway!" You define tolerations in the pod specification to let them bypass the taints.

---

## Taints & Tolerations in Action 🎬

Here’s a breakdown of the commands to manage taints and tolerations:

### Tainting a Node:

```bash
kubectl taint nodes node1 key=gpu:NoSchedule
```

This command taints node1 with the key "gpu" and the effect "NoSchedule." Pods without a toleration for this taint won't be scheduled there.

To remove the taint , you add - at the end of the command , like below.

```bash
kubectl taint nodes node1 key=gpu:NoSchedule-
```

### Adding toleration to the pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: redis
  name: redis
spec:
  containers:
  - image: redis
    name: redis
  tolerations:
  - key: "gpu"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
```

>Note: This pod specification defines a toleration for the "gpu" taint with the effect "NoSchedule." This allows the pod to be scheduled on tainted nodes.

### Labels vs Taints/Tolerations

Labels group nodes based on size, type,env, etc. Unlike taints, labels don't directly affect scheduling but are useful for organizing resources.

### Limitations to Remember 🚧

Taints and tolerations are powerful tools, but they have limitations. They cannot handle complex expressions like "AND" or "OR." 
So, what do we use in that case? We use a combination of Taints, tolerance, and Node affinity, which we will discuss in the next video.


Of course. Here is a comprehensive guide to help you complete Task 14 of the #40DaysOfKubernetes challenge. This task is a deep dive into the important scheduling concept of **Taints and Tolerations**.

### Prerequisites: Kubernetes Cluster Setup

To begin this exercise, you need a multi-node Kubernetes cluster. If you don't already have one, you can set it up locally using **Kind (Kubernetes in Docker)**.

*   **Kind Installation and Multi-Node Cluster Creation**: The **Day 6 video** provides a step-by-step tutorial on how to install Kind and create a cluster with one control plane node and multiple worker nodes using a YAML configuration file.
*   **Port Binding for Kind Users**: As discussed in the **Day 9 video**, a standard Kind cluster does not expose node ports to your local machine (localhost). To access services externally, you need to add an `extraPortMappings` section to your Kind cluster configuration YAML. This is not strictly necessary for this specific task, but it's a good practice to be aware of for future exercises.

### Understanding Taints and Tolerations

Taints and Tolerations are a mechanism in Kubernetes that allows you to control which pods can be scheduled onto which nodes.

*   **Taint**: A taint is applied to a **node**. It acts as a "repellent," marking the node so that the scheduler will not place any pods on it unless the pod has a matching toleration. This is useful for dedicating nodes to specific types of workloads (e.g., nodes with GPUs) or for preventing custom workloads from running on control plane nodes.
*   **Toleration**: A toleration is applied to a **pod**. It allows (but does not require) the pod to be scheduled on a node with a matching taint. The scheduler will consider scheduling a pod with a toleration onto a tainted node if it meets other scheduling criteria.
*   **Effect**: Each taint has an effect, which determines what happens to pods that do not tolerate the taint. The main effects are:
    *   `NoSchedule`: Prevents new pods from being scheduled on the node unless they have a matching toleration. Existing pods are not affected.
    *   `PreferNoSchedule`: The scheduler will try to avoid placing pods without a matching toleration on the node, but it's not a strict requirement.
    *   `NoExecute`: Evicts existing pods from the node if they do not tolerate the taint and prevents new pods from being scheduled.

Now, let's walk through the task details step by step.

### 1. Taint Your Worker Nodes

First, you need to apply taints to your two worker nodes.

1.  **List your nodes** to get their names:
    ```bash
    kubectl get nodes
    ```
    You should see your control plane node and two worker nodes (e.g., `cka-cluster-3-worker`, `cka-cluster-3-worker2`).

2.  **Apply the taints** using the `kubectl taint` command:
    *   For the first worker node (`worker01`):
        ```bash
        kubectl taint node <worker01-name> gpu=true:NoSchedule
        ```
    *   For the second worker node (`worker02`):
        ```bash
        # Note: The task asks for gpu=false, so we will apply that here.
        kubectl taint node <worker02-name> gpu=false:NoSchedule
        ```

3.  **Verify the taints** by describing one of the nodes and filtering for the "Taints" field:
    ```bash
    kubectl describe node <worker01-name> | grep Taints
    ```
    You should see the taint `gpu=true:NoSchedule` listed.

### 2. Create a Pod and Observe Scheduling Failure

Now, create a simple Nginx pod without any tolerations and observe why it fails to get scheduled.

1.  **Run the command to create an Nginx pod**:
    ```bash
    kubectl run nginx --image=nginx
    ```

2.  **Check the pod's status**:
    ```bash
    kubectl get pods
    ```
    You will see that the `nginx` pod is stuck in the **Pending** state.

3.  **Investigate the reason** using `kubectl describe`:
    ```bash
    kubectl describe pod nginx
    ```
    In the `Events` section at the bottom, you will see a message explaining the scheduling failure. It will state that out of three available nodes, one has an untolerated taint for the control plane, and the other two have untolerated taints (`gpu=true` and `gpu=false`). The pod cannot be scheduled because it doesn't tolerate any of these taints.

### 3. Add a Toleration to a Pod

Next, you will create a new pod with a toleration that matches the taint on your first worker node.

1.  **Generate a YAML manifest** for a new pod. You can use the `--dry-run=client -o yaml` flag to create a template without creating the pod live:
    ```bash
    kubectl run redis --image=redis --dry-run=client -o yaml > redis-pod.yaml
    ```

2.  **Edit the `redis-pod.yaml` file** to add the `tolerations` block within the `spec` section. The toleration must match the taint on `worker01`.
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: redis
    spec:
      tolerations:
      - key: "gpu"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
      containers:
      - name: redis
        image: redis
    ```
    This configuration tells the scheduler that this pod can tolerate the `gpu=true:NoSchedule` taint.

3.  **Apply the manifest and verify**:
    ```bash
    kubectl apply -f redis-pod.yaml
    kubectl get pods -o wide
    ```
    You will see that the `redis` pod is now in the **Running** state and has been successfully scheduled on your first worker node (`worker01`), because it was able to tolerate the taint on that node. Meanwhile, the `nginx` pod remains pending.

### 4. Schedule a Pod on the Control Plane Node

By default, the control plane node has a taint to prevent regular workloads from being scheduled on it, ensuring its resources are reserved for control plane components. You will now remove this taint to schedule a pod there.

1.  **Describe the control plane node** to identify its default taint:
    ```bash
    kubectl describe node <control-plane-node-name> | grep Taints
    ```
    You will likely see a taint like `node-role.kubernetes.io/control-plane:NoSchedule`.

2.  **Remove the taint**. To do this, you use the `kubectl taint` command with the same key and effect, but add a hyphen (`-`) at the end:
    ```bash
    kubectl taint node <control-plane-node-name> node-role.kubernetes.io/control-plane:NoSchedule-
    ```

3.  **Create a new Redis pod** without any specific tolerations:
    ```bash
    kubectl run redis-new --image=redis
    ```

4.  **Verify the pod's location**:
    ```bash
    kubectl get pods -o wide
    ```
    The `redis-new` pod should now be scheduled and running on the **control plane node** because you removed the taint that was previously preventing it.

5.  **Add the taint back** to the control plane node to restore its default behavior:
    ```bash
    kubectl taint node <control-plane-node-name> node-role.kubernetes.io/control-plane:NoSchedule
    ```

### Share Your Learnings

This is a critical part of the #40DaysOfKubernetes challenge. After completing the hands-on tasks, it's time to document and share what you've learned.

*   **Write a blog post**: Explain the concept of Taints and Tolerations in your own words. Describe how taints are used to restrict scheduling on nodes and how tolerations allow pods to be scheduled on those restricted nodes. Document the commands you used and the outcomes you observed.
*   **Embed the video**: Include the Day 14 video in your blog post to provide visual context for your readers.
*   **Share on Social Media**: Post a link to your blog on platforms like LinkedIn or Twitter. Use the hashtag **`#40DaysOfKubernetes`** and tag the creator and the Cloud Ops community so your work can be seen and recognized. This practice helps solidify your understanding and showcases your skills to a wider audience.

If you face any issues, the dedicated Discord community is an excellent place to ask for help. Good luck with the task!