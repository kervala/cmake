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

IF(RFB_LIB_DIR)
  SET(RFBLIB_DIR ${RFB_LIB_DIR})
ENDIF()

FIND_PACKAGE_HELPER(RfbLib RfbLib.h)

IF(RFBLIB_FOUND)
  FIND_PACKAGE(OpenSSL REQUIRED)
  FIND_PACKAGE(Neolib REQUIRED)
  FIND_PACKAGE(ZLIB REQUIRED)
  FIND_PACKAGE(JPEG REQUIRED)

  SET(RFBLIB_INCLUDE_DIRS ${RFBLIB_INCLUDE_DIR} ${OPENSSL_INCLUDE_DIR} ${NEOLIB_INCLUDE_DIR} ${ZLIB_INCLUDE_DIR} ${JPEG_INCLUDE_DIR})
  SET(RFBLIB_LIBRARIES ${RFBLIB_LIBRARIES} ${OPENSSL_LIBRARIES} ${NEOLIB_LIBRARIES} ${ZLIB_LIBRARY} ${JPEG_LIBRARY})
  SET(RFBLIB_DEFINITIONS ${NEOLIB_DEFINITIONS})

  IF(WIN32)
    SET(RFBLIB_LIBRARIES ${RFBLIB_LIBRARIES} Ws2_32)
  ENDIF(WIN32)
ENDIF()
