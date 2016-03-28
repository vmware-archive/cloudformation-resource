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
   check_output=$(run_docker "$(generate_input 'ignore')" '/opt/resource/check')
   echo "$check_output" >&2
   echo $check_output | jq -r '.[0].timestamp // empty'
}

cleanup() {
   echo 'Running cleanup' >&2
   run_docker "$(generate_input '')" '/tmp/test/cleanup.sh'
}

echo "Check that the stack is not present"
if  [ ! -z "$(get_timestamp)" ]; then
   echo "the stack should not exist at this point"
   cleanup
   exit 1
fi

echo $(generate_input initial_cloudformation.json)
echo $(generate_input)
echo "Run initial creation"
run_docker "$(generate_input initial_cloudformation.json)"

timestamp1="$(get_timestamp)"
if  [ -z "$timestamp1" ]; then
   echo "the stack is not present in the aws account"
   cleanup
   exit 1
fi

echo "Run second creation (update)"
run_docker "$(generate_input updated_cloudformation.json)"

timestamp2="$(get_timestamp)"
echo $timestamp1
echo $timestamp2
if [ "$timestamp2" == "$timestamp1" ]; then
   echo "the stack has not been updated"
   cleanup
   exit 1
fi

cleanup

