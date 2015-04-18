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

IF(TARGET_X64)
  SET(FMOD_BASE fmod64)
ELSE()
  SET(FMOD_BASE fmodvc)
ENDIF()

FIND_PACKAGE_HELPER(FMOD fmod.h RELEASE ${FMOD_BASE} DEBUG ${FMOD_BASE}d SUFFIXES fmod3)
