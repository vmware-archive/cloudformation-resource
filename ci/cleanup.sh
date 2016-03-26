#!/bin/sh

set -e

# read stdin
jq -M -S . < /dev/stdin | tee /tmp/input
# load AWS creds
export AWS_ACCESS_KEY_ID=$(jq -r .source.aws_access_key < /tmp/input)
export AWS_SECRET_ACCESS_KEY=$(jq -r .source.aws_secret_key < /tmp/input)
export AWS_DEFAULT_REGION=$(jq -r .source.aws_region < /tmp/input)
STACK_NAME=$(jq -r .params.stack_name < /tmp/input)
aws cloudformation delete-stack --stack-name $STACK_NAME
