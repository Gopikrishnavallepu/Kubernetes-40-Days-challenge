
# Day 5/40 - What is Kubernetes - Kubernetes Architecture Explained ☸️


## Check out the video below for Day5 👇

[![Day 5/40 - What is Kubernetes - Kubernetes Architecture Explained](https://img.youtube.com/vi/SGGkUCctL4I/sddefault.jpg)](https://youtu.be/SGGkUCctL4I)


## Kubernetes Architecture

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/f15fbf28-5d18-4469-8a28-edd13678cbbf)

## Master/Control plane Node V/s Worker Node ( Node is nothing but a Virtual machine)

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/ef04ec3d-9f3a-4ac5-8a6a-31e877bfabf3)

## ApiServer :- Client interacts with the cluster using ApiServer

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/b8aeb299-9fc9-49da-9c87-0a6eb948ebd1)

## Scheduler: decide which pod to be scheduled on which node based on different factors

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/189208b6-a01e-4e3f-baf9-ae9a9d0f3daf)

## Controller Manager

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/9aece452-6d76-452f-9c89-0f7825151312)

## ETCD Server - Key value database that stores the cluster state and configuration

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/81e037e3-78f0-41a7-8589-f2b4ec3af511)

## Kubelet - Node-level agent that helps container management and receives instructions from Api server

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/bd178509-c49c-4206-bc11-147ac91d2713)

## Kube proxy - Pod to pod communication

![image](https://github.com/piyushsachdeva/CKA-2024/assets/40286378/e99ec3f5-5d73-4554-99d4-a7905d463f64)

Of course. Here is a detailed breakdown of my learnings, diagrams, and explanations based on the provided video about Kubernetes architecture.

### My Learnings from the Video

The video provided a comprehensive, high-level overview of the Kubernetes architecture, breaking down what could be an overwhelming topic into digestible parts. My key learnings are:

*   **The Master-Worker Model is Central**: Kubernetes operates on a clear division of labor. The **Control Plane** (or Master Node) acts as the "board of directors," making decisions and giving instructions but not doing the actual groundwork. The **Worker Nodes** are where the applications (inside containers and Pods) actually run, doing the "ground work" as instructed.
*   **The API Server is the Brain's Entry Point**: Every single interaction with the Kubernetes cluster, whether from a user or another component, goes through the **API Server**. It's the central gateway that validates requests and coordinates all the other components.
*   **`etcd` is the Cluster's Single Source of Truth**: I learned that `etcd` is a key-value data store that holds the entire state of the cluster—every configuration, every Pod, every node, every secret. The API Server is the sole component authorized to read from and write to `etcd`, ensuring data consistency and security. When you ask for the status of something (like `kubectl get pods`), the API server just queries `etcd` for the stored information.
*   **Component Responsibilities are Specialized**: Each control plane component has a very specific job:
    *   The **Scheduler** is like a logistics manager, finding the best-fit worker node for a new Pod based on resource constraints like CPU and memory.
    *   The **Controller Manager** is a watchdog, continuously monitoring the cluster's state to ensure the actual state matches the desired state (e.g., restarting a crashed Pod).
    *   On the worker nodes, the **Kubelet** is the local agent that receives instructions from the API Server and carries them out (e.g., creating or deleting a Pod on that specific node).
    *   **Kube-proxy** is the network specialist, managing network rules on each node so Pods can communicate with each other.
*   **Pods are More Than Just Wrappers**: A Pod is the smallest deployable unit in Kubernetes, but it's not just a simple wrapper. It's an environment that encapsulates one or more containers, allowing them to share resources. The analogy of a "sack" protecting a baby in the womb was particularly helpful for visualizing this concept.

### Kubernetes Architecture Diagram

Here is a text-based diagram illustrating the Kubernetes architecture as described in the video.

```
+-------------------------------------------------------------------------+
|                               CONTROL PLANE (Master Node/VM)            |
|                                                                         |
|  +-----------------------+      +-----------------------+               |
|  |       Scheduler       |<---->|      API Server       |<----(kubectl)-+---- [ User ]
|  | (Finds best node for  |      |  (Cluster Gateway)    |               |
|  |  a Pod)               |      | (Validates/Processes) |<--------------+
|  +-----------------------+      +-----------+-----------+               |
|          ^                            ^     |                           |
|          |                            |     |                           |
|  +-------+---------------+    +-------v-----+-------+                   |
|  |  Controller Manager   |<-->|       etcd          |                   |
|  | (Maintains desired    |    | (Key-Value Store /  |                   |
|  |  state, watches objs) |    |  Cluster State)     |                   |
|  +-----------------------+    +---------------------+                   |
|                                                                         |
+------------------------------------------+------------------------------+
                                           | (Instructions to Kubelet)
                                           v
+------------------------------------------+------------------------------+
| WORKER NODE 1 (VM)                       | WORKER NODE 2 (VM)           |
|                                          |                              |
|  +-----------------------+               |  +-----------------------+   |
|  |        Kubelet        |<--------------+  |        Kubelet        |   |
|  |  (Agent on node, talks|               |  |  (Agent on node, talks|   |
|  |   to API Server)      |               |  |   to API Server)      |   |
|  +---------+-------------+               |  +---------+-------------+   |
|            |                             |            |                 |
|            v (Manages Pods)              |            v (Manages Pods)  |
|  +-----------------------+               |  +-----------------------+   |
|  |      Kube-proxy       |               |  |      Kube-proxy       |   |
|  |   (Manages network    |               |  |   (Manages network    |   |
|  |    rules on node)     |               |  |    rules on node)     |   |
|  +---------+-------------+               |  +-----------------------+   |
|            |                             |                              |
|  +---------v-------------+   +-----------v-----------+                   |
|  |         Pod           |   |         Pod           |                   |
|  | +-------------------+ |   | +-------------------+ |                   |
|  | |    Container      | |   | |    Container      | |                   |
|  | +-------------------+ |   | +-------------------+ |                   |
|  +-----------------------+   +-----------------------+                   |
+------------------------------------------+------------------------------+
```

### End-to-End Flow: `kubectl create pod`

This diagram illustrates the step-by-step process that occurs when a user runs a command to create a Pod, as detailed in the video.

```
                               +-----------------+
                               |  1. kubectl     |
                               |    create pod   |
                               +--------+--------+
                                        |
                                        v
+---------------------------------------+------------------------------------------+
| CONTROL PLANE                                                                    |
|                                                                                  |
|  +--------------------------------+       +------------------------------------+ |
|  | 2. API Server                  |------>| 3. etcd                            | |
|  |  - Authenticates & Validates   |       |  - Creates an entry for the        | |
|  |    the request            |       |    new Pod                    | |
|  +-----------------+--------------+       +------------------^-----------------+ |
|                    |                                         | 4. Response       |
|  +-----------------v--------------+                          |   "Entry made"    |
|  | 5. Scheduler                   |<-------------------------+                   |
|  |  - Sees an unscheduled Pod     |                                             |
|  |  - Finds the best Node (e.g.,  |                                             |
|  |    Node A)             |                                             |
|  |  - Informs API Server          |                                             |
|  +-----------------+--------------+                                             |
|                    | 6. "Schedule on Node A"                                     |
|                    v                                                             |
+--------------------+-------------------------------------------------------------+
                     | 7. API Server sends instruction
                     |    to the Kubelet on Node A
                     v
+--------------------+-------------------------------------------------------------+
| WORKER NODE A                                                                    |
|                                                                                  |
|  +--------------------------------+                                              |
|  | 8. Kubelet                     |                                              |
|  |  - Receives request from API   |                                              |
|  |    Server                 |                                              |
|  |  - Creates the actual Pod &    |                                              |
|  |    starts its container(s)|                                              |
|  +-----------------+--------------+                                              |
|                    | 9. Response to API Server:                                  |
|                    |    "Pod created successfully"                               |
+--------------------+-------------------------------------------------------------+
                     |
                     v
+--------------------+-------------------------------------------------------------+
| CONTROL PLANE                                                                    |
|                                                                                  |
|  +--------------------------------+       +------------------------------------+ |
|  | 10. API Server                 |------>| 11. etcd                           | |
|  |  - Receives success message    |       |  - Updates Pod status in the       | |
|  |  - Updates etcd with status    |       |    database                   | |
|  +-----------------+--------------+       +------------------------------------+ |
|                    |                                                             |
|                    | 12. Final confirmation sent back to user               |
+--------------------+-------------------------------------------------------------+
                     |
                     v
             +-------+----------+
             | USER: "pod/nginx |
             |      created"    |
             +------------------+
```

### Control Plane Component Functions in Simple Terms

*   **API Server**: This is the **front door and main coordinator** of the Kubernetes cluster. Every command you send and every action a component takes goes through the API Server. It checks if you have permission and then tells the other components what to do.
*   **`etcd`**: This is the cluster's **memory and single source of truth**. It’s a database that stores every single detail about the cluster's desired state—what should be running and where. Only the API Server can talk to it.
*   **Scheduler**: This is the **matchmaker**. When you ask to create a new Pod, the Scheduler's only job is to look at all the available worker nodes and pick the best one for that Pod based on available resources like CPU and memory.
*   **Controller Manager**: This is the **watchdog**. It's a collection of controllers that constantly watch the cluster. If something is not right (e.g., a Pod has crashed), the Controller Manager detects this and works to fix it, ensuring the actual state matches the desired state stored in `etcd`.

### A Note on Pods and Containers

In the world of Kubernetes, you don't run containers directly. Instead, you run them inside an object called a **Pod**.

A **container** is the package holding your application and all its dependencies, just like we learned with Docker. It’s the unit of software that you build.

A **Pod** is the smallest and most basic unit that you can deploy in Kubernetes. Think of it as a logical host or a protective "sack" for one or more containers. The containers inside a single Pod share the same network resources and storage, meaning they can easily communicate with each other as if they were on the same machine. While it’s possible to run multiple containers in one Pod (often for helper or "sidecar" tasks), the most common practice is to run just **one container per Pod**.

Ultimately, the goal of using Kubernetes is to host applications inside containers, and those containers must run inside Pods on the worker nodes to be managed by the cluster.

***

*References:*
*   *Video: "Day 5/40 - What is Kubernetes - Kubernetes Architecture Explained" by "Tech Tutorials with Piyush"*
*   *Official Documentation: For further reading, I would consult the official Kubernetes documentation on "Pods" and "Kubernetes Components." (This information is not from the provided source but is a recommended next step for verification).*