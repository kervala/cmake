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

FIND_PACKAGE_HELPER(Luabind luabind/luabind.hpp)

IF(LUABIND_FOUND)
  FIND_PACKAGE(MyBoost REQUIRED)

  SET(LUABIND_INCLUDE_DIR ${LUABIND_INCLUDE_DIR} ${BOOST_INCLUDE_DIR})
  # Check if luabind/version.hpp exists
  FIND_FILE(LUABIND_VERSION_FILE luabind/version.hpp PATHS ${LUABIND_INCLUDE_DIR})
  IF(LUABIND_VERSION_FILE)
    SET(LUABIND_DEFINITIONS "-DHAVE_LUABIND_VERSION")
  ENDIF(LUABIND_VERSION_FILE)
ENDIF(LUABIND_FOUND)
