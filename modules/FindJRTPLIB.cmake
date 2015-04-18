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

FIND_PACKAGE_HELPER(JRTPLIB rtpconfig.h RELEASE jrtplib DEBUG jrtplib_d SUFFIXES jrtplib3)

FIND_PACKAGE_HELPER(JThread jthread.h RELEASE jthread DEBUG jthread_d SUFFIXES jthread)

IF(JRTPLIB_FOUND)
  SET(JRTPLIB_INCLUDE_DIRS ${JRTPLIB_INCLUDE_DIR} ${JTHREAD_INCLUDE_DIR})
  SET(JRTPLIB_LIBRARIES ${JRTPLIB_LIBRARIES} ${JTHREAD_LIBRARIES})
ENDIF()
