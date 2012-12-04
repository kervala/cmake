IF(DEFINED CMAKE_CROSSCOMPILING)
  # subsequent toolchain loading is not really needed
  RETURN()
ENDIF()

# Standard settings
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_VERSION 1) # TODO: determine target Linux version
SET(UNIX ON)
SET(LINUX ON)
SET(ANDROID ON)

IF(NOT NDK_ROOT)
  SET(NDK_ROOT $ENV{NDK_ROOT})

  IF(CMAKE_HOST_WIN32)
    FILE(TO_CMAKE_PATH ${NDK_ROOT} NDK_ROOT)
  ENDIF(CMAKE_HOST_WIN32)
ENDIF(NOT NDK_ROOT)

IF(NOT TARGET_CPU)
  SET(TARGET_CPU "armv7")
ENDIF(NOT TARGET_CPU)

IF(TARGET_CPU STREQUAL "armv7")
  SET(LIBRARY_ARCHITECTURE "armeabi-v7a")
  SET(CMAKE_SYSTEM_PROCESSOR "armv7")
  SET(TOOLCHAIN_ARCH "arm")
  SET(TOOLCHAIN_PREFIX "arm-linux-androideabi")
  SET(TOOLCHAIN_BIN_PREFIX "arm")
  SET(MINIMUM_NDK_TARGET 4)
ELSEIF(TARGET_CPU STREQUAL "armv5")
  SET(LIBRARY_ARCHITECTURE "armeabi")
  SET(CMAKE_SYSTEM_PROCESSOR "armv5")
  SET(TOOLCHAIN_ARCH "arm")
  SET(TOOLCHAIN_PREFIX "arm-linux-androideabi")
  SET(TOOLCHAIN_BIN_PREFIX "arm")
  SET(MINIMUM_NDK_TARGET 4)
ELSEIF(TARGET_CPU STREQUAL "x86")
  SET(LIBRARY_ARCHITECTURE "x86")
  SET(CMAKE_SYSTEM_PROCESSOR "x86")
  SET(TOOLCHAIN_ARCH "x86")
  SET(TOOLCHAIN_PREFIX "x86")
  SET(TOOLCHAIN_BIN_PREFIX "i686")
  SET(MINIMUM_NDK_TARGET 9)
ELSEIF(TARGET_CPU STREQUAL "mips")
  SET(LIBRARY_ARCHITECTURE "mips")
  SET(CMAKE_SYSTEM_PROCESSOR "mips")
  SET(TOOLCHAIN_ARCH "mips")
  SET(TOOLCHAIN_PREFIX "mipsel-linux-android")
  SET(TOOLCHAIN_BIN_PREFIX "mipsel")
  SET(MINIMUM_NDK_TARGET 9)
ENDIF(TARGET_CPU STREQUAL "armv7")

IF(NOT NDK_TARGET)
  SET(NDK_TARGET ${MINIMUM_NDK_TARGET})
ENDIF(NOT NDK_TARGET)

FILE(GLOB _TOOLCHAIN_VERSIONS "${NDK_ROOT}/toolchains/${TOOLCHAIN_PREFIX}-*")
IF(_TOOLCHAIN_VERSIONS)
  LIST(SORT _TOOLCHAIN_VERSIONS)
  LIST(REVERSE _TOOLCHAIN_VERSIONS)
  FOREACH(_TOOLCHAIN_VERSION ${_TOOLCHAIN_VERSIONS})
    STRING(REGEX REPLACE ".+${TOOLCHAIN_PREFIX}-([0-9.]+)" "\\1" _TOOLCHAIN_VERSION "${_TOOLCHAIN_VERSION}")
    IF(_TOOLCHAIN_VERSION MATCHES "^([0-9.]+)$")
      LIST(APPEND NDK_TOOLCHAIN_VERSIONS ${_TOOLCHAIN_VERSION})
    ENDIF(_TOOLCHAIN_VERSION MATCHES "^([0-9.]+)$")
  ENDFOREACH(_TOOLCHAIN_VERSION)
ENDIF(_TOOLCHAIN_VERSIONS)

IF(NOT NDK_TOOLCHAIN_VERSIONS)
  MESSAGE(FATAL_ERROR "No Android toolchain found in default search path ${NDK_ROOT}/toolchains")
ENDIF(NOT NDK_TOOLCHAIN_VERSIONS)

IF(NDK_TOOLCHAIN_VERSION)
  LIST(FIND NDK_TOOLCHAIN_VERSIONS "${NDK_TOOLCHAIN_VERSION}" _INDEX)
  IF(_INDEX EQUAL -1)
    LIST(GET NDK_TOOLCHAIN_VERSIONS 0 NDK_TOOLCHAIN_VERSION)
  ENDIF(_INDEX EQUAL -1)
ELSE(NDK_TOOLCHAIN_VERSION)
  LIST(GET NDK_TOOLCHAIN_VERSIONS 0 NDK_TOOLCHAIN_VERSION)
ENDIF(NDK_TOOLCHAIN_VERSION)

MESSAGE(STATUS "Target Android NDK ${NDK_TARGET} and use GCC ${NDK_TOOLCHAIN_VERSION}")

IF(CMAKE_HOST_WIN32)
  SET(TOOLCHAIN_HOST "windows")
  SET(TOOLCHAIN_BIN_SUFFIX ".exe")
ELSEIF(CMAKE_HOST_APPLE)
  SET(TOOLCHAIN_HOST "apple")
  SET(TOOLCHAIN_BIN_SUFFIX "")
ELSEIF(CMAKE_HOST_UNIX)
  SET(TOOLCHAIN_HOST "linux-x86")
  SET(TOOLCHAIN_BIN_SUFFIX "")
ENDIF(CMAKE_HOST_WIN32)

SET(TOOLCHAIN_ROOT "${NDK_ROOT}/toolchains/${TOOLCHAIN_PREFIX}-${NDK_TOOLCHAIN_VERSION}/prebuilt/${TOOLCHAIN_HOST}")
SET(PLATFORM_ROOT "${NDK_ROOT}/platforms/android-${NDK_TARGET}/arch-${TOOLCHAIN_ARCH}")

MESSAGE(STATUS "Found Android toolchain in ${TOOLCHAIN_ROOT}")
MESSAGE(STATUS "Found Android platform in ${PLATFORM_ROOT}")

# include dirs
SET(PLATFORM_INCLUDE_DIR "${PLATFORM_ROOT}/usr/include")
SET(STL_DIR "${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++")

IF(EXISTS "${STL_DIR}/${NDK_TOOLCHAIN_VERSION}")
  # NDK version >= 8b
  SET(STL_DIR "${STL_DIR}/${NDK_TOOLCHAIN_VERSION}")
ENDIF(EXISTS "${STL_DIR}/${NDK_TOOLCHAIN_VERSION}")

# Determine bin prefix for toolchain
FILE(GLOB _TOOLCHAIN_BIN_PREFIXES "${TOOLCHAIN_ROOT}/bin/${TOOLCHAIN_BIN_PREFIX}-*-gcc${TOOLCHAIN_BIN_SUFFIX}")
IF(_TOOLCHAIN_BIN_PREFIXES)
  LIST(GET _TOOLCHAIN_BIN_PREFIXES 0 _TOOLCHAIN_BIN_PREFIX)
  STRING(REGEX REPLACE "${TOOLCHAIN_ROOT}/bin/([a-z0-9-]+)-gcc${TOOLCHAIN_BIN_SUFFIX}" "\\1" TOOLCHAIN_BIN_PREFIX "${_TOOLCHAIN_BIN_PREFIX}")
ENDIF(_TOOLCHAIN_BIN_PREFIXES)

SET(STL_INCLUDE_DIR "${STL_DIR}/include")
SET(STL_LIBRARY_DIR "${STL_DIR}/libs/${LIBRARY_ARCHITECTURE}")
SET(STL_INCLUDE_CPU_DIR "${STL_LIBRARY_DIR}/include")
SET(STL_LIBRARY "${STL_LIBRARY_DIR}/libgnustl_static.a")

SET(CMAKE_FIND_ROOT_PATH ${TOOLCHAIN_ROOT} ${PLATFORM_ROOT}/usr ${CMAKE_PREFIX_PATH} ${CMAKE_INSTALL_PREFIX} $ENV{EXTERNAL_ANDROID_PATH} CACHE string  "Android find search path root")

SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

INCLUDE_DIRECTORIES(${STL_INCLUDE_DIR} ${STL_INCLUDE_CPU_DIR})

MACRO(SET_TOOLCHAIN_BINARY _NAME _BINARY)
  SET(${_NAME} ${TOOLCHAIN_ROOT}/bin/${TOOLCHAIN_BIN_PREFIX}-${_BINARY}${TOOLCHAIN_BIN_SUFFIX})
ENDMACRO(SET_TOOLCHAIN_BINARY)

SET_TOOLCHAIN_BINARY(CMAKE_C_COMPILER gcc)
SET_TOOLCHAIN_BINARY(CMAKE_CXX_COMPILER g++)

# Force the compilers to GCC for Android
include (CMakeForceCompiler)
CMAKE_FORCE_C_COMPILER(${CMAKE_C_COMPILER} GNU)
CMAKE_FORCE_CXX_COMPILER(${CMAKE_CXX_COMPILER} GNU)
