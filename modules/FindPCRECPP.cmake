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

FIND_PACKAGE_HELPER(PCRE pcre.h)
FIND_PACKAGE_HELPER(PCRECPP pcrecpp.h)

IF(PCRECPP_FOUND)
  SET(PCRECPP_LIBRARIES ${PCRE_LIBRARIES} ${PCRECPP_LIBRARIES})
  SET(PCRECPP_DEFINITIONS "-DHAVE_PCRECPP")
  IF(WIN32)
    SET(PCRECPP_DEFINITIONS "-DPCRE_STATIC ${PCRECPP_DEFINITIONS}")
  ENDIF()
ENDIF()
