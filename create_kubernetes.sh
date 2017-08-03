#!/bin/sh
az login
az acs create --orchestrator-type=kubernetes --resource-group kubernetesdev --name=scaledSebugCluster --dns-prefix=sgk8scluster --agent-count=2 --generate-ssh-keys --windows --admin-username azureuser --admin-password $1

