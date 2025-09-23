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

***

### References

*   "Day 1/40 - Docker Tutorial For Beginners - Docker Fundamentals - CKA Full Course 2025" - Tech Tutorials with Piyush
*   "Day 5/40 - What is Kubernetes - Kubernetes Architecture Explained" - Tech Tutorials with Piyush
*   "Day 7/40 - Pod In Kubernetes Explained | Imperative VS Declarative Way | YAML Tutorial" - Tech Tutorials with Piyush
*   "Day 8/40 - Kubernetes Deployment, Replication Controller and ReplicaSet Explained" - Tech Tutorials with Piyush
*   "FREE Kubernetes Full Course (Day 0/40) | Certified Kubernetes Administrator (CKA) Tutorial + Roadmap" - Tech Tutorials with Piyush