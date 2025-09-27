# Day 19/40 - kubernetes configmap and secret

## Check out the video below for Day19 👇

[![Day 19/40 - kubernetes configmap and secret](https://img.youtube.com/vi/Q9fHJLSyd7Q/sddefault.jpg)](https://youtu.be/Q9fHJLSyd7Q)

### What is a config map in Kubernetes?

- When your manifest grows it becomes difficult to manage multiple env vars
- You can take this out of the manifest and store as a config map object in the key-value pair
- Then you can inject that config map into the pod
- You can reuse the same config map into multiple pods

#### Sample command to create a config map

```
- kubectl create cm <configmapname> --from-literal=color=blue \
--from-literal=color=red
```
Where color=clue is the key and value of the config map


#### Secrets

Follow the doc: https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#define-container-environment-variables-using-secret-data

### Sample YAMLs used in the demo

```yaml
apiVersion: v1
data:
  firstname: piyush
  lastname: sachdeva
kind: ConfigMap
metadata:
  name: app-cm
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
    - name: FIRSTNAME
      valueFrom:
        configMapKeyRef:
          name: app-cm
          key: firstname
    command: ['sh', '-c', 'echo The app is running! && sleep 3600']
```

Of course. Here is a comprehensive guide to help you complete the exercise on **ConfigMaps, Secrets, and Environment Variables**, which appears to be Day 19 of the #40DaysOfKubernetes challenge. This guide will walk you through the task provided in the official Kubernetes documentation, drawing upon the concepts and prerequisites mentioned in the sources.

### Prerequisites: Kubernetes Cluster Setup

To perform this exercise, you'll need a running multi-node Kubernetes cluster. The sources recommend setting one up locally using **Kind (Kubernetes in Docker)**, as this provides a realistic environment for learning.

*   **Cluster Creation**: The **Day 6 video** provides a detailed, step-by-step guide on how to install Kind and create a multi-node cluster (e.g., one control plane, two worker nodes) using a YAML configuration file.
*   **Port Binding (for Kind users)**: For some tasks, you may need to expose ports from your Kind cluster to your local machine. This is done by adding an `extraPortMappings` section to your Kind cluster configuration YAML, as explained in the **Day 9 video**. While not strictly required for this specific task, it is a good practice to be familiar with.

### Understanding ConfigMaps, Secrets, and Environment Variables

In Kubernetes, it's a best practice to decouple configuration data from your application code. Hardcoding configuration values, credentials, or other variables directly into a container image is inflexible and insecure. Kubernetes provides two main objects to manage this external configuration:

*   **ConfigMaps**: Used to store non-confidential data in key-value pairs. This is ideal for application settings, feature flags, or any configuration that does not need to be encrypted.
*   **Secrets**: Similar to ConfigMaps but designed to store sensitive information like passwords, API keys, or TLS certificates. Secret data is stored in a base64-encoded format, which is not encryption but obfuscation. Kubernetes provides mechanisms to manage and mount secrets more securely than ConfigMaps.

One of the most common ways to consume this data is by injecting it into a container as **environment variables**.

### Task: Define Container Environment Variables Using Secret Data

The task you've been given is from the official Kubernetes documentation. Let's walk through the steps to complete it.

#### 1. Create a Secret

First, you need to create a Kubernetes Secret to hold the credentials. Secrets can be created imperatively (using `kubectl create`) or declaratively (using a YAML manifest). The documentation uses the imperative approach, which is often faster for simple tasks.

1.  **Create the Secret imperatively**:
    The documentation provides the `kubectl create secret` command. This command will create a Secret named `mysecret` with two data keys: `username` and `password`, both of which are base64-encoded automatically.

    ```bash
    kubectl create secret generic mysecret --from-literal=username='myuser' --from-literal=password='mypassword123'
    ```
    *   `generic`: Specifies the type of secret. `generic` is used for arbitrary key-value pairs.
    *   `--from-literal`: Allows you to provide the secret data directly on the command line.

2.  **Verify the Secret**:
    You can inspect the secret you just created.

    ```bash
    # Get the secret in YAML format to see its structure
    kubectl get secret mysecret -o yaml
    ```
    You will notice that the `data` field contains the base64-encoded values for `username` and `password`. This is a security measure to prevent credentials from being accidentally exposed in logs or plain text manifests.

#### 2. Define Container Environment Variables from the Secret

Now, you will create a Pod and inject the data from the Secret into the container as environment variables.

1.  **Create the Pod Manifest** (`secret-pod.yaml`):
    The documentation provides a YAML file for the pod. This manifest defines two environment variables, `SECRET_USERNAME` and `SECRET_PASSWORD`, for the container. Instead of hardcoding the values, it references the Secret you created earlier.

    ```yaml
    # secret-pod.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: secret-env-pod
    spec:
      containers:
      - name: mycontainer
        image: redis
        env:
          - name: SECRET_USERNAME
            valueFrom:
              secretKeyRef:
                name: mysecret  # The name of the Secret
                key: username   # The key within the Secret
          - name: SECRET_PASSWORD
            valueFrom:
              secretKeyRef:
                name: mysecret  # The name of the Secret
                key: password   # The key within the Secret
      restartPolicy: Never
    ```
    *   **`env`**: This field is a list of environment variables for the container.
    *   **`valueFrom.secretKeyRef`**: This is the crucial part. It tells Kubernetes to get the value for the environment variable from a specific key within a named Secret.

2.  **Apply the Manifest**:
    Create the pod using the manifest file.

    ```bash
    kubectl apply -f secret-pod.yaml
    ```

#### 3. Verify the Environment Variables are Set

Finally, you need to confirm that the container has the environment variables set correctly.

1.  **Exec into the container**:
    Since the container is running a simple `redis` image, you can get a shell inside it to check its environment.

    ```bash
    kubectl exec -it secret-env-pod -- /bin/sh
    ```

2.  **Print the environment variables**:
    Once inside the container's shell, use the `echo` or `printenv` command to display the values of the environment variables you defined.

    ```sh
    # Inside the container's shell
    echo $SECRET_USERNAME
    echo $SECRET_PASSWORD
    ```
    The output should be `myuser` and `mypassword123`, respectively. This demonstrates that Kubernetes successfully retrieved the base64-decoded values from the `mysecret` Secret and injected them as environment variables into your running container.

