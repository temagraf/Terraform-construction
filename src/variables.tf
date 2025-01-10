###cloud vars
variable "token" {
  type        = string
  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
}

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}
variable "default_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "VPC network&subnet name"
}

### web vm params
variable "admin" {
  description = "VMs admin"
  type        = string
  default     = "ubuntu"
}

variable "web_vm" {
  description = "VM params for group 'web' (count)"
  type = object({
    count       = number
    name        = string
    image_id    = string
    platform_id = string
    preemptible = bool
    nat         = bool
    resources   = map(number)
    metadata    = map(string)
  })

  default = {
    count       = 2
    name        = "web"
    image_id    = "ubuntu-2004-lts"
    platform_id = "standard-v1"
    preemptible = true
    nat         = true
    resources = {
      cores         = 2
      memory        = 1
      core_fraction = 5
      disk          = 10
    }
    metadata = { serial-port-enable = "1" }
  }
}

### backend? vm params
variable "backend_image_id" {
  description = "Image ID for backend"
  type        = string
  default     = "ubuntu-2004-lts"
}

variable "backend_vm" {
  description = "VM params for group 'backend' (for-each)"
  /*
  По заданию использовать list(object({ vm_name=string, cpu=number, ram=number, disk=number  })),
  но я решил немного расширить
  */
  type = list(object({
    name        = string
    platform_id = string
    preemptible = bool
    nat         = bool
    resources   = map(number)
    metadata    = map(string)
  }))
  default = [
    {
      name        = "main"
      platform_id = "standard-v1"
      preemptible = false
      nat         = true
      resources = {
        cores         = 4
        memory        = 4
        core_fraction = 20
        disk          = 10
      }
      metadata = { serial-port-enable = "1" }
    },
    {
      name        = "replica"
      platform_id = "standard-v1"
      preemptible = true
      nat         = true
      resources = {
        cores         = 2
        memory        = 1
        core_fraction = 5
        disk          = 10
      }
      metadata = { serial-port-enable = "1" }
    }
  ]
}

### storage VM params
variable "storage_vm" {
  description = "VM params for 'storage' (single)"
  type = object({
    name        = string
    image_id    = string
    platform_id = string
    preemptible = bool
    nat         = bool
    resources   = map(number)
    disks = object({
      count  = number
      type   = string
      size   = number
      prefix = string
    })
    metadata = map(string)
  })

  default = {
    name        = "storage"
    image_id    = "ubuntu-2004-lts"
    platform_id = "standard-v1"
    preemptible = false
    nat         = false
    resources = {
      cores         = 2
      memory        = 2
      core_fraction = 5
      disk          = 10
    }
    disks = {
      count  = 3
      size   = 1
      type   = "network-hdd"
      prefix = "disk"
    }
    metadata = { serial-port-enable = "1" }
  }
}
