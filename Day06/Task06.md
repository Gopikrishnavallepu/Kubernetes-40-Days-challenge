### Please follow task.md for the Day6 assignment

**Documentation followed in this video:**
- Install [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- Kind cluster [docs](https://kind.sigs.k8s.io/docs/user/quick-start/)
- kind example config [yaml](https://raw.githubusercontent.com/kubernetes-sigs/kind/main/site/content/docs/user/kind-example-config.yaml)

**Below domains and all of its sub-domains are allowed to be referred in the exam**
- https://kubernetes.io/docs
- https://kubernetes.io/blog/
- Kubernetes cheat sheet : https://kubernetes.io/docs/reference/kubectl/quick-reference/


Of course. Here is a blog post documenting my learnings from the video and detailing the step-by-step process of setting up single-node and multi-node `kind` clusters.

---

### Getting Started with Kubernetes: Your First Local Cluster with `kind`

In the previous videos of this CKA series, we've explored the architecture of Kubernetes and understood *why* we need an orchestration system. Now it's time to roll up our sleeves and get our hands dirty. Before diving into managed Kubernetes services like EKS, AKS, or GKE, it's crucial to build a solid foundation by running Kubernetes locally. This approach gives you maximum learning, full access to the control plane, and the ability to practice concepts without incurring cloud costs.

For our local setup, we will use **`kind` (Kubernetes IN Docker)**, a popular and lightweight tool for running local Kubernetes clusters using Docker containers as nodes. This guide will walk you through setting up both a single-node and a multi-node cluster, just as you would for the CKA exam.

#### My Learnings from the Video

*   **Local Installation is Key for Learning**: The video emphasized that starting with a local Kubernetes installation is the best way to learn. Managed services abstract away many of the underlying components (like the control plane node), which limits your ability to troubleshoot and understand how the cluster truly works.
*   **`kind` Uses Docker Containers as Nodes**: The core concept of `kind` is that it spins up Docker containers and treats each one as a Kubernetes node (either a control plane or a worker). This makes it incredibly lightweight and easy to set up on any machine with Docker installed.
*   **Cluster Configuration is Declarative**: While you can create a simple cluster with a single command, `kind` allows you to define a multi-node cluster declaratively using a YAML configuration file. This file specifies the number of control plane and worker nodes you need.
*   **`kubectl` is the Universal CLI**: Interacting with any Kubernetes cluster, whether local or in the cloud, is done through the `kubectl` command-line utility. It's the primary tool for deploying applications and managing cluster resources.
*   **Context is Crucial for Managing Multiple Clusters**: When working with more than one cluster, it's essential to manage your `kubectl` context. The `kubectl config use-context` command allows you to switch between clusters, ensuring your commands are sent to the correct one. This is a critical step in the CKA exam before attempting any task.

### Step 1: Install Prerequisites (`kubectl` and `kind`)

Before creating a cluster, we need two tools: `kind` to create the cluster and `kubectl` to interact with it.

#### Installing `kind`

As per the official `kind` documentation, the installation process varies by operating system. I'm on a Mac, so I used Homebrew.

```bash
# Command for macOS using Homebrew
brew install kind

# Explanation:
# 'brew install' is a command for the Homebrew package manager on macOS.
# It downloads and installs the 'kind' binary, making it available in my system's PATH.
# For other operating systems like Windows or Linux, you can follow the instructions on the kind.sigs.k8s.io website.
```

#### Installing `kubectl`

`kubectl` is the Kubernetes command-line client. You'll need it to run commands against your new cluster.

```bash
# Command for macOS using Homebrew
brew install kubectl

# Explanation:
# Similar to the 'kind' installation, this command uses Homebrew to install the 'kubectl' CLI tool.
# You can find detailed instructions for all operating systems in the official Kubernetes documentation.
```

To verify the installation, you can check the client version.

```bash
kubectl version --client
```

### Step 2: Create a Single-Node Cluster (Kubernetes v1.29)

For the CKA exam, it's important to use the specific Kubernetes version required. Let's create a single-node cluster using version `1.29`.

First, find the correct node image tag for the desired version from the `kind` release notes. For v1.29.4, the image is `kindest/node:v1.29.4@sha256:...`.

```bash
# Command to create a single-node cluster with a specific version and name
kind create cluster --name cka-cluster1 --image kindest/node:v1.29.4

# Explanation:
# 'kind create cluster' is the command to create a new cluster.
# '--name cka-cluster1' assigns a custom name to our cluster. If omitted, the default name is 'kind'.
# '--image kindest/node:v1.29.4' specifies the Docker image to use for the node, ensuring we get Kubernetes v1.29.
```

This command will pull the Docker image and configure a single container to act as both the control plane and a worker node.

### Step 3: Delete the Cluster

`kind` makes it just as easy to tear down a cluster as it is to create one.

```bash
# Command to delete the cluster by name
kind delete cluster --name cka-cluster1

# Explanation:
# 'kind delete cluster' removes all the Docker containers associated with the specified cluster.
# '--name cka-cluster1' identifies which cluster to delete.
```

### Step 4: Create a Multi-Node Cluster (Kubernetes v1.30)

For more realistic scenarios, we need a cluster with separate control plane and worker nodes. We'll create a cluster named `cka-cluster2` with one control plane and three worker nodes running Kubernetes v1.30.

This requires a configuration file. Create a file named `kind-config.yaml`.

```bash
# Command to create the configuration file
touch kind-config.yaml
```

Now, add the following content to `kind-config.yaml`. This structure is based on the `kind` documentation for multi-node clusters.

```yaml
# A multi-node kind cluster configuration
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: cka-cluster2
nodes:
- role: control-plane
  # This is for the Kubernetes v1.30 node image
  image: kindest/node:v1.30.0
- role: worker
  image: kindest/node:v1.30.0
- role: worker
  image: kindest/node:v1.30.0
- role: worker
  image: kindest/node:v1.30.0
```

Now, create the cluster using this configuration file.

```bash
# Command to create a cluster from a config file
kind create cluster --config kind-config.yaml

# Explanation:
# We again use 'kind create cluster'.
# '--config kind-config.yaml' tells 'kind' to use our YAML file to define the cluster's topology, including the roles and number of nodes.
```

### Step 5: Set Context and Verify the Cluster

After creating a new cluster, `kind` automatically sets the `kubectl` context to the new cluster. In a real-world scenario or an exam, you might need to switch contexts manually.

```bash
# Command to switch kubectl context
kubectl config use-context kind-cka-cluster2

# Explanation:
# 'kubectl config use-context' sets the current cluster that kubectl will interact with.
# The context name is typically prefixed with 'kind-' followed by your cluster name. This is a crucial command to run before starting any task in the CKA exam.
```

Now, let's verify that all our nodes are ready.

```bash
# Command to list all nodes in the current context
kubectl get nodes

# Explanation:
# This command communicates with the API server of the 'cka-cluster2' cluster to retrieve the status of all nodes.
```

You should see an output with one control-plane node and three worker nodes, all in the `Ready` state.

### Step 6: Verify the Nodes are Docker Containers

Finally, let's confirm that these Kubernetes nodes are, in fact, just Docker containers.

```bash
# Command to list running Docker containers
docker ps

# Explanation:
# This command lists all active containers managed by the Docker daemon on your host machine.
# You will see containers with names corresponding to your kind nodes (e.g., cka-cluster2-control-plane, cka-cluster2-worker, etc.), confirming that 'kind' truly means Kubernetes IN Docker.
```

Congratulations! You have successfully set up a multi-node Kubernetes cluster on your local machine. You are now ready to start deploying applications and exploring the core concepts of Kubernetes.

***
*References:*
*   *Video: "Day 6/40 - Kubernetes Multi Node Cluster Setup Step By Step | Kind Tutorial" by "Tech Tutorials with Piyush"*
*   *Video: "Day 4/40 - Why Kubernetes Is Used - Kubernetes Simply Explained - CKA Full Course 2025" by "Tech Tutorials with Piyush"*
*   *Official Documentation: Kubernetes.io and kind.sigs.k8s.io were referenced in the video and are essential resources for installation and command syntax.*

Perfect 🚀 Here’s a **Kind (Kubernetes IN Docker) Commands Cheat Sheet** — you can keep this handy for **interviews and real-time practice**.

---

# 📝 Kind (Kubernetes in Docker) Cheat Sheet

| Command                                               | Description                                                                                               | Example                                            |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| `kind create cluster`                                 | Create a cluster with default name `kind`                                                                 | `kind create cluster`                              |
| `kind create cluster --name <name>`                   | Create a cluster with a custom name                                                                       | `kind create cluster --name mydev`                 |
| `kind get clusters`                                   | List all clusters created by Kind                                                                         | `kind get clusters`                                |
| `kind delete cluster`                                 | Delete the default cluster `kind`                                                                         | `kind delete cluster`                              |
| `kind delete cluster --name <name>`                   | Delete a specific cluster                                                                                 | `kind delete cluster --name mydev`                 |
| `kind export kubeconfig --name <name>`                | Export kubeconfig for a specific cluster (adds to \~/.kube/config)                                        | `kind export kubeconfig --name mydev`              |
| `kubectl config get-contexts`                         | List all contexts (each Kind cluster creates a context)                                                   | `kubectl config get-contexts`                      |
| `kubectl config current-context`                      | Show current active cluster context                                                                       | `kubectl config current-context`                   |
| `kubectl cluster-info --context kind-<name>`          | Show cluster details for a specific cluster                                                               | `kubectl cluster-info --context kind-mydev`        |
| `docker ps`                                           | List Docker containers (each Kind node runs in a container)                                               | `docker ps`                                        |
| `docker exec -it <container_id> bash`                 | Access a Kind node container directly                                                                     | `docker exec -it kind-control-plane bash`          |
| `kind load docker-image <image>:<tag> --name <name>`  | Load a local Docker image into a Kind cluster (since Kind nodes don’t see local Docker images by default) | `kind load docker-image myapp:latest --name mydev` |
| `kind load image-archive <archive.tar> --name <name>` | Load image tarball into Kind cluster                                                                      | `kind load image-archive app.tar --name mydev`     |
| `kind get kubeconfig --name <name>`                   | Get kubeconfig details for a specific cluster                                                             | `kind get kubeconfig --name mydev`                 |
| `kind create cluster --config <file>`                 | Create cluster with a custom config (multi-node, ingress, etc.)                                           | `kind create cluster --config kind-config.yaml`    |

---

# 🔹 Interview Value Add

* **Why Kind?** → Lightweight, local Kubernetes testing in Docker (good for CI/CD, DevSecOps, experimentation).
* **Multi-cluster Management** → You can run multiple clusters (e.g., `kind-dev`, `kind-test`).
* **Image loading** → Local Docker images don’t automatically appear in Kind → must use `kind load`.
* **Custom config** → You can create multi-node clusters (1 control-plane + multiple workers) using YAML config.

---

👉 Do you want me to also give you a **sample Kind cluster config YAML** (multi-node with ingress enabled), so you can explain *“I’ve created custom Kind clusters in real time”* in interviews?
