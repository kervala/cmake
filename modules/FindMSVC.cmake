# - Find MS Visual C++
#
#  VC_INCLUDE_DIR  - where to find headers
#  VC_INCLUDE_DIRS - where to find headers
#  VC_LIBRARY_DIR  - where to find libraries
#  VC_FOUND        - True if MSVC found.

IF(NOT VC_DIR)
  SET(VC_DIR $ENV{VC_DIR})
ENDIF(NOT VC_DIR)

IF(MSVC11)
  IF(NOT MSVC11_REDIST_DIR)
    # If you have VC++ 2012 Express, put x64/Microsoft.VC110.CRT/*.dll in ${EXTERNAL_PATH}/redist
    SET(MSVC11_REDIST_DIR "${EXTERNAL_PATH}/redist")
  ENDIF(NOT MSVC11_REDIST_DIR)

  IF(NOT VC_DIR)
    IF(NOT VC_ROOT_DIR)
      GET_FILENAME_COMPONENT(VC_ROOT_DIR "[HKEY_CURRENT_USER\\Software\\Microsoft\\VisualStudio\\11.0_Config;InstallDir]" ABSOLUTE)
      # VC_ROOT_DIR is set to "registry" when a key is not found
      IF(VC_ROOT_DIR STREQUAL "/registry")
        GET_FILENAME_COMPONENT(VC_ROOT_DIR "[HKEY_CURRENT_USER\\Software\\Microsoft\\WDExpress\\11.0_Config\\Setup\\VC;InstallDir]" ABSOLUTE)
        IF(VC_ROOT_DIR STREQUAL "/registry")
          SET(VS110COMNTOOLS $ENV{VS110COMNTOOLS})
          IF(VS110COMNTOOLS)
            FILE(TO_CMAKE_PATH ${VS110COMNTOOLS} VC_ROOT_DIR)
          ENDIF(VS110COMNTOOLS)
          IF(NOT VC_ROOT_DIR)
            MESSAGE(FATAL_ERROR "Unable to find VC++ 2012 directory!")
          ENDIF(NOT VC_ROOT_DIR)
        ENDIF(VC_ROOT_DIR STREQUAL "/registry")
      ENDIF(VC_ROOT_DIR STREQUAL "/registry")
    ENDIF(NOT VC_ROOT_DIR)
    # convert IDE fullpath to VC++ path
    STRING(REGEX REPLACE "Common7/.*" "VC" VC_DIR ${VC_ROOT_DIR})
  ENDIF(NOT VC_DIR)
ELSEIF(MSVC10)
  IF(NOT MSVC10_REDIST_DIR)
    # If you have VC++ 2010 Express, put x64/Microsoft.VC100.CRT/*.dll in ${EXTERNAL_PATH}/redist
    SET(MSVC10_REDIST_DIR "${EXTERNAL_PATH}/redist")
  ENDIF(NOT MSVC10_REDIST_DIR)

  IF(NOT VC_DIR)
    IF(NOT VC_ROOT_DIR)
      GET_FILENAME_COMPONENT(VC_ROOT_DIR "[HKEY_CURRENT_USER\\Software\\Microsoft\\VisualStudio\\10.0_Config;InstallDir]" ABSOLUTE)
      # VC_ROOT_DIR is set to "registry" when a key is not found
      IF(VC_ROOT_DIR MATCHES "registry")
        GET_FILENAME_COMPONENT(VC_ROOT_DIR "[HKEY_CURRENT_USER\\Software\\Microsoft\\VCExpress\\10.0_Config;InstallDir]" ABSOLUTE)
        IF(VC_ROOT_DIR MATCHES "registry")
          SET(VS100COMNTOOLS $ENV{VS100COMNTOOLS})
          IF(VS100COMNTOOLS)
            FILE(TO_CMAKE_PATH ${VS100COMNTOOLS} VC_ROOT_DIR)
          ENDIF(VS100COMNTOOLS)
          IF(NOT VC_ROOT_DIR)
            MESSAGE(FATAL_ERROR "Unable to find VC++ 2010 directory!")
          ENDIF(NOT VC_ROOT_DIR)
        ENDIF(VC_ROOT_DIR MATCHES "registry")
      ENDIF(VC_ROOT_DIR MATCHES "registry")
    ENDIF(NOT VC_ROOT_DIR)
    # convert IDE fullpath to VC++ path
    STRING(REGEX REPLACE "Common7/.*" "VC" VC_DIR ${VC_ROOT_DIR})
  ENDIF(NOT VC_DIR)
ELSE(MSVC11)
  IF(NOT VC_DIR)
    IF(CMAKE_MAKE_PROGRAM MATCHES "Common7")
      # convert IDE fullpath to VC++ path
      STRING(REGEX REPLACE "Common7/.*" "VC" VC_DIR ${CMAKE_MAKE_PROGRAM})
    ELSE(CMAKE_MAKE_PROGRAM MATCHES "Common7")
      # convert compiler fullpath to VC++ path
      STRING(REGEX REPLACE "VC/bin/.+" "VC" VC_DIR ${CMAKE_CXX_COMPILER})
    ENDIF(CMAKE_MAKE_PROGRAM MATCHES "Common7")
  ENDIF(NOT VC_DIR)
ENDIF(MSVC11)

MACRO(DETECT_VC_VERSION_HELPER _ROOT _STR _VERSION)
  # Software/Wow6432Node/...
  GET_FILENAME_COMPONENT(VC${_STR}_DIR "[${_ROOT}\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;${_VERSION}]" ABSOLUTE)

  IF(VC${_STR}_DIR AND NOT VC${_STR}_DIR STREQUAL "/registry")
    SET(VC${_STR}_FOUND ON)
    IF(NOT MSVC_FIND_QUIETLY)
      MESSAGE(STATUS "Found Visual C++ ${_VERSION} in ${VC${_STR}_DIR}")
    ENDIF(NOT MSVC_FIND_QUIETLY)
  ELSEIF(VC${_STR}_DIR AND NOT VC${_STR}_DIR STREQUAL "/registry")
    SET(VC${_STR}_DIR "")
  ENDIF(VC${_STR}_DIR AND NOT VC${_STR}_DIR STREQUAL "/registry")
ENDMACRO(DETECT_VC_VERSION_HELPER)

MACRO(DETECT_VC_VERSION _STR _VERSION)
  DETECT_VC_VERSION_HELPER("HKEY_CURRENT_USER" ${_STR} ${_VERSION})

  IF(NOT VC${_STR}_FOUND)
    DETECT_VC_VERSION_HELPER("HKEY_LOCAL_MACHINE" ${_STR} ${_VERSION})
  ENDIF(NOT VC${_STR}_FOUND)
ENDMACRO(DETECT_VC_VERSION)

# VS100COMNTOOLS
DETECT_VC_VERSION("11" "11.0")
DETECT_VC_VERSION("10" "10.0")

SET(VC_INCLUDE_DIR "${VC_DIR}/include")
INCLUDE_DIRECTORIES(${VC_INCLUDE_DIR})
