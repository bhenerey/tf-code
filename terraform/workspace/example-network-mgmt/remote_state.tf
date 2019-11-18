data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "${var.vpc_attributes.remote_state_bucket}"
    key    = "${var.vpc_attributes.remote_state_key}"
    region = "${var.AWS_REGION}"
  }
}
