#!/bin/bash
set -eux

echo $AWS_ACCESS_KEY
echo $AWS_SECRET_KEY
echo $AWS_REGION

if [ ! -d /opt/resource ]; then
  sudo mkdir -p /opt/resource
  sudo chown $(whoami) /opt/resource
  if [ ! -f /opt/resource/common.sh ]; then
    cat << EOF > /opt/resource/common.sh
      function start_docker() {
        docker --version
      }
EOF
  fi
fi

TMP_DIR=$(mktemp -d -t cloudformation-resource-integration-test)
TMP_DIR=$(echo $TMP_DIR | sed -E "s/\/var\//\/private\/var\//")

cp -R .. $TMP_DIR/task-repo
cp integration-test.sh $TMP_DIR

cd $TMP_DIR

./integration-test.sh
