#!/bin/bash

EXTERNAL_ROOT=$(pwd)
BUILDDIR=build

#-DCMAKE_PREFIX_PATH=$EXTERNAL

function cmake_compile
{
  NAME=$1
  cmake_hg $NAME &&

  echo "Compiling $NAME..."

  if [ -e CMakeLists.txt ]
  then
    cmake_configure $2 $3 $4 $5 $6
  fi

  if [ -e Makefile ]
  then
    make -j4 2> errors.txt && make install
  fi

  return $?
}

function cmake_hg
{
  NAME=$1
  mkdir -p $EXTERNAL_ROOT/$NAME
  cd $EXTERNAL_ROOT/$NAME

  if [ -d ".hg" ]
  then
    hg pull && hg update
  else
    hg clone https://code.neolinks.com/hg/$NAME
  fi

  return $?
}

function cmake_configure
{
  FLAGS="-DIOS_PLATFORM=ALL -DIOS_VERSION=4.3 -DCMAKE_INSTALL_PREFIX=$EXTERNAL_IOS_PATH $1 $2 $3 $4 $5"
  mkdir -p $EXTERNAL_ROOT/$NAME/$BUILDDIR
  cd $EXTERNAL_ROOT/$NAME/$BUILDDIR
  if [ ! -e "CMakeCache.txt" ]
  then
    FLAGS="-DCMAKE_TOOLCHAIN_FILE=$CMAKE_MODULE_PATH/iOSToolChain.cmake $FLAGS"
  fi
  cmake $FLAGS ..
  return $?
}

cmake_compile cmake_modules &&

cmake_compile boost &&
cmake_compile openssl &&
cmake_compile xvid &&
cmake_compile speex &&
cmake_compile speex++ &&
cmake_compile crypto &&

cmake_compile neolib &&
cmake_compile gclib &&
cmake_compile wbclient &&
cmake_compile mcu &&

cmake_compile visioxpert_ios -G Xcode &&
cmake_compile mobile_ios -G Xcode

cd $EXTERNAL_ROOT

echo "Done."
