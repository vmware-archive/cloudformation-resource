# AWS CloudFormation Stack Resource

A [Concourse](http://concourse.ci) resource to manage your [AWS CloudFormation](http://aws.amazon.com/cloudformation/) stacks.


## Source Configuration

 * **`name`** - the stack name
 * **`access_key`** - AWS access key
 * **`secret_key`** - AWS secret key
 * `region` - the region to manage the stack (default `us-east-1`)


## Behavior

### `check`

Trigger when the stack is successfully created or updated.


### `in`

Pulls down stack outputs, resource IDs, and metadata.

 * `/arn.txt` - the stack ARN
 * `/outputs.json` - a JSON object with the stack [outputs](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html)
 * `/resources.json` - a JSON object with the logical IDs of all created resources (resource name + `Id` is the key). Names of security groups are also set (resource name + `Name`)

Parameters:

 * `allow_deleted` - by default the resource will fail when referencing a deleted stack (default `false`)


### `out`

Create, update, or delete the stack. The `parameters` and `tags` data should by a simple key-value hash of names and values (e.g. `{"MyName":"MyValue"}`).

 * **`template`** - path to a CloudFormation template (do not configure when enabling `delete`)
 * `parameters` - path to a JSON file
 * `parameters_aws` - path to a aws cloudformation formatted JSON file
 * `tags` - path to a JSON file
 * `capabilities` - array of additional [capabilities](http://docs.aws.amazon.com/AWSCloudFormation/latest/APIReference/API_CreateStack.html) (e.g. `CAPABILITY_IAM`)
 * `delete` - set to `true` to delete the stack (default `false`)


## Installation

This resource is not included with the standard Concourse release. Use one of the following methods.


### Deployment-wide

To install on all Concourse workers, update your deployment manifest to add a new `resource_types`...

    properties:
      groundcrew:
        resource_types:
          - image: "docker:///dpb587/aws-cloudformation-stack-resource#stable"
            type: "aws-cloudformation-stack"


### Pipeline-specific

To use on a single pipeline, update your pipeline to add a new `resource_types`...

    resource_types:
      - name: "aws-cloudformation-stack"
        type: "docker-image"
        source:
          repository: "dpb587/aws-cloudformation-stack-resource"
          tag: "stable"


### Example

The following example uses a repository to store configuration and, whenever the repository is updated, the stack will be created/updated according to template or parameter changes. Another job watches the stack for changes and will execute a hook to propagate stack results and resources to dependent services.

    resources:
      # a stack we will be updating
      - name: "acme-stack"
        type: "aws-cloudformation-stack"
        source:
          name: "my-acme-stack-name"
          access_key: "my-aws-access-key"
          secret_key: "my-aws-secret-key"
      
      # a repository to version your configuration
      - name: "acme-config"
        type: "git-resource"
        source:
          repository: "git@git.acme.internal:infra.git"
    
    jobs:
      # update the stack when changes are made in your repo
      - name: "update-prod-stack"
        plan:
          - get: "acme-config"
            trigger: true
          - put: "acme-stack"
            params:
              template: "acme-infra/vpc/template.json"
              parameters: "acme-infra/vpc/generate-parameters.sh"
      
      # execute a hook whenever the stack is created/updated
      # propagate task will see `stack/arn.txt`, `stack/outputs.json`, ...
      - name: "propagate-resources"
        plan:
          - aggregate:
              - get: "stack"
                resource: "acme-stack"
                trigger: true
              - get: "acme-config"
          - task: "propagate"
            file: "acme-config/vpc/post-update-hooks.yml"

Another example is the [main](./ci/pipelines/main.yml) pipeline which creates/updates/deletes a stack as part of some lightweight tests.
