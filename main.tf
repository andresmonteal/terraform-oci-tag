// Copyright (c) 2018, 2021, Oracle and/or its affiliates.

########################
# Tags
########################

locals {
  default_freeform_tags = {
    terraformed = "Please do not edit manually"
    module      = "oracle-terraform-oci-iam-tag"
  }
  merged_freeform_tags = merge(var.freeform_tags, local.default_freeform_tags)
  compartment_id       = try(data.oci_identity_compartments.compartment[0].compartments[0].id, var.compartment_id)
}

resource "oci_identity_tag_namespace" "main" {
  # required  
  compartment_id = local.compartment_id
  description    = var.description
  name           = var.name

  # optional
  freeform_tags = local.merged_freeform_tags
  defined_tags  = var.defined_tags
  is_retired    = false

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }
}

resource "oci_identity_tag" "main" {
  # required
  for_each = var.tags

  name             = each.key
  description      = lookup(each.value, "description", "")
  tag_namespace_id = oci_identity_tag_namespace.main.id
  is_cost_tracking = lookup(each.value, "is_cost_tracking", false)

  # optional
  dynamic "validator" {
    for_each = length(each.value["list"]) > 0 ? { "list" : each.value["list"] } : {}
    content {
      #Required
      validator_type = "ENUM"
      values         = each.value["list"]
    }
  }

  freeform_tags = local.merged_freeform_tags
  defined_tags  = var.defined_tags
  is_retired    = false

  timeouts {
    create = "15m"
    update = "15m"
    delete = "12h"
  }
}

resource "oci_identity_tag_default" "main" {
  for_each = var.tags_default

  #Required
  compartment_id    = data.oci_identity_compartments.tag_default[each.key].compartments[0].id
  tag_definition_id = oci_identity_tag.main[each.value["tag"]].id
  value             = each.value["value"]

  #Optional
  is_required = false
}