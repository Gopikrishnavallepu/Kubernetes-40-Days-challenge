## Check out the task.md file for the hands-on exercises

## Cheatsheet for Kubernetes commands:
https://kubernetes.io/docs/reference/kubectl/quick-reference/

### Replicaset
https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/3e9792d4-1127-44b4-a6ec-cdc2a82219e3)


### Deployment
https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/b888d272-c623-4a00-8381-45c25ce9d9c0)


### Replication Controller
https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/

Of course. Based on the new sources you've provided, here's a detailed overview of Replication Controllers, ReplicaSets, and Deployments in Kubernetes, incorporating the key concepts from our conversation and the new material.

It looks like you're diving into some of the core workload controllers in Kubernetes. These objects are essential for ensuring application availability, scalability, and managing updates. Let's break down each concept.

### Replication Controller

A **Replication Controller** is an older, legacy Kubernetes object whose primary job is to ensure that a specified number of pod replicas are running at any given time. It provides a basic level of high availability and self-healing.

*   **Core Function**: It continuously monitors the running pods and if a pod fails, crashes, or is deleted, the Replication Controller will automatically spin up a new one to maintain the desired count.
*   **Manual Scaling**: It allows you to manually scale your application by changing the `replicas` field in its manifest.
*   **Use Case**: For instance, if you have a pod serving users and it crashes, the Replication Controller ensures a new pod is created, minimizing downtime for the user. You can also specify multiple replicas to handle increased traffic and ensure high availability from the start.
*   **YAML Definition**: To create a Replication Controller, you define a manifest file with `kind: ReplicationController`. The `spec` section includes a `replicas` count and a `template` which contains the metadata and spec for the pods it will manage.

Here is an example structure for a Replication Controller YAML:
```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx-rc
spec:
  replicas: 3
  template:
    metadata:
      labels:
        env: demo
    spec:
      containers:
      - name: nginx-container
        image: nginx
```
*I've created this example based on information from the sources. It demonstrates the structure described.*

### ReplicaSet

A **ReplicaSet** is the next-generation replacement for the Replication Controller. While it performs the same fundamental task—ensuring a stable set of replica pods are running—it introduces more powerful and flexible selectors.

*   **Key Difference**: The most significant difference is its **selector capability**. While a Replication Controller uses simple equality-based selectors (e.g., `env=demo`), a ReplicaSet can use more expressive set-based selectors like `in`, `notin`, and `exists`.
*   **Managing Existing Pods**: This advanced selector allows a ReplicaSet to manage existing pods that were not created as part of the ReplicaSet, as long as their labels match the selector.
*   **YAML Definition**: The `apiVersion` for a ReplicaSet is typically `apps/v1`. The `spec` section is similar to a Replication Controller but includes a `selector` block with `matchLabels` to define which pods it should manage.

Here's an example structure for a ReplicaSet YAML:
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      env: demo
  template:
    metadata:
      labels:
        env: demo
    spec:
      containers:
      - name: nginx-container
        image: nginx
```
*This example is based on information from the sources to illustrate the structure.*

### Deployment

A **Deployment** is a higher-level controller that manages ReplicaSets and Pods, providing declarative updates and other useful features. In modern Kubernetes, you will almost always interact with Deployments rather than creating ReplicaSets directly.

*   **Manages ReplicaSets**: When you create a Deployment, it automatically creates a ReplicaSet in the background. The ReplicaSet then manages the pods. This layered approach allows for more sophisticated management.
*   **Rolling Updates**: The primary advantage of a Deployment is its ability to perform **rolling updates**. When you update the pod template (e.g., changing the container image version), the Deployment ensures zero downtime by gradually replacing old pods with new ones. While a new pod is being created, traffic is served by the old, stable pods.
*   **Rollbacks**: Deployments maintain a history of revisions, allowing you to easily roll back to a previous, stable version if an update fails or introduces bugs. You can view the rollout history and undo a rollout with `kubectl rollout` commands.
*   **Scaling**: Like ReplicaSets, Deployments can be scaled manually by updating the `replicas` count. This can be done by editing the YAML, using `kubectl edit`, or with the `kubectl scale` command.

Using a Deployment abstracts away the complexity of managing ReplicaSets directly and provides crucial features for production environments, such as controlled updates and rollbacks.

I hope this overview helps clarify the roles of these essential Kubernetes objects! Let me know if you have more questions.

Of course. Here is a step-by-step guide to completing the hands-on exercises for ReplicaSets and Deployments, using the concepts from our conversation and the provided sources.

### Note on Setting Up Your Cluster

Before starting, ensure you have a running Kubernetes cluster. As noted in the sources, you can create a local Kubernetes cluster using `kind`. You will also need the `kubectl` command-line utility installed to interact with the cluster. Remember to use `kubectl config use-context` to switch to the correct cluster if you have multiple clusters running.

### Part 1: ReplicaSet Exercises

A **ReplicaSet** is a Kubernetes object that ensures a specified number of pod replicas are running at any given time. It uses powerful set-based selectors to manage pods.

#### 1. Create a ReplicaSet with 3 Replicas

First, we will create a ReplicaSet declaratively using a YAML file. You can generate a base YAML file and then modify it to suit your needs.

1.  **Generate and create the YAML file:**
    A ReplicaSet manifest requires `apiVersion: apps/v1`, `kind: ReplicaSet`, and `metadata`. The `spec` must include the `replicas` count, a `selector` with `matchLabels`, and a `template` for the pods it will manage.

    Let's create a file named `rs.yaml`:
    ```bash
    vi rs.yaml
    ```
    Paste the following content into the file:
    ```yaml
    apiVersion: apps/v1
    kind: ReplicaSet
    metadata:
      name: nginx-rs
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nginx-pods
      template:
        metadata:
          labels:
            app: nginx-pods
        spec:
          containers:
          - name: nginx
            image: nginx
    ```

2.  **Apply the YAML to create the ReplicaSet:**
    Use the `kubectl apply` command, which is suitable for both creating and updating resources.
    ```bash
    kubectl apply -f rs.yaml
    ```

3.  **Verify the creation:**
    Check the status of the ReplicaSet and the pods.
    ```bash
    kubectl get rs
    # NAME       DESIRED   CURRENT   READY   AGE
    # nginx-rs   3         3         3       15s

    kubectl get pods
    # NAME             READY   STATUS    RESTARTS   AGE
    # nginx-rs-5z7f7   1/1     Running   0          25s
    # nginx-rs-g9h2l   1/1     Running   0          25s
    # nginx-rs-j8w8q   1/1     Running   0          25s
    ```

#### 2. Update Replicas to 4 from YAML

You can scale a ReplicaSet by modifying its manifest file and re-applying it.

1.  **Edit the `rs.yaml` file:**
    Open the `rs.yaml` file and change the `replicas` field from `3` to `4`.
    ```bash
    vi rs.yaml
    ```
    ```yaml
    #...
    spec:
      replicas: 4
    #...
    ```

2.  **Apply the updated YAML:**
    ```bash
    kubectl apply -f rs.yaml
    ```

3.  **Verify the update:**
    You should now see 4 pods running.
    ```bash
    kubectl get pods
    # NAME             READY   STATUS    RESTARTS   AGE
    # nginx-rs-5z7f7   1/1     Running   0          1m
    # nginx-rs-g9h2l   1/1     Running   0          1m
    # nginx-rs-j8w8q   1/1     Running   0          1m
    # nginx-rs-x5v9p   1/1     Running   0          10s
    ```

#### 3. Update Replicas to 6 from the Command Line

For quick scaling operations, the imperative `kubectl scale` command is very efficient.

1.  **Scale the ReplicaSet using the command:**
    ```bash
    kubectl scale --replicas=6 rs/nginx-rs
    ```
    *Note: `rs/nginx-rs` specifies the resource type (ReplicaSet) and its name.*

2.  **Verify the final state:**
    ```bash
    kubectl get rs
    # NAME       DESIRED   CURRENT   READY   AGE
    # nginx-rs   6         6         6       2m

    kubectl get pods
    # You will see 6 running pods
    ```

### Part 2: Deployment Exercises

A **Deployment** is a higher-level object that manages ReplicaSets, providing declarative updates and rollbacks. When you create a Deployment, it automatically creates a ReplicaSet to manage the pods. This is the preferred way to manage stateless applications in production.

#### 1. Create a Deployment

1.  **Create the YAML file `deployment.yaml`:**
    You can generate a template using the `kubectl create deployment` command with `--dry-run=client -o yaml`.
    ```bash
    kubectl create deployment nginx --image=nginx:1.23.0 --replicas=3 --dry-run=client -o yaml > deployment.yaml
    ```

2.  **Edit the YAML to add the required labels:**
    Open `deployment.yaml` and add the `tier: backend` label to the Deployment's metadata and the `app: v1` label to the pod template's metadata.
    ```bash
    vi deployment.yaml
    ```
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx
      labels:
        tier: backend # Added this label for the Deployment
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: v1 # Ensure this matches the template label
      template:
        metadata:
          labels:
            app: v1 # Added this label for the Pods
        spec:
          containers:
          - image: nginx:1.23.0
            name: nginx
    ```
    *Note: I also updated `selector.matchLabels` to match the pod template label, which is a requirement.*

3.  **Apply the YAML:**
    ```bash
    kubectl apply -f deployment.yaml
    ```

#### 2. List the Deployment and Verify Replicas

```bash
kubectl get deployment
# NAME    READY   UP-TO-DATE   AVAILABLE   AGE
# nginx   3/3     3            3           20s

kubectl get pods --show-labels
# NAME                    READY   STATUS    RESTARTS   AGE   LABELS
# nginx-6b76c7c4d-abcde   1/1     Running   0          30s   app=v1,pod-template-hash=...
# nginx-6b76c7c4d-fghij   1/1     Running   0          30s   app=v1,pod-template-hash=...
# nginx-6b76c7c4d-klmno   1/1     Running   0          30s   app=v1,pod-template-hash=...
```

#### 3. Update the Image to `nginx:1.23.4`

Updating the image triggers a **rolling update**, where the Deployment replaces old pods with new ones gradually, ensuring zero downtime.

```bash
kubectl set image deployment/nginx nginx=nginx:1.23.4
```

#### 4. Verify the Rollout

You can watch the rollout process in real-time.
```bash
kubectl rollout status deployment/nginx
# deployment "nginx" successfully rolled out
```
Now, check the pod images using `kubectl describe pods`. You will see the new image `nginx:1.23.4` is being used.

#### 5. Assign a Change Cause

Annotating a revision with a cause makes the rollout history more understandable.
```bash
kubectl annotate deployment/nginx kubernetes.io/change-cause="Pick up patch version"
```

#### 6. Scale the Deployment to 5 Replicas

```bash
kubectl scale deployment/nginx --replicas=5
```

#### 7. View Rollout History

The `rollout history` command shows the different revisions of your Deployment.
```bash
kubectl rollout history deployment/nginx
# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         Pick up patch version
```

#### 8. Revert to Revision 1

If an update is faulty, you can easily roll back to a previous, stable version.
```bash
kubectl rollout undo deployment/nginx --to-revision=1
```

#### 9. Ensure Pods Use the Original Image

Verify the rollback by checking the pod images again. They should now be running `nginx:1.23.0`.
```bash
kubectl describe pods | grep "Image:"
# Image:          nginx:1.23.0
# Image:          nginx:1.23.0
# ... (for all 5 pods)
```

### Part 3: Troubleshooting

This section involves debugging and fixing invalid Deployment YAML files.

#### Troubleshooting Issue 1

Here is the first invalid YAML:
```yaml
apiVersion: v1
kind:  Deployment
# ...
```
1.  **Save the file** as `deploy-broken1.yaml` and attempt to apply it.
    ```bash
    kubectl apply -f deploy-broken1.yaml
    ```
2.  **Error Message:**
    ```
    error: resource mapping not found for name: "nginx-deploy" namespace: "" from "deploy-broken1.yaml": no matches for kind "Deployment" in version "v1"
    ```
3.  **Analysis and Fix:**
    The error indicates that `kind: Deployment` is not found in `apiVersion: v1`. Deployments are part of the `apps` API group. The correct `apiVersion` for a Deployment is `apps/v1`.
4.  **Corrected YAML:**
    ```yaml
    apiVersion: apps/v1 # Corrected from v1
    kind: Deployment
    # ... rest of the file
    ```
    After fixing the `apiVersion`, applying the file will work successfully.

#### Troubleshooting Issue 2

Here is the second invalid YAML:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
  labels:
    env: demo
spec:
  template:
    metadata:
      labels:
        env: demo
    # ...
  replicas: 3
  selector:
    matchLabels:
      env: dev # Mismatch with template label
```
1.  **Save the file** as `deploy-broken2.yaml` and attempt to apply it.
    ```bash
    kubectl apply -f deploy-broken2.yaml
    ```
2.  **Error Message:**
    ```
    The Deployment "nginx-deploy" is invalid: spec.selector: Invalid value: v1.LabelSelector{...}: `selector` does not match template `labels`
    ```
3.  **Analysis and Fix:**
    The error clearly states that the `spec.selector.matchLabels` do not match the labels in the pod `template` (`spec.template.metadata.labels`). The selector has `env: dev` while the pod template has `env: demo`. The selector must match the pod template labels for the Deployment to know which pods to manage.
4.  **Corrected YAML:**
    ```yaml
    # ...
    selector:
      matchLabels:
        env: demo # Corrected from 'dev' to match template label
    ```
    After fixing the selector label, the YAML will apply correctly.