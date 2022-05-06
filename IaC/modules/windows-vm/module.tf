variable "windows-vm" {
  type = object({
    create              = bool
    name                = string
    resource_group_name = string
    location            = string
    license_type        = string
    size                = string
    admin_username      = string
    admin_password      = string
    subnet_id           = string
    tags                = map(string)

    os_disk = object({
      caching              = string
      storage_account_type = string
    })
  })
}

variable "availability_set_id" {
  description = "ID for the availability set the VM will exist in."
  type        = string
  default     = null
}

variable "source_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    offer     = null
    publisher = null
    sku       = null
    version   = null
  }

}

variable "computer_name" {
  description = "the VM's computer name, will default to the name property if null"
  type        = string
  default     = null
}

variable "image_id" {
  description = "If deploying a custom VM Image, enter in the the ID of the VM image in this param."
  type        = string
  default     = null
}

resource "azurerm_network_interface" "vm-nic" {
  name                = "${var.windows-vm.name}-nic"
  location            = var.windows-vm.location
  resource_group_name = var.windows-vm.resource_group_name

  ip_configuration {
    name                          = "${var.windows-vm.name}-ip"
    subnet_id                     = var.windows-vm.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

}

resource "azurerm_windows_virtual_machine" "windows-vm" {
  count                 = var.windows-vm.create ? 1 : 0
  name                  = var.windows-vm.name
  computer_name         = var.computer_name
  resource_group_name   = var.windows-vm.resource_group_name
  location              = var.windows-vm.location
  license_type          = var.windows-vm.license_type
  size                  = var.windows-vm.size
  admin_username        = var.windows-vm.admin_username
  admin_password        = var.windows-vm.admin_password
  network_interface_ids = [azurerm_network_interface.vm-nic.id]
  source_image_id       = var.image_id != null ? var.image_id : null
  availability_set_id   = var.availability_set_id != null ? var.availability_set_id : null
  tags                  = var.windows-vm.tags

  os_disk {
    caching              = var.windows-vm.os_disk.caching
    storage_account_type = var.windows-vm.os_disk.storage_account_type
  }
  dynamic "source_image_reference" {
    for_each = var.image_id != null ? [] : [1]
    content {
      publisher = var.source_image_reference.publisher
      offer     = var.source_image_reference.offer
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
    }
  }

}

output "id" {
  value = azurerm_windows_virtual_machine.windows-vm[0].id
}


