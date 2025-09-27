# Day 11/40 - Multi Container Pod Kubernetes - Sidecar vs Init Container

## Check out the video below for Day11 👇

[![Day11/40 - Multi Container Pod Kubernetes - Sidecar vs Init Container](https://img.youtube.com/vi/yRiFq1ykBxc/sddefault.jpg)](https://youtu.be/yRiFq1ykBxc)


## Sample YAML used in the demo

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app.kubernetes.io/name: MyApp
spec:
  containers:
  - name: myapp-container
    image: busybox:1.28
    env:
    - name: FIRSTNAME
      value: "Piyush"
    command: ['sh', '-c', 'echo The app is running! && sleep 3600']
  initContainers:
  - name: init-myservice
    image: busybox:1.28
    command: ['sh', '-c'] #command to run
    args: ['until nslookup myservice.default.svc.cluster.local; do echo waiting for myservice; sleep 2; done']
  - name: init-mydb
    image: busybox:1.28
    command: ['sh', '-c']
    args: ['until nslookup mydb.default.svc.cluster.local; do echo waiting for mydb; sleep 2; done']
```


```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app.kubernetes.io/name: MyApp
spec:
  containers:
  - name: myapp-container
    image: busybox:1.28
    env:
    command: ['sh', '-c', 'echo The app is running! && sleep 3600']
  initContainers:
  - name: init-myservice
    image: busybox:1.28
    command: ['sh', '-c'] # command to run
    args: # arguments to the command
      - > # multi-line string
        until nslookup myservice.default.svc.cluster.local; do
         echo waiting for myservice;
         sleep 2;
        done;
```

Of course, let's go through the exercise on environment variables and multi-container pods in Kubernetes, using the information from the sources you provided.

Based on the sources, a **multi-container pod** is a pod that runs additional containers alongside the main application container to provide support. These can be **`init` containers**, which run and complete specific tasks before the main app container starts, or **sidecar containers** (helper containers), which run concurrently with the app container. A key feature is that all containers within a single pod share resources like memory, CPU, and storage.

### Task: Create a Multi-container Pod

Here's a step-by-step guide to creating a multi-container pod with an `init` container and environment variables, as demonstrated in the sources.

#### Step 1: Create the Pod Manifest (`pod.yaml`)

First, you'll create a YAML manifest file for the pod. This file will define all the pod's specifications, including its containers, environment variables, and any commands it needs to run.

Here is a sample YAML configuration based on the video demonstration. You can create a file named `pod.yaml` and add this content:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  labels:
    app: my-app-pod
spec:
  # Environment variable injected via a ConfigMap
  env:
    - name: FIRST_NAME # This will be the variable name inside the container
      valueFrom:
        configMapKeyRef:
          name: app-cm      # Name of the ConfigMap
          key: first_name   # Key in the ConfigMap's data section
  
  # Main application container
  containers:
    - name: my-app-container
      image: busybox
      command: ["sh", "-c", "echo The app is running with user $FIRST_NAME && sleep 3600"]
      
  # Init container that runs before the main container
  initContainers:
    - name: init-my-service
      image: busybox:1.28
      command: ["sh", "-c", "until nslookup my-service.default.svc.cluster.local; do echo waiting for my-service; sleep 2; done;"]
```

#### Step 2: Create a ConfigMap for Environment Variables

Instead of hardcoding environment variables directly into the pod's YAML file, a best practice is to use a **`ConfigMap`**. A `ConfigMap` is a Kubernetes object that stores configuration data as key-value pairs, which can then be injected into pods. This makes your configurations reusable and easier to manage.

You can create a `ConfigMap` using an imperative command:
```bash
kubectl create configmap app-cm --from-literal=first_name=Piyush
```
This command creates a `ConfigMap` named `app-cm` with a data entry where the key is `first_name` and the value is `Piyush`.

#### Step 3: Create a Service for the `init` Container to Check

The `init` container in our `pod.yaml` is designed to wait for a service named `my-service` to become available before allowing the main application container to start. This is a common pattern to ensure that dependencies are ready before your application starts.

1.  **Create a simple deployment** for the service to point to:
    ```bash
    kubectl create deployment nginx-deploy --image=nginx
    ```
2.  **Expose the deployment as a service**. The service must be named `my-service` to match what the `init` container is looking for.
    ```bash
    kubectl expose deployment nginx-deploy --name=my-service --port=80
    ```
    This command creates a service that makes the `nginx-deploy` pods accessible within the cluster under the name `my-service`.

#### Step 4: Create the Multi-container Pod

Now that the `ConfigMap` and the dependent `my-service` are in place, you can create the pod using your manifest file:
```bash
kubectl apply -f pod.yaml
```

#### Step 5: Verify the Pod's Status and Functionality

1.  **Check the pod status**:
    ```bash
    kubectl get pods
    ```
    Initially, the pod will be in an `Init` state, indicating that the `init` container is running. Once the `my-service` is available, the `init` container will complete, and the main `my-app-container` will start, moving the pod's status to `Running`.

2.  **Inspect the `init` container's logs** to see its progress:
    ```bash
    kubectl logs my-app -c init-my-service
    ```
    You will see messages like "waiting for my-service" until the service is resolved, after which the log will show a successful `nslookup`.

3.  **Verify the environment variable** inside the main container:
    *   Exec into the running pod's main container:
        ```bash
        kubectl exec -it my-app -- sh
        ```
    *   Inside the container's shell, print the environment variable to confirm it was injected correctly from the `ConfigMap`:
        ```bash
        echo $FIRST_NAME
        ```
        This should output `Piyush`, which is the value we stored in the `app-cm` `ConfigMap`.

This exercise demonstrates how `init` containers can manage startup dependencies and how `ConfigMaps` can effectively decouple configuration from your pod definitions, which are both crucial concepts in managing applications on Kubernetes.

Of course. Let's take a detailed look at multi-container pods in Kubernetes, specifically comparing **Init Containers** and **Sidecar Containers**, and then walk through a practical exercise.

A multi-container pod is a pod that contains more than one container. These containers share the same network namespace, storage volumes, and resources like CPU and memory allocated to the pod. This design pattern allows you to run a main application container alongside one or more helper containers that provide supporting functionalities. There are two primary types of these helper containers: `init` containers and `sidecar` containers.

### Init Containers vs. Sidecar (Helper) Containers

| Feature | Init Containers | Sidecar Containers (Helper Containers) |
| :--- | :--- | :--- |
| **Execution Order** | Run sequentially, one after another, and **must complete successfully** before the main application container starts. If any `init` container fails, Kubernetes will repeatedly restart it until it succeeds, and the main app container will not start. | Run **concurrently** with the main application container. They start at roughly the same time as the main container and run for the entire lifecycle of the pod. |
| **Purpose** | Used for setup tasks, pre-flight checks, or to ensure dependencies are met before the main application starts. A common use case is to wait for a dependent service (like a database) to be available before the application container starts. | Used to extend or enhance the functionality of the main application without being part of the application itself. They act as "helpers". Examples include log shippers, monitoring agents, or network proxies. |
| **Lifecycle** | Their lifecycle is separate from the main container. They run a specific task and then exit. The pod's overall status will be `Init` while they are running. | Their lifecycle is tied directly to the main container. They run as long as the main container is running. If the main container restarts or stops, the sidecar container does too. |
| **Resource Sharing** | They share network and storage with the main app container but run in a distinct sequence. All resources allocated to the pod are shared among all containers, including `init` containers. | They share all resources with the main container, including the network and storage volumes, allowing for tight integration (e.g., communicating via `localhost`). |
| **Failure Impact** | A failing `init` container **prevents the main application container from starting**, keeping the pod stuck in an initialization state. | A failing sidecar container can cause the entire pod to restart, depending on the pod's restart policy, but it doesn't block the main container from starting initially. |
| **Use Case Example** | An `init` container can run a command like `nslookup` in a loop to wait for a service's DNS to resolve, ensuring a database is ready before the main app tries to connect. | A sidecar container could be a Fluentd agent that tails log files from a shared volume and forwards them to a central logging system. |

### Practical Exercise: Creating a Multi-Container Pod

Let's build a practical example that uses multiple `init` containers to check for service dependencies before launching a main application container. This exercise is based on the demonstrations in the sources.

#### Step 1: Create the Pod Manifest (`pod-multi-init.yaml`)

We will create a pod named `my-app` that has two `init` containers. Each `init` container will wait for a specific service (`my-service` and `my-db`) to become available. The main application container will only start after both `init` containers have completed successfully.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: my-app-container
    image: busybox
    # This command simply keeps the main container running
    command: ["sh", "-c", "echo The main app is running! && sleep 3600"]

  initContainers:
  # First init container waits for 'my-service'
  - name: init-my-service
    image: busybox:1.28
    command: ["sh", "-c", "until nslookup my-service; do echo waiting for my-service; sleep 2; done;"]
  
  # Second init container waits for 'my-db'
  - name: init-my-db
    image: busybox:1.28
    command: ["sh", "-c", "until nslookup my-db; do echo waiting for my-db; sleep 2; done;"]
```
**Note:** You cannot add or remove `init` containers from a pod that is already running. You must delete and recreate the pod.

#### Step 2: Apply the Manifest

First, let's apply the manifest before creating the services it depends on. This will allow us to observe the `init` container states.

```bash
kubectl apply -f pod-multi-init.yaml
```

#### Step 3: Observe the Pod Status

Check the pod's status. You will see it is stuck in the `Init` state.

```bash
kubectl get pods
# NAME     READY   STATUS    RESTARTS   AGE
# my-app   0/1     Init:0/2   0          15s
```
The status `Init:0/2` indicates that there are two `init` containers defined, and zero have completed successfully so far.

You can also check the logs of the first `init` container to see what it's doing:
```bash
# The -c flag specifies the container name
kubectl logs my-app -c init-my-service

# Output will show repeated failures:
# waiting for my-service
# nslookup: can't resolve 'my-service'
```
The pod is waiting for the `my-service` dependency to be met.

#### Step 4: Create the First Dependent Service

Now, let's create the first service that `init-my-service` is waiting for. We'll create a simple Nginx deployment and expose it with the service name `my-service`.

```bash
# Create a deployment
kubectl create deployment nginx-deploy --image=nginx

# Expose it as a service named 'my-service'
kubectl expose deployment nginx-deploy --name=my-service --port=80
```

#### Step 5: Observe the Status Change

After a few moments, check the pod status again.

```bash
kubectl get pods -w
# NAME     READY   STATUS    RESTARTS   AGE
# my-app   0/1     Init:0/2   0          1m
# my-app   0/1     Init:1/2   0          1m15s 
```
The status has changed to `Init:1/2`. This shows that the first `init` container (`init-my-service`) has completed successfully, and now the pod is running the second `init` container (`init-my-db`), which is still waiting.

#### Step 6: Create the Second Dependent Service

Let's create the `my-db` service that the second `init` container is waiting for.

```bash
# Create another deployment (using a redis image for variety)
kubectl create deployment my-db --image=redis

# Expose it as a service named 'my-db'
kubectl expose deployment my-db --name=my-db --port=6379
```

#### Step 7: Final Pod Status

Once the `my-db` service is up, the second `init` container will complete. Since all `init` containers have now finished, the main application container will start, and the pod's status will change to `Running`.

```bash
kubectl get pods
# NAME     READY   STATUS    RESTARTS   AGE
# my-app   1/1     Running   0          3m
```

This exercise clearly demonstrates the sequential, blocking nature of `init` containers, making them ideal for handling startup dependencies and ensuring your application starts in a predictable and stable state. 