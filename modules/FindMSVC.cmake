#
#  CMake custom modules
#  Copyright (C) 2011-2015  Cedric OCHS
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# - Find MS Visual C++
#
#  VC_INCLUDE_DIR  - where to find headers
#  VC_INCLUDE_DIRS - where to find headers
#  VC_LIBRARY_DIR  - where to find libraries
#  VC_FOUND        - True if MSVC found.

MACRO(ADD_TRAILING_SLASH _FILENAME_VAR)
  # put content in a new variable
  SET(_FILENAME ${${_FILENAME_VAR}})
  # get length of the string
  STRING(LENGTH ${_FILENAME} _LEN)
  # convert length to last pos
  MATH(EXPR _POS "${_LEN}-1")
  # get last character of the string
  STRING(SUBSTRING ${_FILENAME} ${_POS} 1 _FILENAME_END)
  # compare it with a slash
  IF(NOT _FILENAME_END STREQUAL "/")
    # not a slash, append it
    SET(${_FILENAME_VAR} "${_FILENAME}/")
  ELSE()
    # already a slash
  ENDIF()
ENDMACRO()

MACRO(DETECT_VC_VERSION_HELPER _ROOT _VERSION)
  # Software/Wow6432Node/...
  GET_FILENAME_COMPONENT(VC${_VERSION}_DIR "[${_ROOT}\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VC7;${_VERSION}]" ABSOLUTE)

  IF(VC${_VERSION}_DIR AND VC${_VERSION}_DIR STREQUAL "/registry")
    SET(VC${_VERSION}_DIR)
    GET_FILENAME_COMPONENT(VC${_VERSION}_DIR "[${_ROOT}\\SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7;${_VERSION}]" ABSOLUTE)

    IF(VC${_VERSION}_DIR AND NOT VC${_VERSION}_DIR STREQUAL "/registry")
      # be sure it's finishing by a /
      ADD_TRAILING_SLASH(VC${_VERSION}_DIR)

      SET(VC${_VERSION}_DIR "${VC${_VERSION}_DIR}VC/")
    ENDIF()
  ENDIF()

  IF(VC${_VERSION}_DIR AND NOT VC${_VERSION}_DIR STREQUAL "/registry")
    SET(VC${_VERSION}_FOUND ON)
    DETECT_EXPRESS_VERSION(${_VERSION})
    IF(NOT MSVC_FIND_QUIETLY)
      SET(_VERSION_STR ${_VERSION})
      IF(MSVC_EXPRESS)
        SET(_VERSION_STR "${_VERSION_STR} Express")
      ENDIF()
      MESSAGE(STATUS "Found Visual C++ ${_VERSION_STR} in ${VC${_VERSION}_DIR}")
    ENDIF()
  ELSEIF(VC${_VERSION}_DIR AND NOT VC${_VERSION}_DIR STREQUAL "/registry")
    SET(VC${_VERSION}_FOUND OFF)
    SET(VC${_VERSION}_DIR "")
  ENDIF()
ENDMACRO()

MACRO(DETECT_VC_VERSION _VERSION)
  IF(NOT VC_FOUND)
    SET(VC${_VERSION}_FOUND OFF)
    DETECT_VC_VERSION_HELPER("HKEY_CURRENT_USER" ${_VERSION})

    IF(NOT VC${_VERSION}_FOUND)
      DETECT_VC_VERSION_HELPER("HKEY_LOCAL_MACHINE" ${_VERSION})
    ENDIF()

    IF(VC${_VERSION}_FOUND)
      SET(VC_FOUND ON)
      SET(VC_DIR "${VC${_VERSION}_DIR}")
    ENDIF()
  ENDIF()
ENDMACRO()

MACRO(DETECT_EXPRESS_VERSION _VERSION)
  GET_FILENAME_COMPONENT(MSVC_EXPRESS "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\VCExpress\\${_VERSION}\\Setup\\VC;ProductDir]" ABSOLUTE)

  IF(MSVC_EXPRESS AND NOT MSVC_EXPRESS STREQUAL "/registry")
    SET(MSVC_EXPRESS ON)
  ENDIF()
ENDMACRO()

IF(MSVC_VERSION GREATER 1909)
  DETECT_VC_VERSION("15.0")
  SET(MSVC_TOOLSET "140")

  SET(VC_DIR "${VC_DIR}Tools/MSVC")

  FILE(GLOB MSVC_TOOLCHAIN_VERSIONS RELATIVE ${VC_DIR} "${VC_DIR}/*")

  IF(MSVC_TOOLCHAIN_VERSIONS)
    LIST(SORT MSVC_TOOLCHAIN_VERSIONS)
    LIST(REVERSE MSVC_TOOLCHAIN_VERSIONS)
  ENDIF()

  IF(NOT MSVC_TOOLCHAIN_VERSIONS)
    MESSAGE(FATAL_ERROR "No MSVC version found in default search path ${VC_DIR}")
  ENDIF()

  LIST(GET MSVC_TOOLCHAIN_VERSIONS 0 MSVC_TOOLCHAIN_VERSION)

  SET(VC_DIR "${VC_DIR}/${MSVC_TOOLCHAIN_VERSION}")
  SET(VC_INCLUDE_DIR "${VC_DIR}/include")
ELSEIF(MSVC14)
  DETECT_VC_VERSION("14.0")
  SET(MSVC_TOOLSET "140")
ELSEIF(MSVC12)
  DETECT_VC_VERSION("12.0")
  SET(MSVC_TOOLSET "120")
ELSEIF(MSVC11)
  DETECT_VC_VERSION("11.0")
  SET(MSVC_TOOLSET "110")
ELSEIF(MSVC10)
  DETECT_VC_VERSION("10.0")
  SET(MSVC_TOOLSET "100")
ELSEIF(MSVC90)
  DETECT_VC_VERSION("9.0")
  SET(MSVC_TOOLSET "90")
ELSEIF(MSVC80)
  DETECT_VC_VERSION("8.0")
  SET(MSVC_TOOLSET "80")
ENDIF()

# If you plan to use VC++ compilers with WINE, set VC_DIR environment variable
IF(NOT VC_DIR)
  SET(VC_DIR $ENV{VC_DIR})
  # Fix path
  FILE(TO_CMAKE_PATH ${VC_DIR} VC_DIR)
ENDIF()

IF(NOT VC_DIR)
  IF(CMAKE_CXX_COMPILER)
    SET(_COMPILER ${CMAKE_CXX_COMPILER})
  ELSE()
    SET(_COMPILER ${CMAKE_C_COMPILER})
  ENDIF()
  STRING(REGEX REPLACE "/(bin|BIN|Bin)/.+" "" VC_DIR ${_COMPILER})
ENDIF()

IF(NOT VC_INCLUDE_DIR AND VC_DIR AND EXISTS "${VC_DIR}")
  SET(VC_INCLUDE_DIR "${VC_DIR}/include")
  IF(EXISTS "${VC_INCLUDE_DIR}")
    SET(VC_FOUND ON)
  ENDIF()
ENDIF()

SET(MSVC_REDIST_DIR "${EXTERNAL_PATH}/redist")

IF(NOT EXISTS "${MSVC_REDIST_DIR}")
  SET(MSVC_REDIST_DIR "${VC_DIR}/redist")
  
  IF(NOT EXISTS "${MSVC_REDIST_DIR}")
    SET(MSVC_REDIST_DIR)
  ENDIF()
ENDIF()

IF(MSVC_REDIST_DIR)
  IF(MSVC1411 OR MSVC1410)
    # If you have VC++ 2017 Express, put x64/Microsoft.VC141.CRT/*.dll in ${EXTERNAL_PATH}/redist
    # original files whould be in ${VC_DIR}/Redist/MSVC/14.11.25325/x64/Microsoft.VC141.CRT
    SET(MSVC14_REDIST_DIR "${MSVC_REDIST_DIR}")
  ELSEIF(MSVC14)
    SET(MSVC14_REDIST_DIR "${MSVC_REDIST_DIR}")
  ELSEIF(MSVC12)
    # If you have VC++ 2013 Express, put x64/Microsoft.VC120.CRT/*.dll in ${EXTERNAL_PATH}/redist
    SET(MSVC12_REDIST_DIR "${MSVC_REDIST_DIR}")
  ELSEIF(MSVC11)
    # If you have VC++ 2012 Express, put x64/Microsoft.VC110.CRT/*.dll in ${EXTERNAL_PATH}/redist
    SET(MSVC11_REDIST_DIR "${MSVC_REDIST_DIR}")
  ELSEIF(MSVC10)
      # If you have VC++ 2010 Express, put x64/Microsoft.VC100.CRT/*.dll in ${EXTERNAL_PATH}/redist
    SET(MSVC10_REDIST_DIR "${MSVC_REDIST_DIR}")
  ELSEIF(MSVC90)
    SET(MSVC90_REDIST_DIR "${MSVC_REDIST_DIR}")
  ELSEIF(MSVC80)
    SET(MSVC80_REDIST_DIR "${MSVC_REDIST_DIR}")
  ENDIF()
ENDIF()

MESSAGE(STATUS "Using headers from ${VC_INCLUDE_DIR}")

SET(VC_INCLUDE_DIRS ${VC_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${VC_INCLUDE_DIR})
