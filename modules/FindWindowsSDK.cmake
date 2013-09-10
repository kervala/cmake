# - Find Windows Platform SDK
# Find the Windows includes
#
#  WINSDK_INCLUDE_DIR - where to find Windows.h
#  WINSDK_INCLUDE_DIRS - where to find all Windows headers
#  WINSDK_LIBRARY_DIR - where to find libraries
#  WINSDK_FOUND       - True if Windows SDK found.

IF(WINSDK_FOUND)
  # If Windows SDK already found, skip it
  RETURN()
ENDIF(WINSDK_FOUND)

# Values can be CURRENT or any existing versions 7.1, 8.0A, etc...
SET(WINSDK_VERSION "CURRENT" CACHE STRING "Windows SDK version to prefer")

MACRO(DETECT_WINSDK_VERSION_HELPER _ROOT _VERSION)
  GET_FILENAME_COMPONENT(WINSDK${_VERSION}_DIR "[${_ROOT}\\SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v${_VERSION};InstallationFolder]" ABSOLUTE)

  IF(WINSDK${_VERSION}_DIR AND NOT WINSDK${_VERSION}_DIR STREQUAL "/registry")
    SET(WINSDK${_VERSION}_FOUND ON)
    GET_FILENAME_COMPONENT(WINSDK${_VERSION}_VERSION_FULL "[${_ROOT}\\SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v${_VERSION};ProductVersion]" NAME)
    IF(NOT WindowsSDK_FIND_QUIETLY)
      MESSAGE(STATUS "Found Windows SDK ${_VERSION} in ${WINSDK${_VERSION}_DIR}")
    ENDIF(NOT WindowsSDK_FIND_QUIETLY)
  ELSE(WINSDK${_VERSION}_DIR AND NOT WINSDK${_VERSION}_DIR STREQUAL "/registry")
    SET(WINSDK${_VERSION}_DIR "")
  ENDIF(WINSDK${_VERSION}_DIR AND NOT WINSDK${_VERSION}_DIR STREQUAL "/registry")
ENDMACRO(DETECT_WINSDK_VERSION_HELPER)

MACRO(DETECT_WINSDK_VERSION _VERSION)
  SET(WINSDK${_VERSION}_FOUND OFF)
  DETECT_WINSDK_VERSION_HELPER("HKEY_CURRENT_USER" ${_VERSION})

  IF(NOT WINSDK${_VERSION}_FOUND)
    DETECT_WINSDK_VERSION_HELPER("HKEY_LOCAL_MACHINE" ${_VERSION})
  ENDIF(NOT WINSDK${_VERSION}_FOUND)
ENDMACRO(DETECT_WINSDK_VERSION)

SET(WINSDK_VERSIONS "8.0" "8.0A" "7.1" "7.0A" "6.1" "6.0" "6.0A")
SET(WINSDK_DETECTED_VERSIONS)

# Search all supported Windows SDKs
FOREACH(_VERSION ${WINSDK_VERSIONS})
  DETECT_WINSDK_VERSION(${_VERSION})

  IF(WINSDK${_VERSION}_FOUND)
    LIST(APPEND WINSDK_DETECTED_VERSIONS ${_VERSION})
  ENDIF(WINSDK${_VERSION}_FOUND)
ENDFOREACH(_VERSION)

SET(WINSDK_SUFFIX)

IF(TARGET_ARM)
  SET(WINSDK8_SUFFIX "arm")
ELSEIF(TARGET_X64)
  SET(WINSDK8_SUFFIX "x64")
  SET(WINSDK_SUFFIX "x64")
ELSEIF(TARGET_X86)
  SET(WINSDK8_SUFFIX "x86")
ENDIF(TARGET_ARM)

GET_FILENAME_COMPONENT(WINSDKCURRENT_VERSION_REGISTRY "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows;CurrentVersion]" NAME)

IF(WINSDKCURRENT_VERSION_REGISTRY AND NOT WINSDKCURRENT_VERSION_REGISTRY STREQUAL "/registry")
  IF(NOT WindowsSDK_FIND_QUIETLY)
#    MESSAGE(STATUS "Current version is ${WINSDKCURRENT_VERSION_REGISTRY}")
  ENDIF(NOT WindowsSDK_FIND_QUIETLY)
ENDIF(WINSDKCURRENT_VERSION_REGISTRY AND NOT WINSDKCURRENT_VERSION_REGISTRY STREQUAL "/registry")

SET(WINSDKCURRENT_VERSION_INCLUDE $ENV{INCLUDE})

IF(WINSDKCURRENT_VERSION_INCLUDE)
  STRING(REPLACE "\\" "/" WINSDKCURRENT_VERSION_INCLUDE ${WINSDKCURRENT_VERSION_INCLUDE})
ENDIF(WINSDKCURRENT_VERSION_INCLUDE)

SET(WINSDKENV_DIR $ENV{WINSDK_DIR})

MACRO(USE_CURRENT_WINSDK)
  SET(WINSDK_VERSION "")
  SET(WINSDK_VERSION_FULL "")

  IF(WINSDKENV_DIR)
    # Use WINSDK environment variable
    SET(WINSDK_DIR ${WINSDKENV_DIR})
    FOREACH(_VERSION ${WINSDK_DETECTED_VERSIONS})
      IF(WINSDK_DIR STREQUAL WINSDK${_VERSION}_DIR)
        SET(WINSDK_VERSION ${_VERSION})
        BREAK()
      ENDIF(WINSDK_DIR STREQUAL WINSDK${_VERSION}_DIR)
    ENDFOREACH(_VERSION)
  ENDIF(WINSDKENV_DIR)

  IF(NOT WINSDK_VERSION AND WINSDKCURRENT_VERSION_INCLUDE)
    # Use INCLUDE environment variable
    FOREACH(_VERSION ${WINSDK_DETECTED_VERSIONS})
      MESSAGE(STATUS "Check ${WINSDK${_VERSION}_DIR}")
      IF(WINSDKCURRENT_VERSION_INCLUDE MATCHES "${WINSDK${_VERSION}_DIR}")
        SET(WINSDK_VERSION ${_VERSION})
        BREAK()
      ENDIF(WINSDKCURRENT_VERSION_INCLUDE MATCHES "${WINSDK${_VERSION}_DIR}")
    ENDFOREACH(_VERSION)
  ENDIF(NOT WINSDK_VERSION AND WINSDKCURRENT_VERSION_INCLUDE)

  IF(NOT WINSDK_VERSION AND WINSDKCURRENT_VERSION_REGISTRY STREQUAL WINSDK7.0A_VERSION_FULL)
    # Windows SDK 7.0A doesn't provide 64bits compilers, use SDK 7.1 for 64 bits
    IF(TARGET_X64)
      SET(WINSDK_VERSION "7.1")
    ELSE(TARGET_X64)
      SET(WINSDK_VERSION "7.0A")
    ENDIF(TARGET_X64)
  ENDIF(NOT WINSDK_VERSION AND WINSDKCURRENT_VERSION_REGISTRY STREQUAL WINSDK7.0A_VERSION_FULL)

  IF(NOT WINSDK_VERSION AND WINSDKCURRENT_VERSION_REGISTRY)
    FOREACH(_VERSION ${WINSDK_DETECTED_VERSIONS})
      IF(WINSDKCURRENT_VERSION_REGISTRY STREQUAL WINSDK${_VERSION}_VERSION_FULL)
        SET(WINSDK_VERSION ${_VERSION})
        BREAK()
      ENDIF(WINSDKCURRENT_VERSION_REGISTRY STREQUAL WINSDK${_VERSION}_VERSION_FULL)
    ENDFOREACH(_VERSION)
  ENDIF(NOT WINSDK_VERSION AND WINSDKCURRENT_VERSION_REGISTRY)

  IF(WINSDK_VERSION AND NOT WINSDK_DIR)
    SET(WINSDK_VERSION_FULL "${WINSDK${WINSDK_VERSION}_VERSION_FULL}")
    SET(WINSDK_DIR "${WINSDK${WINSDK_VERSION}_DIR}")
  ENDIF(WINSDK_VERSION AND NOT WINSDK_DIR)
ENDMACRO(USE_CURRENT_WINSDK)

IF(WINSDK_VERSION STREQUAL "CURRENT")
  USE_CURRENT_WINSDK()
ELSE(WINSDK_VERSION STREQUAL "CURRENT")
  IF(WINSDK${WINSDK_VERSION}_FOUND)
    SET(WINSDK_VERSION_FULL "${WINSDK${WINSDK_VERSION}_VERSION_FULL}")
    SET(WINSDK_DIR "${WINSDK${WINSDK_VERSION}_DIR}")
  ELSE(WINSDK${WINSDK_VERSION}_FOUND)
    USE_CURRENT_WINSDK()
  ENDIF(WINSDK${WINSDK_VERSION}_FOUND)
ENDIF(WINSDK_VERSION STREQUAL "CURRENT")

IF(WINSDK_DIR)
  MESSAGE(STATUS "Using Windows SDK ${WINSDK_VERSION}")
ELSE(WINSDK_DIR)
  MESSAGE(FATAL_ERROR "Unable to find Windows SDK!")
ENDIF(WINSDK_DIR)

# directory where Win32 headers are found
FIND_PATH(WINSDK_INCLUDE_DIR Windows.h
  HINTS
  ${WINSDK_DIR}/Include/um
  ${WINSDK_DIR}/Include
)

# directory where DirectX headers are found
FIND_PATH(WINSDK_SHARED_INCLUDE_DIR d3d9.h
  HINTS
  ${WINSDK_DIR}/Include/shared
  ${WINSDK_DIR}/Include
)

# directory where all libraries are found
FIND_PATH(WINSDK_LIBRARY_DIR ComCtl32.lib
  HINTS
  ${WINSDK_DIR}/Lib/win8/um/${WINSDK8_SUFFIX}
  ${WINSDK_DIR}/Lib/${WINSDK_SUFFIX}
)

# signtool is used to sign executables
FIND_PROGRAM(WINSDK_SIGNTOOL signtool
  HINTS
  ${WINSDK_DIR}/Bin/x86
  ${WINSDK_DIR}/Bin
)

# midl is used to generate IDL interfaces
FIND_PROGRAM(WINSDK_MIDL midl
  HINTS
  ${WINSDK_DIR}/Bin/x86
  ${WINSDK_DIR}/Bin
)

IF(WINSDK_INCLUDE_DIR)
  SET(WINSDK_FOUND ON)
  SET(WINSDK_INCLUDE_DIRS ${WINSDK_INCLUDE_DIR} ${WINSDK_SHARED_INCLUDE_DIR})
  SET(CMAKE_LIBRARY_PATH ${WINSDK_LIBRARY_DIR} ${CMAKE_LIBRARY_PATH})
  INCLUDE_DIRECTORIES(${WINSDK_INCLUDE_DIRS})

  # Fix for using Windows SDK 7.1 with Visual C++ 2012
  IF(WINSDK_VERSION STREQUAL "7.1" AND MSVC11)
    ADD_DEFINITIONS(-D_USING_V110_SDK71_)
  ENDIF(WINSDK_VERSION STREQUAL "7.1" AND MSVC11)
ELSE(WINSDK_INCLUDE_DIR)
  IF(NOT WindowsSDK_FIND_QUIETLY)
    MESSAGE(STATUS "Warning: Unable to find Windows SDK!")
  ENDIF(NOT WindowsSDK_FIND_QUIETLY)
ENDIF(WINSDK_INCLUDE_DIR)
