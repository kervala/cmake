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

CMAKE_MINIMUM_REQUIRED(VERSION 2.6.3)

# ROOT_DIR should be set to root of the repository (where to find the .svn or .hg directory)
# SOURCE_DIR should be set to root of your code (where to find CMakeLists.txt)
# BINARY_DIR should be set to root of your build directory

SET(SOURCE_DIR ${CMAKE_SOURCE_DIR})
SET(ROOT_DIR ${CMAKE_SOURCE_DIR})
SET(BINARY_DIR ${CMAKE_BINARY_DIR})

MACRO(NOW RESULT)
  IF(CMAKE_VERSION VERSION_GREATER "2.8.10")
    STRING(TIMESTAMP ${RESULT} "%Y-%m-%d %H:%M:%S")
  ELSE()
    IF(WIN32)
      EXECUTE_PROCESS(COMMAND "wmic" "os" "get" "localdatetime" OUTPUT_VARIABLE DATETIME)
      IF(NOT DATETIME MATCHES "ERROR")
        STRING(REGEX REPLACE ".*\n([0-9][0-9][0-9][0-9])([0-9][0-9])([0-9][0-9])([0-9][0-9])([0-9][0-9])([0-9][0-9]).*" "\\1-\\2-\\3 \\4:\\5:\\6" ${RESULT} "${DATETIME}")
      ENDIF()
    ELSEIF(UNIX)
      EXECUTE_PROCESS(COMMAND "date" "+%Y-%m-%d %H:%M:%S" OUTPUT_VARIABLE DATETIME)
      STRING(REGEX REPLACE "([0-9: -]+).*" "\\1" ${RESULT} "${DATETIME}")
    ELSE()
      MESSAGE(SEND_ERROR "date not implemented")
      SET(${RESULT} "0000-00-00 00:00:00")
    ENDIF()
  ENDIF()
ENDMACRO()

IF(EXISTS "${ROOT_DIR}/.svn/")
  FIND_PACKAGE(Subversion QUIET)

  IF(SUBVERSION_FOUND)
    Subversion_WC_INFO(${ROOT_DIR} ER)
    SET(REVISION ${ER_WC_REVISION})
  ENDIF()

  FIND_PACKAGE(TortoiseSVN QUIET)

  IF(TORTOISESVN_FOUND)
    TORTOISESVN_GET_REVISION(${ROOT_DIR} REVISION)
  ENDIF()
ENDIF()

IF(EXISTS "${ROOT_DIR}/.hg/")
  FIND_PACKAGE(Mercurial)

  IF(MERCURIAL_FOUND)
    Mercurial_WC_INFO(${ROOT_DIR} ER)
    SET(REVISION ${ER_WC_REVISION})
    SET(CHANGESET ${ER_WC_CHANGESET})
    SET(BRANCH ${ER_WC_BRANCH})
  ENDIF()
ENDIF()

# if processing exported sources, use "revision" file if exists
IF(SOURCE_DIR AND NOT DEFINED REVISION)
  SET(REVISION_FILE ${SOURCE_DIR}/revision)
  IF(EXISTS ${REVISION_FILE})
    FILE(STRINGS ${REVISION_FILE} REVISION LIMIT_COUNT 1)
    MESSAGE(STATUS "Read revision ${REVISION} from file")
  ENDIF()
ENDIF()

IF(DEFINED REVISION)
  MESSAGE(STATUS "Found revision ${REVISION}")
ENDIF()
