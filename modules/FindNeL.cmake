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

SET(NEL_LIBRARIES)
SET(NEL_INCLUDE_DIRS)

FOREACH(COMPONENT ${NeL_FIND_COMPONENTS})
  SET(_NAME NeL${COMPONENT})
  STRING(TOUPPER ${_NAME} _UPNAME)

  SET(${_NAME}_FIND_REQUIRED ${NeL_FIND_REQUIRED})

  FIND_PACKAGE_HELPER(${_NAME} nel/misc/types_nl.h
    RELEASE nel${COMPONENT}_r nel${COMPONENT}
    DEBUG nel${COMPONENT}_d
    QUIET)

  IF(${_UPNAME}_FOUND)
    LIST(APPEND NEL_LIBRARIES ${${_UPNAME}_LIBRARIES})
    IF(NOT NEL_INCLUDE_DIRS)
      SET(NEL_INCLUDE_DIRS ${${_UPNAME}_INCLUDE_DIRS})
    ENDIF()
  ENDIF()

  IF(COMPONENT STREQUAL "3d")
    FIND_PACKAGE(Freetype REQUIRED)
    LIST(APPEND NEL_LIBRARIES ${FREETYPE_LIBRARIES})
  ELSEIF(COMPONENT STREQUAL "misc")
    FIND_PACKAGE(MyPNG REQUIRED)
    FIND_PACKAGE(Jpeg REQUIRED)
    FIND_PACKAGE(LibXml2 REQUIRED)
    LIST(APPEND NEL_LIBRARIES ${PNG_LIBRARIES} ${JPEG_LIBRARIES} ${LIBXML2_LIBRARIES})
  ENDIF()
ENDFOREACH()

MESSAGE_VERSION_PACKAGE_HELPER(NeL "0.50" ${NEL_LIBRARIES})
