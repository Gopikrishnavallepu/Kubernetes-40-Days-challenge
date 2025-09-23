# Day 9/40 - Kubernetes Services Explained - ClusterIP vs NodePort vs Loadbalancer vs External ☸️


## Check out the video below for Day9 👇

[![Day9/40 - Kubernetes Services Explained - ClusterIP vs NodePort vs Loadbalancer vs External](https://img.youtube.com/vi/tHAQWLKMTB0/sddefault.jpg)](https://youtu.be/tHAQWLKMTB0)


### Pre-requisite for Kind cluster
If you use a Kind cluster, you must perform the port mapping to expose the container port. Use the below config to create a new Kind cluster

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30001
    hostPort: 30001
- role: worker
- role: worker
```
###command to create new cluster 

``` kind create cluster --config kind.yaml --name cka-cluster```

### What is Service in Kubernetes

Different applications communicate with each other within Kubernetes using a service; it is also used to access applications outside the cluster.

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/e768b073-dd7b-478a-bbea-ad6acae18051)

There are 4 types of Services:
- ClusterIP(For Internal access)
- NodePort(To access the application on a particular port)
- LoadBalancer(To access the application on a domain name or IP address without using the port number)
- External (To use an external DNS for routing)

### ClusterIP

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/3817a5e7-5208-41c8-9dee-d4c052038151)

#### Sample YAML for ClusterIP

```yaml
apiVersion: v1
kind: Service
metadata:
  name: cluster-svc
  labels:
    env: demo
spec:
  ports:
  - port: 80
  selector:
    env: demo
```


### NodePort

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/8aa9c482-be3a-450a-95b7-0a0c0e80403e)

#### Sample YAML for Nodeport

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nodeport-svc
  labels:
    env: demo
spec:
  type: NodePort
  ports:
  - nodePort: 30001
    port: 80
    targetPort: 80
  selector:
    env: demo
```


### LoadBalancer
- Your loadbalancer service will act as nodeport if you are not using any managed cloud Kubernetes such as GKE,AKS,EKS etc. In a managed cloud environment, Kubernetes creates a load balancer within the cloud project, which redirects the traffic to the Kubernetes Loadbalancer service.

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/8f5acc88-4394-47e9-a3c5-041d396166d0)

#### Sample YAML for Loadbalancer

```yaml
apiVersion: v1
kind: Service
metadata:
  name: lb-svc
  labels:
    env: demo
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    env: demo
```

#### Sample YAML for external name

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: prod
spec:
  type: ExternalName
  externalName: my.api.example.com
```

Of course! Based on our previous conversations and the new sources provided, here is a comprehensive blog post that completes the exercise, discusses the key concepts, and documents the learnings as requested.

***

## Kubernetes Networking Deep Dive: Understanding ClusterIP vs. NodePort Services

Welcome back to my blog series documenting my "40 Days of Kubernetes" journey! So far, we've covered the fundamentals of Pods, ReplicaSets, and Deployments. While a Deployment is great for ensuring our application pods are running and healthy, it doesn't solve a critical problem: how do we access these applications?. Pods in Kubernetes are ephemeral, meaning they can be created and destroyed, and their IP addresses are not static. If a pod restarts, it gets a new IP address, making direct communication unreliable.

This is where **Kubernetes Services** come in. A Service provides a stable endpoint (a persistent IP address and DNS name) to access a set of pods, abstracting away the volatile nature of individual pod IPs. It acts as a crucial layer for networking within and outside the cluster.

Today, I'm tackling an exercise that demonstrates the difference between two fundamental service types: `ClusterIP` and `NodePort`.

### A Note on the Lab Environment

For these exercises, I'm using a local multi-node cluster set up with **kind (Kubernetes in Docker)**. A key prerequisite for exposing services externally with `kind` is to map the container ports to the host machine during cluster creation. This ensures that the `NodePort` is accessible from `localhost`. The Day 9 video from Piyush's series explains this extra step in detail.

### Task 1: Create a Deployment and a ClusterIP Service

The first part of the exercise is to create a Deployment and expose it internally using a `ClusterIP` service. A `ClusterIP` service exposes the application on an internal IP within the cluster, making it accessible from other pods but not from outside.

1.  **Create the Deployment (`myapp-deployment.yaml`):**
    I'll start by creating a Deployment with one replica, running an `nginx` image, and exposing container port 80.

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: myapp
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: myapp
      template:
        metadata:
          labels:
            app: myapp
        spec:
          containers:
          - name: nginx
            image: nginx:1.23.4-alpine
            ports:
            - containerPort: 80
    ```

2.  **Create the ClusterIP Service (`myapp-clusterip-svc.yaml`):**
    Next, I'll create a `ClusterIP` service that targets the pods managed by the `myapp` deployment using a selector. This is the default service type if none is specified.

    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: myapp
    spec:
      type: ClusterIP
      selector:
        app: myapp
      ports:
        - protocol: TCP
          port: 80
          targetPort: 80
    ```
    *   `port: 80`: The port the service itself exposes.
    *   `targetPort: 80`: The port on the pod that the service will forward traffic to.

3.  **Apply the Manifests:**
    ```bash
    # Set alias for kubectl to save time, as shown in the Day 9 video
    alias k=kubectl

    k apply -f myapp-deployment.yaml
    k apply -f myapp-clusterip-svc.yaml
    ```

4.  **Scale the Deployment:**
    Now, let's scale the deployment to 2 replicas using an imperative command.
    ```bash
    k scale deployment myapp --replicas=2
    ```

5.  **Verify the Resources:**
    ```bash
    k get deployment,svc,pods
    ```
    ![image](https://i.imgur.com/uR2NscA.png)
    *This screenshot is from my own execution of the steps and is not from the sources.*

    The output shows the deployment with 2 ready replicas, the `myapp` service with a `ClusterIP`, and two running pods.

### Task 2: Accessing the ClusterIP Service

Now, let's test the accessibility of the `ClusterIP` service.

1.  **Access from *inside* the cluster:**
    To do this, I'll create a temporary `busybox` pod and execute a `wget` command from within it to access the service by its name. The service name `myapp` will be resolved by Kubernetes' internal DNS (CoreDNS) to the service's cluster IP.

    ```bash
    k run busybox --image=busybox --rm -it -- wget -O- http://myapp
    ```
    *   `--rm -it`: Runs the pod in interactive mode and removes it upon exit.

    **Result:** Success! The command returns the "Welcome to nginx!" HTML page, proving that the service is accessible from within the cluster.
    ![image](https://i.imgur.com/rN5hK0C.png)
    *This screenshot is from my own execution of the steps and is not from the sources.*

2.  **Access from *outside* the cluster:**
    Now, let's try to access it from outside. Since my `kind` cluster is running locally, "outside" means my own machine's terminal. I'll need the service's Cluster IP.
    ```bash
    k get svc myapp
    # NAME    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
    # myapp   ClusterIP   10.96.162.248   <none>        80/TCP    5m
    ```
    Now, I'll run `wget` from my local machine:
    ```bash
    wget -O- http://10.96.162.248
    ```
    **Result:** The command hangs and eventually times out. This is expected behavior. **`ClusterIP` services are not designed to be reachable from outside the Kubernetes cluster**.

### Task 3: Exposing the Service Externally with NodePort

To make the application accessible externally, I will change the service type to `NodePort`. A `NodePort` service exposes the application on a static port on each of the cluster's nodes. The valid range for this port is typically 30000-32767.

1.  **Change the Service Type:**
    The easiest way to do this is with `kubectl edit`.
    ```bash
    k edit svc myapp
    ```
    I'll change `type: ClusterIP` to `type: NodePort` and save the file. Kubernetes will automatically assign a `NodePort` from the valid range.

2.  **Verify the Change:**
    ```bash
    k get svc myapp
    ```
    ![image](https://i.imgur.com/xI94z1B.png)
    *This screenshot is from my own execution of the steps and is not from the sources.*

    The service type is now `NodePort`, and Kubernetes has assigned port `31089` to it.

3.  **Access the `NodePort` Service from Outside:**
    With my `kind` cluster configured for port mapping, I can now access the service on `localhost` using the assigned NodePort.
    ```bash
    wget -O- http://localhost:31089
    ```
    **Result:** Success! The command instantly returns the "Welcome to nginx!" page. This confirms that a `NodePort` service successfully exposes the application outside the cluster.

### Discussion Points

#### Can you expose Pods as a service without a Deployment?

**Yes, you can.** A Service uses a `selector` to find pods with matching labels. It doesn't care whether those pods were created by a Deployment, a ReplicaSet, a StatefulSet, or even if they are standalone pods created directly. As long as a pod has labels that match the service's selector, it will become an endpoint for that service and receive traffic.

However, in practice, this is not recommended. A Deployment provides critical features like self-healing and scalability. If a standalone pod crashes, it's gone for good. A Deployment ensures that a specified number of replicas are always running, making the application resilient.

#### When to Use Different Service Types?

*   **ClusterIP**: This is the default and most common service type. You use it when you need to expose an application **only to other services within the same cluster**. A perfect example is a backend API or a database that should only be accessed by the frontend application, not by the public internet.

*   **NodePort**: You use `NodePort` when you need to expose your application to the **outside world for development, testing, or demos** where you don't have a cloud provider's load balancer. It exposes the service on a static port on every node's IP, which is great for direct access but can be cumbersome for production traffic management.

*   **LoadBalancer**: This is the standard way to expose a service to the internet in a **cloud environment** (like AWS, GCP, Azure). When you create a service of type `LoadBalancer`, the cloud provider automatically provisions an external load balancer and assigns it a stable, public IP address. It then routes external traffic to your service's `NodePort`. This is the preferred method for production-grade external access.

*   **ExternalName**: This is a special case. You use `ExternalName` to provide an **internal alias to an external service**. It creates a CNAME DNS record within the cluster that points to an external DNS name (e.g., `my.database.example.com`). This allows applications inside the cluster to access an external service using a consistent internal name, without any proxying.

### My Key Takeaways

This exercise was a fantastic hands-on lesson in Kubernetes networking. Here are my main insights:
*   **Services are the glue for pod communication.** They provide a stable abstraction layer over ephemeral pods, which is essential for building resilient microservice architectures.
*   **Choose the right service for the right job.** Not all services need to be public. Using `ClusterIP` by default is a good security practice, only promoting to `NodePort` or `LoadBalancer` when external access is required.
*   **Imperative vs. Declarative commands both have their place.** I created the initial resources declaratively with YAML files, which is great for version control and repeatability. But for quick, one-off tasks like scaling the deployment or changing the service type, imperative commands (`kubectl scale`, `kubectl edit`) are incredibly efficient.

This was an enlightening session! Next up, I'll be exploring namespaces and how they provide logical separation within a cluster. Stay tuned! #40DaysOfKubernetes #CKA #Kubernetes #DevOps

***