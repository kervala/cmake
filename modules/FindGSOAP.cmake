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

FIND_PACKAGE_HELPER(GSOAP stdsoap2.h RELEASE stdsoap2 DEBUG gsoapd stdsoap2d)

FIND_PROGRAM(GSOAP_SOAPCPP2
  NAMES
  soapcpp2
  soapcpp2.exe
  PATHS
  ${GSOAP_BIN_PATH}
  /usr/local/bin
  /usr/bin
)

FIND_PATH(GSOAP_IMPORT_DIR 
  wsa.h
  ${GSOAP_LIB_PATH}
  /usr/local/share/gsoap/import
  /usr/share/gsoap/import
)

MACRO(GSOAP_WRAPPER file target)
  FILE(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/generated)
  SET_SOURCE_FILES_PROPERTIES(${CMAKE_BINARY_DIR}/generated/${target}${file}.cpp PROPERTIES GENERATED TRUE)

  ADD_CUSTOM_COMMAND(OUTPUT ${CMAKE_BINARY_DIR}/generated/${target}${file}.cpp
    COMMAND ${GSOAP_SOAPCPP2} -x -I${GSOAP_IMPORT_DIR} -q${target} -d${CMAKE_BINARY_DIR}/generated -n ${CMAKE_CURRENT_SOURCE_DIR}/${target}.h
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${target}.h)
ENDMACRO(GSOAP_WRAPPER)
