# Day 12/40 - Kubernetes Daemonset Explained - Daemonsets, Job and Cronjob in Kubernetes

## Check out the video below for Day12 👇

[![Day12/40 - Kubernetes Daemonset Explained - Daemonsets, Job and Cronjob in Kubernetes](https://img.youtube.com/vi/kvITrySpy_k/sddefault.jpg)](https://youtu.be/kvITrySpy_k)


### What is a daemonset?
- A daemon set is another type of Kubernetes object that controls pods. Unlike deployment, the DS automatically deploys 1 pod to each available node. You don't need to update the replica based on demand; the DS takes care of it by spinning X number of pods for X number of nodes.
- If you create a ds in a cluster of 5 nodes, then 5 pods will be created.
- If you add another node to the cluster, a new pod will be automatically created on the new node.

### Examples of daemonset
- kube-proxy
- calico
- weave-net
- monitoring agents etc

### Daemonset for a 3 nodes cluster

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/bb803dc2-f9ab-4fe3-a0bb-0eacdfcf3ce0)



### Sample DS yaml used in the demo

```yaml
apiVersion: apps/v1
kind:  DaemonSet
metadata:
  name: nginx-ds
  labels:
    env: demo
spec:
  template:
    metadata:
      labels:
        env: demo
      name: nginx
    spec:
      containers:
      - image: nginx
        name: nginx
        ports:
        - containerPort: 80
  selector:
    matchLabels:
      env: demo
```


Of course. Here is a guide to help you with Task 12 from the "40 Days of Kubernetes" challenge, drawing upon the provided sources. This task focuses on exploring DaemonSets, CronJobs, and Jobs in Kubernetes.

### Prerequisites: Kubernetes Cluster Setup

Before you begin, you'll need a running Kubernetes cluster. If you don't have one, you can set up a local multi-node cluster using **Kind (Kubernetes in Docker)**, which is the method used in this tutorial series.

*   **Installation**: The Day 6 video provides step-by-step instructions for installing Kind and creating a multi-node cluster. This involves creating a `config.yaml` file to define your control plane and worker nodes.
*   **Port Binding (for Kind users)**: Kind clusters, by default, do not expose node ports to your local machine (localhost). The Day 9 video explains how to configure your Kind cluster's YAML file to map container ports to your host machine, which is necessary to access services externally.

### 1. Create a DaemonSet

A **DaemonSet** ensures that all (or some) nodes in your cluster run a copy of a pod. This is different from a Deployment or ReplicaSet where you specify a number of replicas that are scheduled across available nodes. A DaemonSet automatically creates one pod on each node and adds a pod to any new nodes that join the cluster.

**Common use cases for DaemonSets include:**
*   Monitoring agents
*   Logging agents
*   Networking components like Kube-proxy and CNI plugins (e.g., Weave, Flannel, Calico)

**Steps to create a DaemonSet:**

1.  **Create a YAML manifest** for the DaemonSet. You can adapt a Deployment YAML, as the structure is very similar.
    *   Set `kind` to `DaemonSet` (with a capital D and S).
    *   The API version for a DaemonSet is `apps/v1`, similar to a Deployment.
    *   **Important**: Remove the `replicas` field. DaemonSets do not use a replica count because they are designed to run one pod per node.
    *   Use a `selector` with `matchLabels` to link the DaemonSet to the pods it will manage, based on the labels defined in the pod template.

    Here is a sample YAML, based on the demonstration in the sources:

    ```yaml
    # ds.yaml
    apiVersion: apps/v1
    kind: DaemonSet
    metadata:
      name: my-daemonset-ds
      labels:
        app: my-daemonset
    spec:
      selector:
        matchLabels:
          app: my-daemonset
      template:
        metadata:
          labels:
            app: my-daemonset
        spec:
          containers:
          - name: nginx-container
            image: nginx
    ```

2.  **Apply the manifest** using `kubectl apply -f ds.yaml`.

3.  **Verify the DaemonSet**.
    *   Run `kubectl get daemonset` or `kubectl get ds`. You can use the `-A` flag to see DaemonSets in all namespaces, such as `kube-proxy` which runs in the `kube-system` namespace.
    *   Run `kubectl get pods -o wide` to see the pods created by the DaemonSet and confirm they are scheduled on your worker nodes. Note that pods may not be scheduled on the control-plane node due to default taints that prevent custom workloads from running there.

### 2. Create a CronJob

A **CronJob** creates Jobs on a repeating schedule. It is useful for running periodic tasks like generating reports or performing cleanup jobs. While Jobs and CronJobs are not a primary focus of the CKA exam, understanding them is valuable.

**Understanding Cron Syntax:**

A cron schedule is defined by five fields, representing minute, hour, day of the month, month, and day of the week.

```
# ┌───────────── minute (0 - 59)
# │ ┌───────────── hour (0 - 23)
# │ │ ┌───────────── day of the month (1 - 31)
# │ │ │ ┌───────────── month (1 - 12)
# │ │ │ │ ┌───────────── day of the week (0 - 6) (Sunday to Saturday)
# │ │ │ │ │
# │ │ │ │ │
# * * * * *
```
*   An asterisk (`*`) means every instance (e.g., every minute, every hour).
*   To run a task **every 5 minutes**, you use the syntax `*/5` in the minute field. The full expression would be `*/5 * * * *`.

**Steps to create a CronJob:**

1.  **Create a YAML manifest** for the CronJob.
    *   The `kind` is `CronJob`.
    *   The `spec` contains the `schedule` using the cron syntax and a `jobTemplate` which defines the pod to be created.
    *   For this task, use the `busybox` image and a command to print "40daysofkubernetes".

    Here is a sample YAML for your task:

    ```yaml
    # cronjob.yaml
    apiVersion: batch/v1
    kind: CronJob
    metadata:
      name: hello-cronjob
    spec:
      schedule: "*/5 * * * *"
      jobTemplate:
        spec:
          template:
            spec:
              containers:
              - name: hello-container
                image: busybox:1.28
                command: ["/bin/sh", "-c", "echo 40daysofkubernetes"]
              restartPolicy: OnFailure
    ```
    *Note: The `restartPolicy` is important for Jobs. `OnFailure` means it will restart the container if it fails, but not if it completes successfully.*

2.  **Apply the manifest**: `kubectl apply -f cronjob.yaml`.

3.  **Verify the CronJob**.
    *   Run `kubectl get cronjob` to see your CronJob.
    *   After 5 minutes, a Job and a corresponding pod will be created. You can check this with `kubectl get jobs` and `kubectl get pods`.
    *   To see the output, check the logs of the completed pod: `kubectl logs <pod-name>`. You should see "40daysofkubernetes" printed.

### 3. Kubernetes Job

For completeness, a **Job** is a Kubernetes object that creates one or more pods and ensures a specified number of them successfully terminate. Unlike a CronJob, a Job runs only once to completion and is not scheduled to repeat. It's often used for one-off tasks like installation scripts or operations in an automation pipeline.

### Share Your Learnings

This is a key part of the **#40DaysOfKubernetes challenge**. The goal is not just to complete the task, but to share what you've learned with the community.

*   **Document your takeaways** in a blog post. Explain the concepts in simple language so that even a beginner can understand them.
*   You could discuss the differences between DaemonSets and Deployments, the practical applications of CronJobs, and the structure of their YAML files.
*   **Embed the video** you followed in your blog post to make the content more visually appealing.
*   **Share your blog post** on social media platforms like LinkedIn or Twitter. Use the hashtag `#40DaysOfKubernetes` and tag the creator so your submission is recognized. Showcasing your skills publicly is a great way to gain exposure and reinforce your learning.

Good luck with the exercise! If you face any issues, the series creator recommends reaching out on the dedicated Discord community server for assistance.