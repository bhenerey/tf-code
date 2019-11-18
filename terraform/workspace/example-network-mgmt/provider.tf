provider "aws" {
  region  = "${var.AWS_REGION}"
  profile = "${var.vpc_attributes.workspace_profile_name}"
}
