# - Find Windows Platform SDK
# Find the Windows includes
#
#  WINSDK_INCLUDE_DIR - where to find Windows.h
#  WINSDK_LIB_DIR     - where to find ComCtl32.lib
#  WINSDK_FOUND       - True if Windows SDK found.

#HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v8.0

GET_FILENAME_COMPONENT(WINSDK8_DIR  "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v8.0;InstallationFolder]" ABSOLUTE CACHE)
GET_FILENAME_COMPONENT(WINSDK8_VERSION "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v8.0;ProductVersion]" NAME)

IF(WINSDK8_DIR)
  IF(NOT WindowsSDK_FIND_QUIETLY)
    MESSAGE(STATUS "Found Windows SDK ${WINSDK8_VERSION} in ${WINSDK8_DIR}")
  ENDIF(NOT WindowsSDK_FIND_QUIETLY)
ENDIF(WINSDK8_DIR)

GET_FILENAME_COMPONENT(WINSDK71_DIR  "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v7.1;InstallationFolder]" ABSOLUTE CACHE)
GET_FILENAME_COMPONENT(WINSDK71_VERSION "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows\\v7.1;ProductVersion]" NAME)

IF(WINSDK71_DIR)
  IF(NOT WindowsSDK_FIND_QUIETLY)
    MESSAGE(STATUS "Found Windows SDK ${WINSDK71_VERSION} in ${WINSDK71_DIR}")
  ENDIF(NOT WindowsSDK_FIND_QUIETLY)
ENDIF(WINSDK71_DIR)

GET_FILENAME_COMPONENT(WINSDKCURRENT_DIR  "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows;CurrentInstallFolder]" ABSOLUTE CACHE)
GET_FILENAME_COMPONENT(WINSDKCURRENT_VERSION "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows;CurrentVersion]" NAME)

IF(WINSDKCURRENT_DIR)
  IF(NOT WindowsSDK_FIND_QUIETLY)
    MESSAGE(STATUS "Found Windows SDK ${WINSDKCURRENT_VERSION} in ${WINSDKCURRENT_DIR}")
  ENDIF(NOT WindowsSDK_FIND_QUIETLY)
ENDIF(WINSDKCURRENT_DIR)

FIND_PATH(WINSDK_INCLUDE_DIR Windows.h
  HINTS
  ${WINSDK71_DIR}/Include
  ${WINSDKCURRENT_DIR}/Include
)

FIND_PATH(WINSDK_LIB_DIR ComCtl32.lib
  HINTS
  ${WINSDK71_DIR}/Lib
  ${WINSDKCURRENT_DIR}/Lib
)

FIND_PROGRAM(WINSDK_SIGNTOOL signtool
  HINTS
  ${WINSDK71_DIR}/Bin
  ${WINSDKCURRENT_DIR}/Bin
)

IF(WINSDK_INCLUDE_DIR)
  SET(WINSDK_FOUND TRUE)
ELSE(WINSDK_INCLUDE_DIR)
  IF(NOT WindowsSDK_FIND_QUIETLY)
    MESSAGE(STATUS "Warning: Unable to find Windows SDK!")
  ENDIF(NOT WindowsSDK_FIND_QUIETLY)
ENDIF(WINSDK_INCLUDE_DIR)
