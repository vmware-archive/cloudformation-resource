#!/bin/sh

exec 3>&1
exec 1>&2
set -eu

[ ! -e /tmp/build/* ] || cd /tmp/build/*

REM () {
  /bin/echo $( date -u +"%Y-%m-%dT%H:%M:%SZ" ) "$@"
}

fatal () {
  echo "FATAL: $1" >&2
  exit 1
}

load_env () {
  export $( cat | tee /tmp/stdin | jq -r '
    "STACK_NAME=" + .source.name,
    "AWS_ACCESS_KEY_ID=" + .source.access_key,
    "AWS_SECRET_ACCESS_KEY=" + .source.secret_key,
    "AWS_DEFAULT_REGION=" + ( .source.region // "us-east-1" ),
    "VERSION=" + ( .version | tojson | tostring // "" ),
    "VERSION_ARN=" + ( .version.arn // "" ),
    "VERSION_TIME=" + ( .version.arn // "" )
  ' )
}

load_stack () {
  # $1 fail when not found (default true)
  
  REM 'checking stack'
  
  ( aws cloudformation describe-stacks --stack-name="$STACK_NAME" 2>&1 || true ) \
    > /tmp/stack

  if grep -qE 'Stack with id [^ ]+ does not exist' /tmp/stack ; then
    if [ "true" = "${1:-true}" ] ; then
      fatal 'stack missing'
    fi
    
    if [ -z "$VERSION_ARN" ] ; then
      VERSION_ARN=$( date -u +"%Y-%m-%dT%H:%M:%SZ" )
    fi
      
    jq -c -n \
      --arg arn "$VERSION_ARN" \
      '{"Stacks": [ { "StackId": $arn, "StackStatus": "DELETE_COMPLETE", "LastUpdatedTime": "DELETED" } ] }' \
      > /tmp/stack
  fi
}

is_stack_completed () {
  STATUS=$( jqstack '.Stacks[0].StackStatus // "DELETE_COMPLETE"' )
  [ \( "$STATUS" = "CREATE_COMPLETE" \) -o \( "$STATUS" = "UPDATE_COMPLETE" \) -o \( "$STATUS" = "DELETE_COMPLETE" \) ]
  return $?
}

is_stack_errored () {
  STATUS=$( jqstack '.Stacks[0].StackStatus // "DELETE_COMPLETE"' )
  [ \( "$STATUS" = "CREATE_FAILED" \) -o \( "$STATUS" = "ROLLBACK_COMPLETE" \) -o \( "$STATUS" = "UPDATE_ROLLBACK_COMPLETE" \) -o \( "$STATUS" = "ROLLBACK_FAILED" \) -o \( "$STATUS" = "DELETE_FAILED" \) -o \( "$STATUS" = "UPDATE_ROLLBACK_FAILED" \) ]
  return $?
}

jqstack () {
  jq -c -r "$1" < /tmp/stack
}
