# Scaled Sample
This is the [terraform](https://www.terraform.io) part of my try at getting a scaled n-tiers application to work inside Windows Server Core on Docker, maybe even distributed on [Kubernetes](https://docs.microsoft.com/en-us/azure/container-service/container-service-kubernetes-windows-walkthrough). It spins up a development VM (expensive!) and a Windows Server 2016 instance to try out docker-compose etc.

The two related projects are [TalkNotesBack](https://github.com/sebug/TalkNotesBack) and [TalkNotesFront](https://github.com/sebug/TalkNotesFront).

Here's the plan:

1. Create a multi-layer app
2. Put them in containers as in [this deploying docker containers on Windows Server 2016 talk](https://vimeo.com/171704656)
3. Push them to an Azure Container Registry
4. Use ACS for Kubernetes + Windows to host them
5. ???
6. Profit!

The sources of the back-end and frontend services are downloaded and built using multi-stage docker images. Just switch to the C:\Sources\TalkNotesComposed directory and execute

	docker-compose -f docker-compose.yml build

Now let's push that image:

	docker login ${container-registry-loginserver}

Where ${container-registry-loginserver} is one of the outputs of terraform. So are admin username and password. In the next lines I'm using a concrete value for it, but you get the gist:

	docker tag talknotesback kubecontainerregistry.azurecr.io/scaled/talknotesback
	docker tag talknotesfront kubecontainerregistry.azurecr.io/scaled/talknotesfront
	docker push kubecontainerregistry.azurecr.io/scaled/talknotesback
	docker push kubecontainerregistry.azurecr.io/scaled/talknotesfront

Now that the images are up, let's create an azure container service instance. From what I've read there's no generalized Windows support yet? Also, I had some issues using the service principal created for Terraform, so we're using the other credentials.

	az login
	az acs create --orchestrator-type=kubernetes --resource-group kubernetesdev --name=scaledSebugCluster --agent-count=2 --generate-ssh-keys --windows --admin-username azureuser --admin-password $KUBERNETES_ADMIN_PASSWORD
	az acs kubernetes get-credentials --resource-group=kubernetesdev --name=scaledSebugCluster


Since we have a private registry, we'll have to create a secret to pull it: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/

First, let's verify it works:

	docker login kubecontainerregistry.azurecr.io

Now we can create the secret:

	kubectl create secret docker-registry regsecret --docker-server=kubecontainerregistry.azurecr.io --docker-username=... --docker-password=... --docker-email=...

With all this in place we can spin up our deployment and services:

	kubectl apply -f scaled-sample-deployment.yaml

There is still one annoying thing left: I didn't get DNS to work, so post the pods being up you'll have to run the following, replacing the pod ID as given:

	kubectl get pods
	kubectl exec talk-notes-front-2272407718-ktms7 -- powershell -Command '"http://$($env:TALKNOTESBACK_SERVICE_HOST):$($env:TALKNOTESBACK_SERVICE_PORT)/TalkNoteService.svc" > C:\\TalkNotesFront\\address.txt'

This kind of destroys the whole point so we'll have to work on doing this differently.
