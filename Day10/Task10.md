# Day 10/40 - Kubernetes Namespace Explained - CKA Full Course 2024


## Check out the video below for Day10 👇

[![Day10/40 - Kubernetes Namespace Explained - CKA Full Course 2024](https://img.youtube.com/vi/yVLXIydlU_0/sddefault.jpg)](https://youtu.be/yVLXIydlU_0)

### What is a Namespace in Kubernetes

- Provides isolation of resources
- Avoid accidental deletion/modification
- Separated by resource type or environment or domain and so on
- Resources can access each other in the same namespace with their first name by the DNS name for other namespaces


![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/d9ae95d5-7224-4d5b-b260-ed09fc53c6fd)


Of course! Here is a detailed walkthrough of the namespace exercise, documented in a blog post format as a continuation of my Kubernetes learning journey.

***

## Kubernetes Namespaces: Achieving Isolation and Order in Your Cluster

Welcome back to my **"40 Days of Kubernetes"** blog! In previous entries, we've created Pods, Deployments, and Services, but so far, all our resources have been created in the `default` namespace. While this is fine for a small cluster or simple projects, real-world Kubernetes environments can become crowded and chaotic without proper organization.

This is where **Namespaces** come in. A Namespace provides a layer of isolation within a single Kubernetes cluster, allowing you to partition cluster resources into logically named groups. Think of it as creating virtual sub-clusters. This is crucial for:

*   **Avoiding Naming Conflicts**: You can have resources with the same name (e.g., `nginx-deployment`) in different namespaces without any issues.
*   **Access Control**: You can assign different permissions and RBAC (Role-Based Access Control) policies to different namespaces, ensuring teams only have access to the resources they need.
*   **Resource Management**: You can set resource quotas on a per-namespace basis to manage CPU and memory usage.
*   **Logical Separation**: It allows you to separate environments like `dev`, `test`, and `prod` within the same physical cluster.

When you provision a Kubernetes cluster, it comes with a few default namespaces, such as `default`, `kube-system` (for control plane components), `kube-public`, and `kube-node-lease`. Any resource you create without specifying a namespace goes into the `default` one.

Today's hands-on exercise will explore how namespaces work and, more importantly, how resources in different namespaces communicate with each other.

### Note on the Lab Environment

As always, I am using a local multi-node cluster created with **kind (Kubernetes in Docker)**. The setup steps are detailed in the Day 6 video of the series. I've also set up an alias `k=kubectl` in my bash profile to speed up my commands, a handy tip from the Day 10 video.

### Task 1: Create Namespaces and Deployments

The first step is to create two namespaces and deploy a simple Nginx application in each.

1.  **Create Two Namespaces:**
    I'll use the imperative `kubectl create namespace` command, which is much faster for simple tasks like this than writing a YAML file.
    ```bash
    k create namespace ns1
    k create namespace ns2
    ```
    To verify, I can list all the namespaces in the cluster.
    ```bash
    k get ns
    # NAME              STATUS   AGE
    # default           Active   2d
    # ns1               Active   10s
    # ns2               Active   9s
    # ... (other system namespaces)
    ```

2.  **Create Deployments in Each Namespace:**
    Now, I'll create an Nginx deployment in each namespace. It's crucial to use the `-n` (or `--namespace`) flag to specify the target namespace. If I forget this flag, the deployment will be created in the `default` namespace.

    ```bash
    # Create deployment in ns1
    k create deployment deploy-ns1 --image=nginx --replicas=1 -n ns1

    # Create deployment in ns2
    k create deployment deploy-ns2 --image=nginx --replicas=1 -n ns2
    ```

3.  **Verify the Deployments and Pods:**
    To see the resources, I again need to specify the namespace.
    ```bash
    # Check pods in ns1
    k get pods -n ns1
    # NAME                          READY   STATUS    RESTARTS   AGE
    # deploy-ns1-6d4b95d6c5-abcde   1/1     Running   0          45s

    # Check pods in ns2
    k get pods -n ns2
    # NAME                          READY   STATUS    RESTARTS   AGE
    # deploy-ns2-5f85f7f8f9-fghij   1/1     Running   0          40s
    ```
    Success! I have a running pod in each of my new namespaces.

### Task 2: Pod-to-Pod Communication using IP Addresses

Next, let's test if a pod in one namespace can directly communicate with a pod in another namespace using its IP address.

1.  **Get the IP Addresses of the Pods:**
    The `-o wide` flag provides extended information, including the pod's IP address and the node it's running on.
    ```bash
    # Get IP for the pod in ns1
    k get pod -n ns1 -o wide
    # NAME                          ...   IP            NODE
    # deploy-ns1-6d4b95d6c5-abcde   ...   10.244.1.4    cka-cluster-3-worker

    # Get IP for the pod in ns2
    k get pod -n ns2 -o wide
    # NAME                          ...   IP            NODE
    # deploy-ns2-5f85f7f8f9-fghij   ...   10.244.2.5    cka-cluster-3-worker2
    ```
    So, the IP for the pod in `ns1` is `10.244.1.4` and for `ns2` is `10.244.2.5`.

2.  **Test Connectivity with `curl`:**
    I'll use `kubectl exec` to run a `curl` command from inside the `ns1` pod, targeting the IP of the `ns2` pod.
    ```bash
    # Get the pod name in ns1
    POD_NS1=$(k get pods -n ns1 -o jsonpath='{.items.metadata.name}')

    # Exec into the pod and curl the IP of the other pod
    k exec -it $POD_NS1 -n ns1 -- curl 10.244.2.5
    ```
    **Result:** It works! The command returns the "Welcome to nginx!" HTML page. This confirms that **pod IP addresses are cluster-wide and directly reachable from any other pod**, regardless of the namespace.

### Task 3: Service-to-Service Communication

While pod IPs work, they are not static; a pod gets a new IP every time it restarts. For stable communication, we need Services. Now, let's explore how services communicate across namespaces.

1.  **Scale the Deployments:**
    First, I'll scale both deployments to 3 replicas.
    ```bash
    k scale deployment deploy-ns1 --replicas=3 -n ns1
    k scale deployment deploy-ns2 --replicas=3 -n ns2
    ```

2.  **Expose Deployments as Services:**
    I'll use the `kubectl expose` command to create a `ClusterIP` service for each deployment.
    ```bash
    # Expose deployment in ns1
    k expose deployment deploy-ns1 --name=svc-ns1 --port=80 -n ns1

    # Expose deployment in ns2
    k expose deployment deploy-ns2 --name=svc-ns2 --port=80 -n ns2
    ```

3.  **Check Service IPs:**
    ```bash
    k get svc -n ns1
    # NAME      TYPE        CLUSTER-IP      PORT(S)
    # svc-ns1   ClusterIP   10.96.123.100   80/TCP

    k get svc -n ns2
    # NAME      TYPE        CLUSTER-IP      PORT(S)
    # svc-ns2   ClusterIP   10.96.200.220   80/TCP
    ```

4.  **Test Service Communication with IP Address:**
    Let's exec into a pod in `ns1` again and try to curl the *ClusterIP* of the service in `ns2`.
    ```bash
    k exec -it $POD_NS1 -n ns1 -- curl 10.96.200.220
    ```
    **Result:** Success again! This shows that service IPs, like pod IPs, are also cluster-wide and can be accessed from any namespace.

5.  **Test Service Communication with Service Name:**
    Now for the interesting part. What if I try to use the service *name* (`svc-ns2`) instead of its IP?
    ```bash
    k exec -it $POD_NS1 -n ns1 -- curl http://svc-ns2
    ```
    **Result:** It fails! The command returns an error: `curl: (6) Could not resolve host: svc-ns2`. This happens because **service hostnames are namespace-scoped, not cluster-wide**. The internal DNS service (`CoreDNS`) in the `ns1` namespace does not know about a service named `svc-ns2`.

6.  **Test Service Communication with FQDN:**
    To resolve a service in another namespace, you must use its **Fully Qualified Domain Name (FQDN)**. The FQDN for a Kubernetes service follows this pattern: `<service-name>.<namespace-name>.svc.cluster.local`.

    Let's try the `curl` command one last time with the FQDN of `svc-ns2`.
    ```bash
    k exec -it $POD_NS1 -n ns1 -- curl http://svc-ns2.ns2.svc.cluster.local
    ```
    **Result:** It works perfectly! The request is successfully resolved and routed to the service in the `ns2` namespace. You can inspect the `/etc/resolv.conf` file inside a pod to see how Kubernetes configures DNS search domains to make this possible.

### Final Step: Cleanup

To clean up all the resources I created, I can simply delete the namespaces. Deleting a namespace will cascade and delete all the objects (Deployments, ReplicaSets, Pods, Services) within it.

```bash
k delete ns ns1 ns2
```

### Key Learnings

This was a fantastic exercise to solidify my understanding of namespaces. My main takeaways are:
*   **IP Addresses are Cluster-Wide**: Both Pod and Service IP addresses are unique across the entire cluster and can be accessed from any namespace.
*   **Hostnames are Namespace-Wide**: Service DNS names (hostnames) are only unique *within* their namespace. To communicate across namespaces, you must use the service's FQDN.
*   **Namespaces Provide Essential Isolation**: They are a fundamental tool for organizing resources, controlling access, and managing multi-tenant or multi-environment clusters effectively.

This concludes today's hands-on lab. Join me next time as we dive into multi-container pods! #40DaysOfKubernetes #CKA #Kubernetes #DevOps

***