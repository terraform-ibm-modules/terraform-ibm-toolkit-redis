
locals {
  role        = "Operator"
  name_prefix = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name        = lower(replace(var.name != "" ? var.name : "${local.name_prefix}-${var.label}", "/[^a-zA-Z0-9_\\-\\.]/", ""))
  service     = "databases-for-redis"
  key_name    = "${local.name}-key"
}

resource null_resource print-names {
  provisioner "local-exec" {
    command = "echo 'Resource group name: ${var.resource_group_name}'"
  }
}

data "ibm_resource_group" "resource_group" {
  depends_on = [null_resource.print-names]

  name = var.resource_group_name
}

resource ibm_database redis_instance {
  count = var.provision ? 1 : 0

  name              = local.name
  service           = local.service
  plan              = var.plan
  location          = var.resource_location
  resource_group_id = data.ibm_resource_group.resource_group.id
  tags              = var.tags

  service_endpoints = var.private_endpoints ? "private" : "public-and-private"

  timeouts {
    create = "90m"
    update = "30m"
    delete = "30m"
  }
}

data ibm_database redis_instance {
  depends_on        = [ibm_database.redis_instance]

  name              = local.name
  resource_group_id = data.ibm_resource_group.resource_group.id
  location          = var.resource_location
  service           = local.service
}

resource "ibm_resource_key" "redis_key" {
  name                 = local.key_name
  role                 = local.role
  resource_instance_id = data.ibm_database.redis_instance.id

  timeouts {
    create = "15m"
    delete = "15m"
  }
}
