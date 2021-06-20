# Variable declarations for the low-latency edge PoP micro-fabric environment.

variable "fabric_name" {
  type    = string
  default = "pontifex-edge-pop"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "global_supernet_cidr" {
  type    = string
  default = "172.16.0.0/12"
}

variable "asn_base" {
  type    = number
  default = 64600
}

variable "regions" {
  type = map(object({
    cloud_provider         = string
    sovereign_jurisdiction = string
    az_count               = number
    anycast_enabled        = bool
    failover_priority      = number
    weight                 = number
    egress_capacity_gbps   = number
  }))
  default = {
    "us-east-edge" = {
      cloud_provider         = "baremetal"
      sovereign_jurisdiction = "us-fed"
      az_count               = 2
      anycast_enabled        = true
      failover_priority      = 1
      weight                 = 100
      egress_capacity_gbps   = 40
    }
    "eu-west-edge" = {
      cloud_provider         = "baremetal"
      sovereign_jurisdiction = "eu-gdpr"
      az_count               = 2
      anycast_enabled        = true
      failover_priority      = 2
      weight                 = 80
      egress_capacity_gbps   = 40
    }
  }
}
