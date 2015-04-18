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

FIND_PACKAGE_HELPER(Xvid xvid.h RELEASE xvidcore DEBUG xvidcored QUIET)

IF(XVID_FOUND)
  FILE(STRINGS ${XVID_INCLUDE_DIR}/xvid.h _FILE REGEX "#define XVID_VERSION    ")

  STRING(REGEX REPLACE "^.*XVID_MAKE_VERSION\\(([0-9,-]+)\\).*$" "\\1" XVID_VERSION "${_FILE}")
  STRING(REPLACE "," "." XVID_VERSION "${XVID_VERSION}")

  PARSE_VERSION_STRING(${XVID_VERSION} XVID_VERSION_MAJOR XVID_VERSION_MINOR)

  SET(XVID_VERSION "${XVID_VERSION_MAJOR}.${XVID_VERSION_MINOR}")

  MESSAGE_VERSION_PACKAGE_HELPER(Xvid ${XVID_VERSION} ${XVID_LIBRARIES})
ENDIF()
