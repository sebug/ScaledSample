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

The Terraform definition outputs the development machine IP which you can connect to using RDP. When there, in PowerShell you can connect to the Kubernetes dev machine:

	winrm s winrm/config/client '@{TrustedHosts="THE_IP_OF_THE_ACCTVM_MACHINE"}'
	Enter-PSSession -ComputerName THE_IP_OF_THE_ACCTVM_MACHINE

This could clearly be done as a post-deploy script.

In any case, here's how you copy over the files for the docker server machine to access:

	$cs = New-PSSession -ComputerName THE_IP_OF_THE_ACCTVM_MACHINE -Name KubeDev
	Copy-Item -Recurse .\bin\Release\PublishOutput -Destination C:\Applications\TalkNotesBack -ToSession $cs


