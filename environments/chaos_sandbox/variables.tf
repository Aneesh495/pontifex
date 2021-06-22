# Variable declarations for the isolated chaos sandbox simulation environment.

variable "fabric_name" {
  type    = string
  default = "pontifex-chaos-sandbox"
}

variable "environment" {
  type    = string
  default = "chaos-sandbox"
}

variable "global_supernet_cidr" {
  type    = string
  default = "10.240.0.0/16"
}

variable "asn_base" {
  type    = number
  default = 65000
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
    "sim-zone-alpha" = {
      cloud_provider         = "gcp"
      sovereign_jurisdiction = "us-fed"
      az_count               = 3
      anycast_enabled        = true
      failover_priority      = 1
      weight                 = 100
      egress_capacity_gbps   = 20
    }
    "sim-zone-beta" = {
      cloud_provider         = "aws"
      sovereign_jurisdiction = "eu-gdpr"
      az_count               = 3
      anycast_enabled        = true
      failover_priority      = 2
      weight                 = 100
      egress_capacity_gbps   = 20
    }
    "sim-zone-gamma" = {
      cloud_provider         = "azure"
      sovereign_jurisdiction = "apac-sg"
      az_count               = 3
      anycast_enabled        = true
      failover_priority      = 3
      weight                 = 100
      egress_capacity_gbps   = 20
    }
  }
}
