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

resource "azurerm_public_ip" "dockerdev" {
  name = "remotingPublicIP2"
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

resource "azurerm_network_interface" "dockerdev" {
  name = "ddni"
  location = "West Europe"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"

  ip_configuration {
    name = "dockerdevconfiguration1"
    subnet_id = "${azurerm_subnet.kubernetesdev.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = "${azurerm_public_ip.dockerdev.id}"
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

resource "azurerm_storage_account" "dockerdev" {
  name = "accsakubedevsg8"
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

resource "azurerm_storage_container" "dockerdev" {
  name = "vhds8"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"
  storage_account_name = "${azurerm_storage_account.dockerdev.name}"
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
    sku = "2016-Datacenter-with-Containers"
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

resource "azurerm_virtual_machine" "dockerdev" {
  name = "ddvm"
  location = "West Europe"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"
  network_interface_ids = ["${azurerm_network_interface.dockerdev.id}"]
  vm_size = "Standard_DS2_v2"

  storage_image_reference {
    publisher = "MicrosoftVisualStudio"
    offer = "VisualStudio"
    sku = "VS-2017-Comm-WS2016"
    version = "latest"
  }

  storage_os_disk {
    name = "myosdisk2"
    vhd_uri = "${azurerm_storage_account.kubernetesdev.primary_blob_endpoint}${azurerm_storage_container.dockerdev.name}/myosdisk2.vhd"
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

resource "azurerm_virtual_machine_extension" "dockerdev" {
  name = "getsources"
  location = "westeurope"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"
  virtual_machine_name = "${azurerm_virtual_machine.dockerdev.name}"
  publisher = "Microsoft.Compute"
  type = "CustomScriptExtension"
  type_handler_version = "1.8"

  settings = <<SETTINGS
{
  "commandToExecute": "mkdir C:\\Sources && cd C:\\Sources && git clone https://github.com/sebug/TalkNotesBack.git && git clone https://github.com/sebug/TalkNotesFront.git && git clone https://github.com/sebug/InvokeDockerServer.git && git clone https://github.com/sebug/TalkNotesComposed.git && PowerShell -command \"Invoke-WebRequest -Uri https://nuget.org/nuget.exe -OutFile C:\\Sources\\nuget.exe\""
}
SETTINGS
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
  "commandToExecute": "PowerShell -NoProfile -ExecutionPolicy Bypass -Command \"iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))\" && SET \"PATH=%PATH%;%ALLUSERSPROFILE%\\chocolatey\\bin\" && choco install -y git && mkdir C:\\Tools && PowerShell -command \"Invoke-WebRequest -Uri https://github.com/docker/compose/releases/download/1.14.0/docker-compose-Windows-x86_64.exe -OutFile $env:ProgramFiles\\Docker\\docker-compose.exe\" && mkdir C:\\Sources"
}
SETTINGS
}

output "dockerdev-ip" {
  value = "${azurerm_public_ip.dockerdev.ip_address}"
}

output "kubernetesdev-internal-ip" {
  value = "${azurerm_network_interface.kubernetesdev.private_ip_address}"
}

output "kubernetesdev-external-ip" {
  value = "${azurerm_public_ip.kubernetesdev.ip_address}"
}
