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

FIND_PACKAGE_HELPER(Squish squish.h)

IF(SQUISH_FOUND)
  IF(NOT SQUISH_FIND_QUIETLY)
    MESSAGE(STATUS "Found Squish: ${SQUISH_LIBRARIES}")
  ENDIF()
  FILE(STRINGS ${SQUISH_INCLUDE_DIR}/squish.h METRIC REGEX "metric = 0")
  IF(METRIC)
    SET(SQUISH_COMPRESS_HAS_METRIC ON)
    SET(SQUISH_DEFINITIONS -DSQUISH_COMPRESS_HAS_METRIC)
  ENDIF()
ENDIF()
