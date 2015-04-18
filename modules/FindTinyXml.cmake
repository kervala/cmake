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

FIND_PACKAGE_HELPER(TinyXml tinyxml.h RELEASE tinyxmlstl DEBUG tinyxmlstld QUIET)

IF(TINYXML_FOUND)
  SET(TINYXML_DEFINITIONS "-DTIXML_USE_STL")

  PARSE_VERSION_OTHER(${TINYXML_INCLUDE_DIR}/tinyxml.h TIXML_MAJOR_VERSION TIXML_MINOR_VERSION TIXML_PATCH_VERSION)
  SET(TINYXML_VERSION "${TIXML_MAJOR_VERSION}.${TIXML_MINOR_VERSION}.${TIXML_PATCH_VERSION}")

  MESSAGE_VERSION_PACKAGE_HELPER(TinyXml ${TINYXML_VERSION} ${TINYXML_LIBRARIES})
ENDIF()
