#!/bin/bash

BUILDDIR=build
EXTERNAL_ROOT=$(pwd)

function clean
{
  NAME=$1
  echo "Cleaning $NAME..."
  DIR=$EXTERNAL_ROOT/$NAME/$BUILDDIR
  if [ -d $DIR ]
  then
    rm -rf $DIR
  fi
  return $?
}

clean boost &&
clean openssl &&
clean xvid &&
clean speex &&
clean speex++ &&
clean crypto &&

clean neolib &&
clean gclib &&
clean wbclient &&
clean mcu &&

clean visioxpert_ios &&
clean mobile_ios
