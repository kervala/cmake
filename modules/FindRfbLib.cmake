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

FIND_PACKAGE_HELPER(RfbLib RfbLib.h DIR ${RFB_LIB_DIR} QUIET)

IF(RFBLIB_FOUND)
  FIND_PACKAGE(Neolib REQUIRED)

  FIND_LIBRARY_HELPER(JPEG DIR ${POPPLER_DIR} REQUIRED)
  FIND_LIBRARY_HELPER(ZLIB RELEASE z DEBUG zd DIR ${POPPLER_DIR} REQUIRED)

  SET(RFBLIB_INCLUDE_DIRS ${RFBLIB_INCLUDE_DIR} ${NEOLIB_INCLUDE_DIRS})
  SET(RFBLIB_LIBRARIES ${RFBLIB_LIBRARIES} ${NEOLIB_LIBRARIES} ${ZLIB_LIBRARIES} ${JPEG_LIBRARIES})
  SET(RFBLIB_DEFINITIONS ${NEOLIB_DEFINITIONS})

  MESSAGE_VERSION_PACKAGE_HELPER(RFBLIB "" ${RFBLIB_LIBRARIES})
ENDIF()
