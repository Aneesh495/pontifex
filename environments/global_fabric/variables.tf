# Variable declarations for the planetary production global fabric environment.

variable "fabric_name" {
  type    = string
  default = "pontifex-global-prod"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "global_supernet_cidr" {
  type    = string
  default = "10.0.0.0/8"
}

variable "asn_base" {
  type    = number
  default = 64512
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
    "us-east-1" = {
      cloud_provider         = "aws"
      sovereign_jurisdiction = "us-fed"
      az_count               = 3
      anycast_enabled        = true
      failover_priority      = 1
      weight                 = 100
      egress_capacity_gbps   = 100
    }
    "us-west-2" = {
      cloud_provider         = "aws"
      sovereign_jurisdiction = "us-fed"
      az_count               = 3
      anycast_enabled        = true
      failover_priority      = 2
      weight                 = 80
      egress_capacity_gbps   = 80
    }
    "eu-central-1" = {
      cloud_provider         = "gcp"
      sovereign_jurisdiction = "eu-gdpr"
      az_count               = 3
      anycast_enabled        = true
      failover_priority      = 3
      weight                 = 90
      egress_capacity_gbps   = 100
    }
  }
}
