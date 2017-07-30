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
