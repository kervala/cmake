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

FIND_PACKAGE_HELPER(X264 x264.h QUIET)

IF(X264_FOUND)
  PARSE_VERSION_OTHER(${X264_INCLUDE_DIR}/x264_config.h X264_POINTVER)

  SET(X264_VERSION "${X264_POINTVER}")

  PARSE_VERSION_STRING(${X264_VERSION} X264_VERSION_MAJOR X264_VERSION_MINOR X264_VERSION_PATCH)

  MESSAGE_VERSION_PACKAGE_HELPER(X264 ${X264_VERSION} ${X264_LIBRARIES})
ENDIF()
