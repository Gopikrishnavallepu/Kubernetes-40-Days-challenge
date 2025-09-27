# Day 18/40 - Health Probes in Kubernetes

## Check out the video below for Day18 👇

[![Day 18/40 - Health Probes in kubernetes](https://img.youtube.com/vi/x2e6pIBLKzw/sddefault.jpg)](https://youtu.be/x2e6pIBLKzw)


### What are probes?
- To investigate or monitor something and to take necessary actions

### What are health probes in Kubernetes?
- Health probes monitor your Kubernetes applications and take necessary actions to recover from failure
- To ensure your application is highly available and self-healing

### Type of health probes in Kubernetes
- Readiness ( Ensure application is ready)
- Liveness ( Restart the application if health checks fail)
- Startup ( Probes for legacy applications that need a lot of time to start)

### Types of health checks they perform?
- HTTP/TCP/command

### Health probes

![image](https://github.com/user-attachments/assets/95f34a79-4956-4555-b33d-aeddf86653c5)

### Sample YAML

#### liveness-http and readiness-http
``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello
spec:
  containers:
  - name: liveness
    image: registry.k8s.io/e2e-test-images/agnhost:2.40
    args:
    - liveness
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 3
      periodSeconds: 3
    readinessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 10
```

#### liveness command

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: registry.k8s.io/busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat 
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

#### liveness-tcp

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tcp-pod
  labels:
    app: tcp-pod
spec:
  containers:
  - name: goproxy
    image: registry.k8s.io/goproxy:0.1
    ports:
    - containerPort: 8080
    livenessProbe:
      tcpSocket:
        port: 3000
      initialDelaySeconds: 10
      periodSeconds: 5
```


Of course. Here is a comprehensive guide to help you complete the exercise on **Health Probes in Kubernetes**, which appears to be Day 18 of the #40DaysOfKubernetes challenge. This task will help you understand and implement `livenessProbe` and `readinessProbe` to ensure your applications are robust and self-healing.

### Prerequisites: Kubernetes Cluster Setup

To perform this exercise, you need a multi-node Kubernetes cluster. The provided sources recommend setting one up locally using **Kind (Kubernetes in Docker)**, as it provides a realistic environment for these tasks.

*   **Cluster Creation**: The **Day 6 video** offers a detailed, step-by-step guide on how to install Kind and create a multi-node cluster (e.g., one control plane, two worker nodes) using a YAML configuration file.
*   **Port Binding (for Kind users)**: When using Kind, you might need to map ports from the container nodes to your local machine (localhost) to access services externally. This is a crucial step for testing services like NodePort. The **Day 9 video** explains how to add an `extraPortMappings` section to your Kind configuration YAML to enable this port binding.

### Understanding Health Probes in Kubernetes

In Kubernetes, **probes** are diagnostic checks performed periodically by the `kubelet` on a container to determine its health. They are essential for building self-healing applications. If a container fails a health check, Kubernetes can take automated action to recover it, ensuring that users are not impacted.

There are three main types of probes:

1.  **Liveness Probe**: This probe checks if your application is running. If the liveness probe fails, it indicates the application is in an unrecoverable state (e.g., deadlocked), and the `kubelet` will kill the container and restart it.
2.  **Readiness Probe**: This probe checks if your application is ready to start accepting traffic. If the readiness probe fails, the pod's IP address is removed from the endpoints of all Services it belongs to. This is useful for applications that need time to initialize before they can serve requests.
3.  **Startup Probe**: This is used for applications that have a slow startup time. It disables liveness and readiness checks until the application has successfully started, preventing the `kubelet` from killing the app before it's ready.

Each of these probes can perform one of three types of health checks:

*   **Exec (Command)**: Executes a command inside the container. If the command exits with status code 0, it's considered a success.
*   **HTTP GET**: Performs an HTTP GET request against a specific path and port. A response code between 200 and 399 indicates success.
*   **TCP Socket**: Attempts to open a TCP socket on a specified port. If the connection is successful, the probe succeeds.

Now, let's walk through the task details.

### 1. Create a Pod with an `exec` Liveness Probe

This part of the task demonstrates a liveness probe that fails after a set time, causing the container to restart.

1.  **Create the YAML Manifest** (`liveness-exec.yaml`):
    *   `kind`: `Pod`
    *   `image`: `registry.k8s.io/busybox`
    *   `args`: This command will:
        *   Create an empty file at `/tmp/healthy`.
        *   Wait for 30 seconds.
        *   Delete the `/tmp/healthy` file.
        *   Wait for another 600 seconds (10 minutes).
    *   `livenessProbe`:
        *   Uses an `exec` check to run `cat /tmp/healthy`. This command will succeed (exit code 0) only if the file exists.
        *   `initialDelaySeconds: 5`: The probe will wait 5 seconds before the first check.
        *   `periodSeconds: 5`: The probe will run every 5 seconds after the initial delay.

    ```yaml
    # liveness-exec.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: liveness-exec-pod
    spec:
      containers:
      - name: liveness-ctr
        image: registry.k8s.io/busybox
        args:
        - /bin/sh
        - -c
        - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
        livenessProbe:
          exec:
            command:
            - cat
            - /tmp/healthy
          initialDelaySeconds: 5
          periodSeconds: 5
    ```

2.  **Apply the Manifest and Observe**:
    ```bash
    kubectl apply -f liveness-exec.yaml
    kubectl get pods -w 
    ```
    *   Initially, the pod will be `Running`. The liveness probe will succeed for the first 30 seconds because `/tmp/healthy` exists.
    *   **After about 35-40 seconds**, you will see the pod's `RESTARTS` count increase to 1. This happens because the file gets deleted after 30 seconds, causing the `cat` command to fail. The liveness probe fails, and the `kubelet` restarts the container.
    *   You can investigate the reason for the restart with `kubectl describe pod liveness-exec-pod`. In the `Events` section, you will see a message like "Liveness probe failed: cat /tmp/healthy: No such file or directory," followed by an event indicating the container was killed and will be restarted.

### 2. Create a Pod with HTTP Liveness and Readiness Probes

This task demonstrates using HTTP-based probes for an application that exposes a health check endpoint.

1.  **Create the YAML Manifest** (`probes-http.yaml`):
    *   `image`: `registry.k8s.io/e2e-test-images/agnhost:2.40` (a utility image for testing).
    *   `livenessProbe`:
        *   Uses `httpGet` to check the `/healthz` path on port 8080.
        *   `initialDelaySeconds: 5`: Wait 5 seconds before the first check.
        *   `periodSeconds: 10`: Run the check every 10 seconds.
    *   `readinessProbe`:
        *   The configuration is identical to the liveness probe. Readiness probes and Liveness probes have the same syntax and properties; only their purpose differs.

    ```yaml
    # probes-http.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: probes-http-pod
    spec:
      containers:
      - name: agnhost-ctr
        image: registry.k8s.io/e2e-test-images/agnhost:2.40
        args:
        - netexec
        - --http-port=8080
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
    ```

2.  **Apply the Manifest and Verify**:
    ```bash
    kubectl apply -f probes-http.yaml
    kubectl get pods
    ```
    *   The pod will transition to a `Running` state and `READY 1/1`. The `agnhost` image is designed to respond successfully to requests on the `/healthz` endpoint, so both probes will pass, and the container will run stably without restarting.
    *   You can use `kubectl describe pod probes-http-pod` to view the probe configurations and confirm in the events that the pod started successfully.

### Share Your Learnings

As part of the **#40DaysOfKubernetes challenge**, documenting and sharing what you've learned is a crucial step for reinforcing your knowledge and showcasing your skills.

*   **Write a blog post**: Explain the concepts of Liveness and Readiness probes. Describe the difference between them and the types of checks (`exec`, `httpGet`, `tcpSocket`) you can perform. Document the steps you took in this exercise and the outcomes you observed.
*   **Embed the video**: Include the Day 18 video in your blog post to make the content more visually appealing and provide additional context.
*   **Share on Social Media**: Post a link to your blog on platforms like LinkedIn or Twitter. Use the hashtag **`#40DaysOfKubernetes`** and tag the creator so your submission is recognized.

If you encounter any issues, the dedicated Discord community server is a great place to ask for help. Good luck with the task!