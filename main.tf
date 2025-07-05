provider "azurerm" {
  features {}
  subscription_id = "bb649e30-d650-43a7-a6d1-2c85eab4d156"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-archivespace-demo"
  location = "eastus"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-archivespace"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-archivespace"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "publicip-archivespace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-archivespace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ArchivesSpace"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "8081", "8089", "8983", "3306"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-archivespace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-archivespace"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "osdisk-archivespace"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  admin_ssh_key {
    username   = "azureuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCob26B/DYDJbiCde82Yq9sEjt9BZgLaRjW7mkKZECIg3GkfCJxpNvMxp9rsiilk4gyMyxE9NigaHBP6Om1FIQ+hl9UV/92KPA7p9+9CXc0LL4INEwolI4OsYqG8lIgmALMXlYTcJunUnW8xjHyxxsMChOqzzwfI1X6PvJno+3oclzBfuvNM13EXDIRy+2fj9ph7wuE+vHBpAcJm3wJ65dR4UgDGyHzWeydW9pUjbxx8QEQ285XRDG0lqPsvtdxd0BZd3Ik4HmTZWLqPLAgbhl5Ejzx25Yf4tszD9KtX3ZHyaWR1PBSD9czlmYezB/fqjyoO2L21hweeomdCQqFIZ+K57uVUb4uyANEJ4O5s22UZm/CmDPDx3rw6QTdZMKIL466OIkh/74U8w459gXCtYxyMMcMGU9vdQx7jN2spuqkAhtAdQlGBXLwXJrfgzyfXs6Ns6TAj46c6uwMhviRgqjNcHZ9OktgrtfR1HOiMoY9nCseKYd5oes2IQnErXwFa5mcqB+nrvDc5vTob8nUHtbUZcl2fK3PGvM4t53l8aX38R6bx2GeYE+q1qJaHfkLpfCO5X3ii2JOSOdB5sqE/n0SD3AbzfSK1FRlW40YX9KsQuPBxOZBk2nNc5TfEniZqBLCfdNVMLM2DeMQXhPR/Smv0y2WU7vr5KsLJSvb5hWJw== shakir@Shakirs-MacBook-Pro.local"
  }
}

resource "azurerm_virtual_machine_extension" "archivesspace_install" {
  name                 = "install-archivesspace"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = <<SETTINGS
    {}
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "script": "${base64encode(file("install-archivesspace.sh"))}"
    }
PROTECTED_SETTINGS
}

output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "ssh_command" {
  value = "ssh azureuser@${azurerm_public_ip.public_ip.ip_address}"
}

output "archivesspace_url" {
  value = "http://${azurerm_public_ip.public_ip.ip_address}"
}

output "archivesspace_staff_url" {
  value = "http://${azurerm_public_ip.public_ip.ip_address}/staff/"
}