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

FIND_PACKAGE_HELPER(DevIL IL/il.h RELEASE IL DEBUG ILd QUIET)

IF(DEVIL_FOUND)
  SET(DEVIL_DEFINITIONS "-DHAVE_DEVIL")

  IF(WIN32)
    SET(DEVIL_DEFINITIONS "${DEVIL_DEFINITIONS} -DIL_STATIC_LIB")
  ENDIF()

  PARSE_VERSION_OTHER(${DEVIL_INCLUDE_DIR}/IL/il.h IL_VERSION)

  IF(IL_VERSION)
    STRING(SUBSTRING ${IL_VERSION} 0 1 DEVIL_VERSION_MAJOR)
    STRING(SUBSTRING ${IL_VERSION} 1 1 DEVIL_VERSION_MINOR)
    STRING(SUBSTRING ${IL_VERSION} 2 1 DEVIL_VERSION_PATCH)
  ENDIF()

  SET(DEVIL_VERSION "${DEVIL_VERSION_MAJOR}.${DEVIL_VERSION_MINOR}.${DEVIL_VERSION_PATCH}")

  MESSAGE_VERSION_PACKAGE_HELPER(DevIL ${DEVIL_VERSION} ${DEVIL_LIBRARIES})
ENDIF()
