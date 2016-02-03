#!/bin/bash

set -eux

WORKING_DIR=$PWD

cd bosh-src
source ci/tasks/utils.sh
check_param OPERATING_SYSTEM_NAME
check_param OPERATING_SYSTEM_VERSION

OS_IMAGE_NAME=$OPERATING_SYSTEM_NAME-$OPERATING_SYSTEM_VERSION-os-image
OS_IMAGE=$WORKING_DIR/$OS_IMAGE_NAME.tgz

sudo chown -R ubuntu .

#cd $WORKING_DIR
#
#OS_IMAGE_NAME=$OPERATING_SYSTEM_NAME-$OPERATING_SYSTEM_VERSION-os-image
#mkdir -p $OS_IMAGE_NAME/
#mv /tmp/os-image.tgz $OS_IMAGE_NAME/
