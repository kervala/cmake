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

FIND_PACKAGE_HELPER(Pqxx pqxx/pqxx RELEASE libpqxx libpqxx_static DEBUG libpqxxD libpqxx_staticD QUIET)

IF(PQXX_FOUND)
  IF(PQXX_LIBRARY_RELEASE MATCHES "static")
    SET(PQXX_TYPE "static")

    # static version of pqxx needs libpq
    FIND_PACKAGE(Libpq REQUIRED)
    IF(LIBPQ_FOUND)
      LIST(APPEND PQXX_LIBRARIES ${LIBPQ_LIBRARIES})
    ENDIF()
  ELSE()
    SET(PQXX_TYPE "shared")
    SET(PQXX_DEFINITIONS "-DPQXX_SHARED")
  ENDIF()

  PARSE_VERSION_OTHER(${PQXX_INCLUDE_DIR}/pqxx/version.hxx PQXX_VERSION_MAJOR PQXX_VERSION_MINOR)

  # First version with pqxx_version.hxx is 3.1
  IF(NOT PQXX_VERSION_MAJOR)
    SET(PQXX_VERSION_MAJOR 2)
    SET(PQXX_VERSION_MINOR 0)
  ENDIF()

  SET(PQXX_VERSION "${PQXX_VERSION_MAJOR}.${PQXX_VERSION_MINOR}")

  MESSAGE_VERSION_PACKAGE_HELPER(Pqxx "${PQXX_VERSION} ${PQXX_TYPE}" ${PQXX_LIBRARIES})
ENDIF()
