# for subscription_id, create a subscription or use an existing one, and find it in portal.azure.com
# for client_id and client_secret, see https://www.terraform.io/docs/providers/azurerm/index.html
# for tenant_id, from the portal, if you click on the Help icon in the upper right and then choose 
# 'Show Diagnostics' you can find the tenant id in the diagnostic JSON.
provider "azurerm" {
  subscription_id = "b866fe50-afff-4cf3-b9cc-fe2c826abfba"
  client_id       = "f0ac0c60-15fc-48e9-a832-4126497651b8"
  client_secret   = "L4obqfBx3Q66cys/8MZ721pJCd0nkookL2xRr4hG1uk="
  tenant_id       = "116e9905-19fc-428e-93d4-bcaffb833597"
}
# create a resource group 
resource "azurerm_resource_group" "helloterraform" {
    name = "terraformtest"
    location = "West US"
}
# create a virtual network
resource "azurerm_virtual_network" "helloterraformnetwork" {
    name = "acctvn"
    address_space = ["10.0.0.0/16"]
    location = "West US"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
}
# create subnet
resource "azurerm_subnet" "helloterraformsubnet" {
    name = "acctsub"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    virtual_network_name = "${azurerm_virtual_network.helloterraformnetwork.name}"
    address_prefix = "10.0.2.0/24"
}
# create public IP
resource "azurerm_public_ip" "helloterraformips" {
    name = "terraformtestip"
    location = "West US"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    public_ip_address_allocation = "dynamic"
    tags {
        environment = "TerraformDemo"
    }
}
# create network interface
resource "azurerm_network_interface" "helloterraformnic" {
    name = "tfni"
    location = "West US"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    ip_configuration {
        name = "testconfiguration1"
        subnet_id = "${azurerm_subnet.helloterraformsubnet.id}"
        private_ip_address_allocation = "static"
        private_ip_address = "10.0.2.5"
        public_ip_address_id = "${azurerm_public_ip.helloterraformips.id}"
    }
}
# create storage account
resource "azurerm_storage_account" "redapt89" {
    name = "redapt89"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    location = "westus"
    account_type = "Standard_LRS"
    tags {
        environment = "staging"
    }
}
# create storage container
resource "azurerm_storage_container" "redapt89storagecontainer" {
    name = "vhd"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    storage_account_name = "${azurerm_storage_account.redapt89.name}"
    container_access_type = "private"
    depends_on = ["azurerm_storage_account.redapt89"]
}
# create virtual machine
resource "azurerm_virtual_machine" "helloterraformvm" {
    name = "terraformvm"
    location = "West US"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    network_interface_ids = ["${azurerm_network_interface.helloterraformnic.id}"]
    vm_size = "Standard_A0"
    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "14.04.2-LTS"
        version = "latest"
    }
    storage_os_disk {
        name = "myosdisk"
        vhd_uri = "${azurerm_storage_account.redapt89.primary_blob_endpoint}${azurerm_storage_container.redapt89storagecontainer.name}/myosdisk.vhd"
        caching = "ReadWrite"
        create_option = "FromImage"
    }
    os_profile {
        computer_name = "hostname"
        admin_username = "testadmin"
        admin_password = "Password1234!"
    }
    os_profile_linux_config {
        disable_password_authentication = false
    }
    tags {
        environment = "staging"
    }
}

resource "azurerm_virtual_machine_extension" "test" {
  name                 = "hostname"
  location             = "West US"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_machine_name = "${azurerm_virtual_machine.test.name}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"

  settings = <<SETTINGS
{
  "fileUris": "https://raw.githubusercontent.com/andyt338/azure-tf-jenkins/master/userdata.sh"
}
SETTINGS

  protected_settings = <<SETTINGS
 {
   "commandToExecute": "bash userdata.sh"
 }

  tags {
    environment = "Production"
  }
}