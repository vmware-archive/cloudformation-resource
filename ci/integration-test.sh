#!/bin/sh

source /opt/resource/common.sh
start_docker

set -eux
set -o pipefail

image_id=$(docker build -q task-repo | cut -d : -f2 | cut -c 1-12)

generate_input() {
   cloudformation_file=${1}

   cat << INPUT_JSON
   {
     "source": {
       "aws_access_key": "${AWS_ACCESS_KEY}",
       "aws_secret_key": "${AWS_SECRET_KEY}",
       "aws_region": "${AWS_REGION}"
     },
     "params": {
       "cloudformation_file": "${cloudformation_file}",
       "stack_name": "cloudformation-resource-integration"
     },
     "version": {
       "timestamp": ""
     }
   }
INPUT_JSON
}

generate_input_with_policy() {
   cloudformation_file=${1}
   policy_file=${2}

   cat << INPUT_JSON
   {
     "source": {
       "aws_access_key": "${AWS_ACCESS_KEY}",
       "aws_secret_key": "${AWS_SECRET_KEY}",
       "aws_region": "${AWS_REGION}"
     },
     "params": {
       "cloudformation_file": "${cloudformation_file}",
       "policy_file": "${policy_file}",
       "stack_name": "cloudformation-resource-integration-with-policy"
     },
     "version": {
       "timestamp": ""
     }
   }
INPUT_JSON
}

run_docker() {
   json_input=${1}
   command=${2:-'/opt/resource/out'}
   current_dir=$(pwd)

   echo "$json_input" | \
   docker run -i \
   -a stdin -a stdout -a stderr \
   -v $current_dir/task-repo/ci:/tmp/test \
   ${image_id} ${command} /tmp/test
}

get_timestamp() {
   echo "Getting timestamp" >&2
   check_output=$(run_docker "$(generate_input_with_policy 'ignore' 'ignore')" '/opt/resource/check')
   echo "$check_output" >&2
   echo $check_output | jq -r '.[0] // empty'
}

get_timestamp_without_policy() {
   echo "Getting timestamp" >&2
   check_output=$(run_docker "$(generate_input 'ignore')" '/opt/resource/check')
   echo "$check_output" >&2
   echo $check_output | jq -r '.[0] // empty'
}

cleanup() {
   echo 'Running cleanup' >&2
   run_docker "$(generate_input_with_policy '' '')" '/tmp/test/cleanup.sh'
}

cleanup_without_policy() {
   echo 'Running cleanup' >&2
   run_docker "$(generate_input '')" '/tmp/test/cleanup.sh'
}

echo "Check that the stack is not present"
if  [ ! -z "$(get_timestamp)" ]; then
   echo "the stack should not exist at this point"
   cleanup
   exit 1
fi

echo $(generate_input_with_policy two_bucket_cloudformation.json deny_policy.json)
echo $(generate_input two_bucket_cloudformation.json)
echo "Run initial creation"
run_docker "$(generate_input_with_policy two_bucket_cloudformation.json deny_policy.json)"

timestamp1="$(get_timestamp)"
if  [ -z "$timestamp1" ]; then
   echo "the stack is not present in the aws account"
   cleanup
   exit 1
fi

echo "Witness policy enforcement"
run_docker "$(generate_input_with_policy single_bucket_cloudformation.json deny_policy.json)"
timestamp2="$(get_timestamp)"
run_docker "$(generate_input_with_policy '' '')" '/tmp/test/describe_stack_resources.sh' | grep TestBucket2

echo "Update policy"
run_docker "$(generate_input_with_policy single_bucket_cloudformation.json allow_policy.json)"

echo "Witness version change"
timestamp3="$(get_timestamp)"
echo $timestamp2
echo $timestamp3
if [ "$timestamp3" == "$timestamp2" ]; then
   echo "the stack has not been updated"
   cleanup
   exit 1
fi

echo "Witness updated policy enforcement (deletion allowed)"
run_docker "$(generate_input_with_policy single_bucket_cloudformation.json allow_policy.json)"
timestamp4="$(get_timestamp)"
run_docker "$(generate_input_with_policy '' '')" '/tmp/test/describe_stack_resources.sh' | grep -v TestBucket2

cleanup

echo "Create additional stack without policy"
run_docker "$(generate_input other_bucket_cloudformation.json)"

timestamp1="$(get_timestamp_without_policy)"
if  [ -z "$timestamp1" ]; then
   echo "the stack is not present in the aws account"
   cleanup_without_policy
   exit 1
fi

cleanup_without_policy
