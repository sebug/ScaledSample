resource "azurerm_resource_group" "kubernetesdev" {
  name = "kubernetesdev"
  location = "West Europe"
}

resource "azurerm_public_ip" "kubernetesdev" {
  name = "remotingPublicIP1"
  location = "West Europe"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"
  public_ip_address_allocation = "dynamic"
}

resource "azurerm_virtual_network" "kubernetesdev" {
  name = "acctvn"
  address_space = ["10.0.0.0/16"]
  location = "West Europe"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"
}

resource "azurerm_subnet" "kubernetesdev" {
  name = "acctsub"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"
  virtual_network_name = "${azurerm_virtual_network.kubernetesdev.name}"
  address_prefix = "10.0.2.0/24"
}

resource "azurerm_network_interface" "kubernetesdev" {
  name = "acctni"
  location = "West Europe"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"

  ip_configuration {
    name = "kubernetesdevconfiguration1"
    subnet_id = "${azurerm_subnet.kubernetesdev.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${azurerm_public_ip.kubernetesdev.id}"
  }
}

resource "azurerm_storage_account" "kubernetesdev" {
  name = "accsakubedevsg7"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"
  location = "westeurope"
  account_type = "Standard_LRS"

  tags {
    environment = "dev"
  }
}

resource "azurerm_storage_container" "kubernetesdev" {
  name = "vhds7"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"
  storage_account_name = "${azurerm_storage_account.kubernetesdev.name}"
  container_access_type = "private"
}

variable "containerdevpass" {
  default = ""
}

resource "azurerm_virtual_machine" "kubernetesdev" {
  name = "acctvm"
  location = "West Europe"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"
  network_interface_ids = ["${azurerm_network_interface.kubernetesdev.id}"]
  vm_size = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer = "WindowsServer"
    sku = "2016-Datacenter"
    version = "latest"
  }

  storage_os_disk {
    name = "myosdisk1"
    vhd_uri = "${azurerm_storage_account.kubernetesdev.primary_blob_endpoint}${azurerm_storage_container.kubernetesdev.name}/myosdisk1.vhd"
    caching = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name = "containerdev"
    admin_username = "sgfeller"
    admin_password = "${var.containerdevpass}"
  }

  tags {
    environment = "dev"
  }
}

# On the Kubernetes development machine we also want docker-compose to test
# before pushing
resource "azurerm_virtual_machine_extension" "kubernetesdev" {
  name = "getsources"
  location = "westeurope"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"
  virtual_machine_name = "${azurerm_virtual_machine.kubernetesdev.name}"
  publisher = "Microsoft.Compute"
  type = "CustomScriptExtension"
  type_handler_version = "1.8"

  settings = <<SETTINGS
{
  "commandToExecute": "PowerShell -NoProfile -ExecutionPolicy Bypass -Command \"iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))\" && SET \"PATH=%PATH%;%ALLUSERSPROFILE%\\chocolatey\\bin\" && choco install -y git && mkdir C:\\Tools && mkdir C:\\Sources && cd C:\\Sources && \"C:\\Program Files\\Git\\cmd\\git.exe\" clone https://github.com/sebug/TalkNotesBack.git && \"C:\\Program Files\\Git\\cmd\\git.exe\" clone https://github.com/sebug/TalkNotesFront.git && \"C:\\Program Files\\Git\\cmd\\git.exe\" clone https://github.com/sebug/InvokeDockerServer.git && \"C:\\Program Files\\Git\\cmd\\git.exe\" clone https://github.com/sebug/TalkNotesComposed.git && PowerShell -NoProfile -ExecutionPolicy Bypass -Command \"Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force\" && PowerShell -NoProfile -ExecutionPolicy Bypass -Command \"Install-Module -Name DockerMsftProvider -Force\" && PowerShell -NoProfile -ExecutionPolicy Bypass -Command \"Install-Package -Name docker -ProviderName DockerMsftProvider -Force\" && choco install -y docker-compose && PowerShell -NoProfile -ExecutionPolicy Bypass -Command \"$wc = New-Object net.webclient; $wc.DownloadFile('https://download.docker.com/win/static/edge/x86_64/docker-17.06.0-ce.zip', \\\"$env:TEMP\\docker-17.06.0-ce.zip\\\"); Expand-Archive -Path \\\"$env:TEMP\\docker-17.06.0-ce.zip\\\" -DestinationPath $env:ProgramFiles -Force\""
}
SETTINGS
}

resource "azurerm_storage_account" "registrystorage" {
  name = "sebugregistry"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"
  location = "westeurope"
  account_type = "Standard_LRS"
}

resource "azurerm_container_registry" "kubernetesdev" {
  name = "kubeContainerRegistry"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"
  location = "westeurope"
  admin_enabled = true
  sku = "Basic"

  storage_account {
    name = "${azurerm_storage_account.registrystorage.name}"
    access_key = "${azurerm_storage_account.registrystorage.primary_access_key}"
  }
}

output "kubernetesdev-internal-ip" {
  value = "${azurerm_network_interface.kubernetesdev.private_ip_address}"
}

output "kubernetesdev-external-ip" {
  value = "${azurerm_public_ip.kubernetesdev.ip_address}"
}

output "container-registry-loginserver" {
  value = "${azurerm_container_registry.kubernetesdev.login_server}"
}

output "container-registry-admin-username" {
  value = "${azurerm_container_registry.kubernetesdev.admin_username}"
}

output "container-registry-admin-password" {
  value = "${azurerm_container_registry.kubernetesdev.admin_password}"
}
