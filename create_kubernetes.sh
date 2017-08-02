#!/bin/sh
az login
az acs create --orchestrator-type=kubernetes --resource-group kubernetesdev --name=scaledSebugCluster --agent-count=2 --generate-ssh-keys --windows --admin-username azureuser --admin-password $1
az acs kubernetes get-credentials --resource-group=kubernetesdev --name=scaledSebugCluster
