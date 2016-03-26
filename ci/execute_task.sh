#!/bin/bash
set -eux

echo $AWS_ACCESS_KEY
echo $AWS_SECRET_KEY
echo $AWS_REGION

fly -t private \
   execute \
   -c integration-test.yml \
   -i task-repo=.. \
   -p

