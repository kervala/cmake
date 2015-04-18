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

FIND_PACKAGE_HELPER(FontConfig fontconfig/fontconfig.h QUIET)

IF(FONTCONFIG_FOUND)
  PARSE_VERSION_OTHER(${FONTCONFIG_INCLUDE_DIR}/fontconfig/fontconfig.h FC_MAJOR FC_MINOR FC_REVISION)

  SET(FONTCONFIG_VERSION "${FC_MAJOR}.${FC_MINOR}.${FC_REVISION}")

  MESSAGE_VERSION_PACKAGE_HELPER(FontConfig ${FONTCONFIG_VERSION} ${FONTCONFIG_LIBRARIES})
ENDIF()
