#!/bin/sh

fatal () {
  echo "$1" >&2
  exit 1
}

load_env () {
  export $( cat | jq -r '
    "STACK_NAME=" + .source.stack_name,
    "AWS_ACCESS_KEY_ID=" + .source.aws_access_key,
    "AWS_SECRET_ACCESS_KEY=" + .source.aws_secret_key,
    "AWS_DEFAULT_REGION=" + (.source.aws_region // "us-east-1"),
    "REF=" + (.version.ref // "")
  ' )
}

load_stack () {
  aws cloudformation describe-stacks --stack-name="$STACK_NAME" \
    > /tmp/stack

  if [ 0 -eq $( jq '.Stacks | length' < /tmp/stack ) ]; then
    echo 'stack missing' >&2
    exit 1
  fi
}

is_stack_completed () {
  STATUS=$( jqstack '.Stacks[0].StackStatus' )
  [ \( "$STATUS" = "CREATE_COMPLETE" \) -o \( "$STATUS" = "UPDATE_COMPLETE" \) ]
  return $?
}

jqstack () {
  jq -r "$1" < /tmp/stack
}
