# Terraform

We're using [Terraform](https://www.terraform.io/docs/providers/aws/index.html) to create infrastructure within Amazon Web Services.

## State files

When working as a team, it is necessary to have a shared [State](https://www.terraform.io/docs/state/index.html) file. This can be done in a few ways, but we're using the Terraform feature called [Backends](https://www.terraform.io/docs/backends/index.html), which will store the statefiles in private S3 buckets.

```
s3://<organization_name>-state-<account_shortname>/tf.state
```

### Initial remote statefile (*Nota Bene*)

Unfortunately there's a bit of a chicken & egg situation with the remote statefiles. They have to be manually uploaded to S3 when you want to use them.

From a [Github Issue 22770](https://github.com/hashicorp/terraform/issues/22770):
```
This is unfortunately one of those situations where one person's bug is another person's feature. Terraform 0.12 intentionally checks that the state is present when retrieving state with terraform_remote_state because the usual interpretation of data sources is as assertions that something should already exist, and thus it's appropriate to return an error if the indicated object does not exist: that indicates that something has been applied out of order, and so usually better to return an error than to silently do something unexpected.
```

## Workspaces

Additionally, when working with multiple AWS accounts you will need to switch between the different accounts. Terraform has a feature called [Workspaces](https://www.terraform.io/docs/state/workspaces.html) that we'll use for this.

You can create new workspaces using terraform workspace new ```<workspace-name>```. So, you can create a workspace for both of your accounts using a sequence such as:

```
terraform workspace new account-1
terraform workspace new account-2
```

And you can switch you're current workspace using terraform workspace select:

```
terraform workspace select account-1
```

## Configuring the AWS provider to be workspace aware

```
[account-1]
aws_access_key_id=AKIAIOSFODNN7EXAMPLE
aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[account-2]
aws_access_key_id=AKIAI44QH8DHBEXAMPLE
aws_secret_access_key=je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY
```
