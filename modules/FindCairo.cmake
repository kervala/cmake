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

FIND_PACKAGE_HELPER(Cairo cairo.h QUIET)

IF(CAIRO_FOUND)
  IF(EXISTS ${CAIRO_INCLUDE_DIR}/cairo-version.h)
    # Recent versions such as 1.10.2
    PARSE_VERSION_OTHER(${CAIRO_INCLUDE_DIR}/cairo-version.h CAIRO_VERSION_MAJOR CAIRO_VERSION_MINOR CAIRO_VERSION_MICRO)
  ELSEIF(EXISTS ${CAIRO_INCLUDE_DIR}/cairo-features.h)
    # Old versions such as 1.6.4
    PARSE_VERSION_OTHER(${CAIRO_INCLUDE_DIR}/cairo-features.h CAIRO_VERSION_MAJOR CAIRO_VERSION_MINOR CAIRO_VERSION_MICRO)
  ELSE()
    # Very old versions
    SET(CAIRO_VERSION_MAJOR 0)
    SET(CAIRO_VERSION_MINOR 0)
    SET(CAIRO_VERSION_MICRO 0)
  ENDIF()
  
  SET(CAIRO_VERSION "${CAIRO_VERSION_MAJOR}.${CAIRO_VERSION_MINOR}.${CAIRO_VERSION_MICRO}")

  MESSAGE_VERSION_PACKAGE_HELPER(Cairo ${CAIRO_VERSION} ${CAIRO_LIBRARIES})
ENDIF()
