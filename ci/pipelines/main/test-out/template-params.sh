#!/bin/sh

set -e

jq -n \
  --arg build_job_name "$BUILD_JOB_NAME" \
  --arg build_pipeline_name "$BUILD_PIPELINE_NAME" \
  '{
    "Param1": $build_job_name,
    "Param2": $build_pipeline_name
  }'
