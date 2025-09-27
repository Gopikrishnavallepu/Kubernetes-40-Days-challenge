# Day 17/40 - Kubernetes Autoscaling | HPA Vs VPA

## Check out the video below for Day17 👇

[![Day17/40 - Kubernetes Autoscaling | HPA Vs VPA](https://img.youtube.com/vi/afUL5jGoLx0/sddefault.jpg)](https://youtu.be/afUL5jGoLx0)

## Autoscaling types

![image](https://github.com/user-attachments/assets/684d96ca-60b7-4496-a180-dd1ab977a9bb)


## HPA v/S VPA

![image](https://github.com/user-attachments/assets/5b68a4b1-e5de-4086-9f55-6845bd420f1b)



### Sample commands used in the video:

```bash
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10

kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"

kubectl get hpa php-apache --watch

kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
```

### Sample YAML used in the video

1. Deploy.yaml

```YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  selector:
    matchLabels:
      run: php-apache
  template:
    metadata:
      labels:
        run: php-apache
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
  labels:
    run: php-apache
spec:
  ports:
  - port: 80
  selector:
    run: php-apache
```

2. hpa.yaml

```YAML
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```


Of course. Here is a comprehensive guide to help you with the exercise on Kubernetes Autoscaling, which appears to be Day 17 of the #40DaysOfKubernetes challenge. This task focuses on understanding and implementing different autoscaling mechanisms like HPA (Horizontal Pod Autoscaler), VPA (Vertical Pod Autoscaler), and Cluster Autoscaler.

### Prerequisites: Kubernetes Cluster Setup

Before you begin, you need a running Kubernetes cluster. The provided sources recommend setting one up locally using **Kind (Kubernetes in Docker)**, as it provides a flexible learning environment.

*   **Kind Installation & Multi-Node Cluster**: The **Day 6 video** provides detailed, step-by-step instructions on how to install Kind and create a multi-node cluster (e.g., one control plane and multiple worker nodes) using a YAML configuration file. It's recommended to use the latest Kubernetes version supported by the CKA exam, which as of the video's recording was `v1.30`.
*   **Port Binding (for Kind users)**: For some tasks, you may need to expose ports from your Kind cluster to your local machine (localhost). This is done by adding an `extraPortMappings` section to your Kind cluster configuration YAML, as explained in the **Day 9 video**. This step is not strictly necessary for this specific exercise but is a good practice.
*   **Metrics Server**: **This is a critical prerequisite for HPA**. The Horizontal Pod Autoscaler relies on resource metrics (like CPU and memory usage) to make scaling decisions. The **Metrics Server** is a Kubernetes add-on that collects these metrics and makes them available to components like the HPA. The Day 16 video covers the installation of the Metrics Server using a provided YAML file. Ensure it is running in your `kube-system` namespace before you proceed.

### Understanding Kubernetes Autoscaling

Scaling is the process of adjusting your resources to meet user demand. In a production environment with thousands of pods, manually scaling is inefficient and nearly impossible. Autoscaling automates this process based on predefined metrics like CPU utilization or custom events.

There are two primary types of scaling:

1.  **Horizontal Scaling (Scale Out/In)**: This involves increasing or decreasing the number of pod replicas. For example, adding more pods to handle a spike in traffic is scaling out. This is managed by the **Horizontal Pod Autoscaler (HPA)** for workloads and the **Cluster Autoscaler** for infrastructure (nodes).
2.  **Vertical Scaling (Scale Up/Down)**: This involves resizing existing resources, such as increasing the CPU or memory allocated to a pod. This is managed by the **Vertical Pod Autoscaler (VPA)**. A key drawback is that resizing a pod often requires a restart, which may not be suitable for applications that cannot afford downtime.

Only HPA is a built-in feature of Kubernetes. VPA and Cluster Autoscaler are typically separate projects or come with managed cloud provider services (like EKS, AKS, GKE). This exercise will focus on implementing **HPA**.

### Task: Implement Horizontal Pod Autoscaler (HPA)

The video demo walks you through setting up and testing an HPA. Here are the detailed steps:

#### 1. Create a Deployment and Service

First, you need an application to autoscale. The demo uses a sample PHP-Apache application designed for HPA testing.

1.  **Create a YAML manifest** (`deploy.yaml`) for the Deployment and Service. You can define multiple Kubernetes objects in a single YAML file by separating them with three hyphens (`---`).
    *   **Deployment**: The deployment will use the image `k8s.gcr.io/hpa-example`.
    *   **Resource Requests and Limits**: **It is crucial to define CPU requests for your containers**. The HPA uses the pod's CPU request to calculate the utilization percentage. The demo sets a CPU request of `200m` (0.2 CPU cores) and a limit of `500m` (0.5 CPU cores).
    *   **Service**: A ClusterIP service is created to expose the deployment internally.

2.  **Apply the manifest** to create the resources:
    ```bash
    kubectl apply -f deploy.yaml
    ```
    This will create a deployment with a single replica and a corresponding service.

#### 2. Create the HPA Object

Next, you create the HPA object to manage the scaling of your deployment.

1.  **Use the `kubectl autoscale` command**: This imperative command is a quick way to create an HPA.
    ```bash
    kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
    ```
    *   `deployment php-apache`: Specifies the target deployment to scale.
    *   `--cpu-percent=50`: This is the target metric. The HPA will add replicas to keep the average CPU utilization across all pods at or below 50% of their requested CPU.
    *   `--min=1`: The minimum number of replicas the deployment must have.
    *   `--max=10`: The maximum number of replicas the HPA can scale up to.

2.  **Verify the HPA creation**:
    ```bash
    kubectl get hpa
    ```
    Initially, the CPU utilization might show as `<unknown>` because it takes a few moments for the metrics server to collect and report the data. After a short while, it will display the current usage (e.g., 1%) against the target (50%). The HPA controller checks metrics by default every 15 seconds.

#### 3. Generate Load and Observe Autoscaling

To trigger the autoscaling, you need to generate a load on the application to increase its CPU usage.

1.  **Run a load generator pod**: The demo uses a temporary BusyBox pod to continuously send requests to the `php-apache` service, which increases the CPU load.
    ```bash
    kubectl run -it --rm load-generator --image=busybox /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
    ```
    *   This command runs a pod in the foreground that sends a web request every 10 milliseconds (`0.01s`). The `--rm` flag ensures the pod is deleted once you stop it (with Ctrl+C).

2.  **Monitor the HPA and Pods**: In a separate terminal, watch the HPA status.
    ```bash
    kubectl get hpa -w
    ```
    *   The `-w` or `--watch` flag will stream the changes live.
    *   You will see the CPU utilization climb past the 50% target. Once it does, the HPA will start creating new pods to distribute the load. The number of replicas will increase from 1 up to the maximum of 10 as needed. You can verify this with `kubectl get pods`.

#### 4. Stop the Load and Observe Scaling Down

Finally, observe the HPA scaling the deployment back down once the load subsides.

1.  **Stop the load generator**: Go back to the terminal where the load generator is running and press `Ctrl+C`. This will terminate the pod.

2.  **Monitor the HPA**: Watch the `kubectl get hpa -w` output. The CPU utilization will drop back down to a low percentage. After a few minutes, the HPA will scale the number of replicas back down to the minimum of 1 to conserve resources.

This exercise provides a practical demonstration of how HPA dynamically manages application scalability in response to real-time demand.