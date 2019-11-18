variable "AWS_REGION" {
  default = "us-east-2"
}

variable "vpc_attributes" {
  type = "map"

  default = {
    tag_name               = "mgmt-vpc"
    cidr_block             = "10.123.192.0/18"
    remote_state_bucket    = "example-tfstate-mgmt"
    remote_state_key       = "network/terraform.tfstate"
    workspace_profile_name = "example-network-mgmt"
    nat_gw_subnet          = 0 # Set to 0,1,2. This is sorted by subnet_id, not zone.
  }
}

variable "availability_zones" {
  description = "A list of availability zones in which to create subnets"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "cidrs" {
  type = "map"
  default = {
    "dmztier"  = "10.123.192.0/20"
    "apptier"  = "10.123.208.0/20"
    "datatier" = "10.123.224.0/20"
  }
}
