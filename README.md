# Cloudformation Resource

An output only resource (at the moment) that will configure your stack in AWS using Cloudformation.

## Source Configuration

* `aws_access_key`: *Required.* The user access key that will be required to make changes to the Cloudformation stack.

* `aws_secret_key`: *Required.* The user secret key that is required to make changes to the Cloudformation stack.

* `aws_region`: *Optional.* The region associated with the Clouformation stack that we are making changes to. The region is defaulted to us-east-1.

### Pipeline Example

```yaml
resource_types:
- name: cloudformation
  type: docker-image
    source:
      repository: pcfseceng/cloudformation-resource

resources:
- name: aws-setup
  type: cloudformation
  source:
    aws_access_key: some_access_key
    aws_secret_key: some_secret_key
    aws_region: us-east-1

jobs:
- name: update-cloudformation
  plan:
  - put: aws-setup
    params:
      cloudformation_file: path/to/cloudformation/configuration/file
      stack_name: name_of_aws_stack_to_configure
      policy_file: path/to/cloudformation/policy/file
```

## Behavior

### `out`: Submit changes to your Cloudformation stack.

Given a Cloudformation configuration file and a AWS stack name, this will apply your Cloudformation configuration to the specified stack in AWS.

#### Parameters

* `cloudformation_file`: *Required.* A path to a file containing the Cloudformation configuration.

* `stack_name`: *Required.* The name of the stack in AWS that this will apply the Cloudformation configuration to.

* `policy_file`: *Optional.* A path to a file containing the stack policy.

* `capabilities`: *Optional.* Additional CloudFormation capabilities required (example "CAPABILITY_IAM")
  "[Currently, the only valid value is CAPABILITY_IAM](http://docs.aws.amazon.com/AWSCloudFormation/latest/APIReference/API_CreateStack.html)"

* `quiet`: *Optional.* Disables trace output from being printed (which may contain credentials).
