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

SET(NSIS_ROOT_PATHS "$ENV{PROGRAMFILES}/NSIS" "$ENV{NSIS_DIR}")

FIND_PROGRAM(NSIS_EXECUTABLE
  NAMES
    makensis
  PATHS
    ${NSIS_ROOT_PATH}
    ${NSIS_ROOT_PATH}/Bin
    ${NSIS_ROOT_PATHS}
  DOC "makensis command line")

MARK_AS_ADVANCED(NSIS_EXECUTABLE)

IF(NSIS_EXECUTABLE)
  EXECUTE_PROCESS(COMMAND ${NSIS_EXECUTABLE} -version
    OUTPUT_VARIABLE NSIS_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  STRING(REGEX REPLACE ".*v([\\.0-9]+).*" "\\1" NSIS_VERSION "${NSIS_VERSION}")

  MESSAGE(STATUS "Found NSIS version ${NSIS_VERSION} in ${NSIS_EXECUTABLE}")

  SET(NSIS_FOUND ON)
ENDIF()

MACRO(ADD_NSIS_PACKAGE SCRIPT)
  SET(NSIS_OPTIONS "")
  FOREACH(arg ${ARGN})
    # Fix path for Windows
    STRING(REPLACE "/" "\\" arg ${arg})
    SET(NSIS_OPTIONS ${NSIS_OPTIONS} -D${arg})
  ENDFOREACH()

  SET(NSIS_COMMANDS ${NSIS_COMMANDS} COMMAND ${NSIS_EXECUTABLE} ${NSIS_OPTIONS} ${SCRIPT})
  SET(NSIS_SOURCES ${NSIS_SOURCES} "${SCRIPT}")
ENDMACRO()

MACRO(MAKE_NSIS_TARGET TARGET)
  # Set another variable because TARGET can't be changed
  SET(_TARGET ${TARGET})

  ADD_CUSTOM_TARGET(packages ${NSIS_COMMANDS} SOURCES ${NSIS_SOURCES})

  IF("${_TARGET}" STREQUAL "ALL")
    SET(_TARGET ${ALL_TARGETS})
  ENDIF()

  ADD_DEPENDENCIES(packages ${_TARGET})

  SET_TARGET_LABEL(packages "PACKAGE")
ENDMACRO()
