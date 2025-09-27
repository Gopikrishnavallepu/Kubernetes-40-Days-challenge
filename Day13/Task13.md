# Day 13/40 - static pods, manual scheduling, labels, and selectors in Kubernetes 📘🚀

## Check out the video below for Day13 👇

[![Day12/40 - Kubernetes Daemonset Explained - Daemonsets, Job and Cronjob in Kubernetes](https://img.youtube.com/vi/6eGf7_VSbrQ/sddefault.jpg)](https://youtu.be/6eGf7_VSbrQ)


Welcome to the quick reference guide for our Kubernetes Labels, Selectors, and Static Pods video! This guide will be handy as you dive deeper into Kubernetes, especially if you're starting. Let's explore these concepts in detail:

---

## 📌 Labels and Selectors in Kubernetes

### Labels 🏷️
Labels are key-value pairs attached to Kubernetes objects like pods, services, and deployments. They help organize and group resources based on criteria that make sense to you.

**Examples of Labels:**
- `environment: production`
- `type: backend`
- `tier: frontend`
- `application: my-app`

### Selectors 🔍
Selectors filter Kubernetes objects based on their labels. This is incredibly useful for querying and managing a subset of objects that meet specific criteria.

**Common Usage:**
- **Pods**: `kubectl get pods --selector app=my-app`
- **Deployments**: Used to filter the pods managed by the deployment.
- **Services**: Filter the pods to which the service routes traffic.

### Labels vs. Namespaces 🌍
- **Labels**: Organize resources within the same or across namespaces.
- **Namespaces**: Provide a way to isolate resources from each other within a cluster.

### Annotations 📝
Annotations are similar to labels but attach non-identifying metadata to objects. For example, recording the release version of an application for information purposes or last applied configuration details etc.

---

## 🛠️ Static Pods

Static Pods are special types of pods managed directly by the `kubelet` on each node rather than through the Kubernetes API server.

### Key Characteristics of Static Pods:
- **Not Managed by the Scheduler**: Unlike deployments or replicasets, the Kubernetes scheduler does not manage static pods.
- **Defined on the Node**: Configuration files for static pods are placed directly on the node's file system, and the `kubelet` watches these files.
- **Some examples of static pods are:** ApiServer, Kube-scheduler, controller-manager, ETCD etc
  
### Managing Static Pods:
1. **SSH into the Node**: You will gain access to the node where the static pod is defined.(Mostly the control plane node)
2. **Modify the YAML File**: Edit or create the YAML configuration file for the static pod.
3. **Remove the Scheduler YAML**: To stop the pod, you must remove or modify the corresponding file directly on the node.
4. **Default location**": is usually `/etc/kubernetes/manifests/`; you can place the pod YAML in the directory, and Kubelet will pick it for scheduling.

## 🧭 Manual Pod Scheduling

Manual scheduling in Kubernetes involves assigning a pod to a specific node rather than letting the scheduler decide.

### Key Points:
- **`nodeName` Field**: Use this field in the pod specification to specify the node where the pod should run.
- **No Scheduler Involvement**: When `nodeName` is specified, the scheduler bypasses the pod, and it’s directly assigned to the given node.

### Example Configuration:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: manual-scheduled-pod
spec:
  nodeName: worker-node-1
  containers:
  - name: nginx
    image: nginx
```

>Note: Kubernetes will place the pod on worker-node-1 with the above configuration.




Of course. Here is a comprehensive guide to help you complete Task 13 of the "40 Days of Kubernetes" challenge, which covers static pods, manual scheduling, labels, and selectors. I will draw on the provided sources to explain the concepts and guide you through the hands-on steps.

### Prerequisites: Kubernetes Cluster Setup

Before starting, you need a multi-node Kubernetes cluster. If you don't have one, the **Day 6 video** provides detailed instructions for setting up a local cluster using **Kind (Kubernetes in Docker)**.

*   **Kind Setup**: Kind runs a Kubernetes cluster using Docker containers as nodes. The Day 6 video guides you through creating a configuration YAML file to set up a cluster with one control plane node and multiple worker nodes.
*   **Port Binding**: If you are using Kind, remember that you might need to map ports from the container nodes to your local machine (localhost) to access services externally. This process, known as port binding, is explained in the **Day 9 video**.

### 1. Static Pods and Control Plane Components

In a typical Kubernetes setup, the **Scheduler** is a control plane component responsible for deciding which node a new pod should run on. It monitors for pods that are in a pending state and, based on various factors, assigns them to a suitable worker node.

However, this presents a "chicken-and-egg" problem: if the Scheduler itself runs as a pod, who schedules the Scheduler pod? The answer lies in the concept of **static pods**.

**Static pods** are managed directly by the `kubelet` daemon on a specific node, without the intervention of the API server or the Scheduler. The control plane components, including the API server, Scheduler, Controller Manager, and etcd, run as static pods. The `kubelet` on the control plane node monitors a specific directory for pod manifest files (YAMLs). If a manifest is present, `kubelet` ensures the corresponding pod is running. If the manifest is removed, `kubelet` terminates the pod.

**Task: Restart Control Plane Components**

1.  **Login to the Control Plane Node**:
    *   First, identify the name of your control plane node. Since Kind uses Docker containers for nodes, you can list them with `docker ps`.
        ```bash
        docker ps
        ```
    *   Find the container corresponding to your control plane node (e.g., `cka-cluster-3-control-plane`).
    *   Use `docker exec` to get a shell inside the control plane container.
        ```bash
        docker exec -it <control-plane-container-name> bash
        ```

2.  **Navigate to the Static Pod Manifests Directory**:
    *   The manifest files for static pods are typically located in `/etc/kubernetes/manifests`.
    *   Navigate to this directory and list its contents:
        ```bash
        cd /etc/kubernetes/manifests
        ls
        ```
    *   You will see the YAML files for components like `kube-apiserver.yaml`, `kube-controller-manager.yaml`, and `kube-scheduler.yaml`.

3.  **Restart the Scheduler**:
    *   To simulate a scheduler failure and restart it, you can temporarily move its manifest file out of the directory. The `kubelet` will detect the file's removal and stop the scheduler pod.
        ```bash
        # Move the scheduler manifest to a temporary directory
        mv kube-scheduler.yaml /tmp/
        ```
    *   In another terminal, you can verify that the `kube-scheduler` pod is no longer running using `kubectl get pods -n kube-system`. New pods you try to create will get stuck in a "Pending" state because there's no scheduler to assign them to a node.
    *   To restart the scheduler, move the manifest file back into the directory. `kubelet` will detect the file and start the pod again.
        ```bash
        # Move the manifest back to restart the scheduler
        mv /tmp/kube-scheduler.yaml .
        ```
    *   You can verify in the other terminal that the `kube-scheduler` pod is running again.

### 2. Manual Pod Scheduling

While the Scheduler is the primary component for assigning pods to nodes, you can also schedule a pod manually by bypassing the scheduler.

The scheduler identifies pods to schedule by looking for a pod in a "Pending" state that does not have the `spec.nodeName` field specified. If you specify a `nodeName` in your pod's manifest, the scheduler will ignore it, and the `kubelet` on the specified node will run the pod directly. This demonstrates manual scheduling.

**Task: Create and Manually Schedule a Pod**

1.  **Stop the Scheduler** (optional, but demonstrates the concept): Follow the steps in the previous section to temporarily move the `kube-scheduler.yaml` manifest file, effectively stopping the scheduler.

2.  **Create a Pod Manifest with `nodeName`**:
    *   Generate a basic pod YAML file. You can use the `--dry-run=client -o yaml` flags to create a template without actually creating the pod.
        ```bash
        kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml
        ```
    *   Edit the `pod.yaml` file. Add the `nodeName` field inside the `spec` section and specify the name of one of your worker nodes (e.g., `cka-cluster-3-worker`).
        ```yaml
        apiVersion: v1
        kind: Pod
        metadata:
          name: nginx
          labels:
            run: nginx
        spec:
          nodeName: cka-cluster-3-worker # Add this line
          containers:
          - image: nginx
            name: nginx
        ```

3.  **Apply the Manifest and Verify**:
    *   Apply the manifest to create the pod.
        ```bash
        kubectl apply -f pod.yaml
        ```
    *   Check the pod's status. Even with the scheduler down, the pod will be scheduled and start running.
        ```bash
        kubectl get pods -o wide
        ```
    *   The output will show that the pod is running on the specific worker node you designated in the `nodeName` field.

4.  **Restart the Scheduler**: Remember to move the `kube-scheduler.yaml` file back to `/etc/kubernetes/manifests` to bring the scheduler back online.

### 3. Labels and Selectors

**Labels** are key-value pairs that you can attach to Kubernetes objects like pods, deployments, and services. They are used to organize and select subsets of objects. For example, you can label pods based on their environment (`dev`, `test`, `prod`), tier (`frontend`, `backend`), or application version.

**Selectors** allow you to filter and select objects based on their labels. This is a fundamental mechanism in Kubernetes. For instance, a Service uses a selector to identify the set of pods it should route traffic to, and a ReplicaSet uses a selector to manage its pods.

**Task: Create and Filter Pods with Labels**

1.  **Create Three Labeled Pods**: Create three separate YAML files or a single multi-object YAML for three Nginx pods named `pod1`, `pod2`, and `pod3`. Assign a unique label to each.
    *   `pod1` with label `env: test`
    *   `pod2` with label `env: dev`
    *   `pod3` with label `env: prod`

    Here's an example for `pod1`:
    ```yaml
    # pod1.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: pod1
      labels:
        env: test
    spec:
      containers:
      - name: nginx-container
        image: nginx
    ```

2.  **Apply the Manifests**: Create all three pods using `kubectl apply -f <filename>`.

3.  **Filter Pods Using Selectors**:
    *   Use the `-l` or `--selector` flag with `kubectl get pods` to filter the pods by their labels.
    *   To filter for pods with labels `env=dev` OR `env=prod`, you can use a comma-separated list, which acts as an `OR` operator. The query in the task seems to imply an "AND" which would return nothing since no single pod has both labels. Assuming the goal is to see pods from either environment:
        ```bash
        kubectl get pods -l 'env in (dev, prod)' --show-labels
        ```
        or
        ```bash
        kubectl get pods -l 'env=dev,env=prod'
        ```
        This command will list `pod2` and `pod3`, which have the specified `env` labels. The `--show-labels` flag is useful to verify the labels on the returned pods.

### Share Your Learnings

As part of the **#40DaysOfKubernetes challenge**, documenting and sharing your progress is a crucial step.
*   **Write a blog post**: Explain the concepts you've learned, such as the role of static pods for the control plane, how manual scheduling works by setting the `nodeName`, and the power of labels and selectors for organizing resources.
*   **Share on Social Media**: Post a link to your blog on platforms like LinkedIn and Twitter.
*   **Use the Hashtag**: Make sure to use the `#40DaysOfKubernetes` hashtag in your posts so the community and creator can see your work. This practice helps solidify your knowledge and showcases your skills to potential employers.

If you run into any issues, you can seek assistance in the dedicated Discord community for the series. Good luck!