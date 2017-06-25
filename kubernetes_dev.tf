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
  name = "accsakubedevsg"
  resource_group_name = "${azurerm_resource_group.kubernetesdev.name}"
  location = "westeurope"
  account_type = "Standard_LRS"

  tags {
    environment = "dev"
  }
}

resource "azurerm_storage_container" "kubernetesdev" {
  name = "vhds"
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
    vhd_uri = "${azurerm_storage_account.kubernetesdev.primary_blob_endpoint}${azurerm_storage_container.kubernetesdev.name}/myosdisk2.vhd"
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
