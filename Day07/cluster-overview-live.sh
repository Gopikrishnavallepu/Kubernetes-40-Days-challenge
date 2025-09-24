#!/bin/bash
# Script: cluster-overview-live.sh
# Real-time Kubernetes Cluster Overview (Pods, Containers, CPU/Memory, Pods per Namespace)
# Auto-refreshes every 5 seconds
# Requires metrics-server installed

INTERVAL=5  # refresh interval in seconds

while true; do
    clear
    echo -e "\033[1;34m=== Kubernetes Cluster Live Overview ===\033[0m"
    echo "Updated: $(date)"
    
    # Temporary files
    POD_CONTAINER_FILE=$(mktemp)
    NODE_RES_FILE=$(mktemp)
    POD_NS_FILE=$(mktemp)
    
    # Pods & Containers per Node
    kubectl get pods -A -o json | jq -r '.items[] | "\(.spec.nodeName) \(.spec.containers | length) \(.metadata.namespace)"' \
    | awk '{pods[$1]++; containers[$1]+=$2; ns[$1,$3]++} END {for (n in pods) print n, pods[n], containers[n]}' > $POD_CONTAINER_FILE

    # CPU & Memory per Node
    kubectl top nodes --no-headers | awk '{print $1, $2, $3}' > $NODE_RES_FILE

    # Pods per Namespace per Node
    kubectl get pods -A -o json | jq -r '.items[] | "\(.spec.nodeName) \(.metadata.namespace)"' | sort | uniq -c > $POD_NS_FILE

    # Print Node Summary
    printf "\n%-20s %-10s %-12s %-12s %-12s\n" "NODE" "PODS" "CONTAINERS" "CPU(cores)" "MEMORY"
    echo "---------------------------------------------------------------"
    while read -r line; do
        node=$(echo $line | awk '{print $1}')
        pods=$(echo $line | awk '{print $2}')
        containers=$(echo $line | awk '{print $3}')
        cpu=$(grep "^$node" $NODE_RES_FILE | awk '{print $2}')
        mem=$(grep "^$node" $NODE_RES_FILE | awk '{print $3}')
        printf "\033[1;32m%-20s %-10s %-12s %-12s %-12s\033[0m\n" "$node" "$pods" "$containers" "$cpu" "$mem"
    done < $POD_CONTAINER_FILE

    # Print Pods per Namespace per Node
    echo -e "\n\033[1;34m=== Pods per Namespace per Node ===\033[0m"
    awk '{count[$2,$3]=$1} END {for (k in count) {split(k,a,SUBSEP); printf "%-20s %-20s %s\n", a[1], a[2], count[k]}}' $POD_NS_FILE

    # Wait before refreshing
    sleep $INTERVAL
done