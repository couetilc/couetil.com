# `www` infrastructure code

## AMIs

to get a list of AMIs for use with Amazon through System Manager Parameters:

```sh
aws ssm get-parameters-by-path \
	--path /aws/service/ami-amazon-linux-latest \
	--query 'Parameters[].Name'
```

For raw image information straight from ec2 (this is usually a high number of images):

```sh
aws ec2 describe-images \
	--filters "Name=architecture,Values=arm64" \
	--filters "Name=virtualization-type,Values=hvm" \
	--filters="Name=hypervisor,Values=xen" \
	--filters="Name=ena-support,Values=true" \
	--filters="Name=owner-alias,Values=amazon" \
	--query 'sort_by(Images, &CreationDate)[].Name'
```
