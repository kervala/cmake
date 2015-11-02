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

MACRO(FIND_LUA MAJOR MINOR)
  SET(_NAME "Lua${MAJOR}${MINOR}")
  SET(_VERSION "${MAJOR}.${MINOR}")
  FIND_PACKAGE_HELPER(${_NAME} lua.h RELEASE lua${_VERSION} lua-${_VERSION} DEBUG lua${_VERSION}d lua-${_VERSION}d SUFFIXES lua${_VERSION} lua-${_VERSION} QUIET)
  
  IF(${_UPNAME_FIXED}_FOUND)
    SET(LUA_FOUND ON)
    SET(LUA_INCLUDE_DIR ${${_UPNAME_FIXED}_INCLUDE_DIR})
    SET(LUA_INCLUDE_DIRS ${${_UPNAME_FIXED}_INCLUDE_DIRS})
    SET(LUA_LIBRARIES ${${_UPNAME_FIXED}_LIBRARIES})
  ENDIF()
ENDMACRO()

IF(Lua_FIND_VERSION_MAJOR)
  IF(NOT Lua_FIND_VERSION_MAJOR EQUAL 5)
    MESSAGE(FATAL_ERROR "Lua versions from 5.0 to 5.3 are supported")
  ENDIF()

  # check specific version
  FIND_LUA(${Lua_FIND_VERSION_MAJOR} ${Lua_FIND_VERSION_MINOR})
ELSE()
  # check all supported versions
  FIND_LUA(5 3)

  IF(NOT LUA_FOUND)
    FIND_LUA(5 2)
  ENDIF()

  IF(NOT LUA_FOUND)
    FIND_LUA(5 1)
  ENDIF()

  IF(NOT LUA_FOUND)
    FIND_LUA(5 0)
  ENDIF()

  IF(NOT LUA_FOUND)
    FIND_PACKAGE_HELPER(Lua lua.h RELEASE lua DEBUG luad QUIET)
  ENDIF()
ENDIF()

IF(LUA_FOUND)
  # include the math library for Unix
  IF(UNIX AND NOT APPLE)
    FIND_LIBRARY(LUA_MATH_LIBRARY m)
    SET(LUA_LIBRARIES ${LUA_LIBRARIES} ${LUA_MATH_LIBRARY} CACHE STRING "Lua Libraries")
    # For Windows and Mac, don't need to explicitly include the math library
  ENDIF()

  IF(NOT LUA_VERSION)
    # Lua 5.0
    #define LUA_VERSION	"Lua 5.0.3"
    FILE(STRINGS "${LUA_INCLUDE_DIR}/lua.h" _CONTENT REGEX "^#define LUA_VERSION[ \t]+\"Lua [0-9.]+\"")

    IF(_CONTENT)
      STRING(REGEX REPLACE "^#define LUA_VERSION[ \t]+\"Lua ([0-9.]+)\".*" "\\1" LUA_VERSION "${_CONTENT}")
    ENDIF()
  ENDIF()
  
  IF(NOT LUA_VERSION)
    # Lua 5.1
    #define LUA_RELEASE	"Lua 5.1.5"
    FILE(STRINGS "${LUA_INCLUDE_DIR}/lua.h" _CONTENT REGEX "^#define LUA_RELEASE[ \t]+\"Lua [0-9.]+\"")

    IF(_CONTENT)
      STRING(REGEX REPLACE "^#define LUA_RELEASE[ \t]+\"Lua ([0-9.]+)\".*" "\\1" LUA_VERSION "${_CONTENT}")
    ENDIF()
  ENDIF()
  
  IF(NOT LUA_VERSION)
    # Lua 5.2
    #define LUA_VERSION_MAJOR	"5"
    #define LUA_VERSION_MINOR	"2"
    #define LUA_VERSION_RELEASE	"2"
    FILE(STRINGS "${LUA_INCLUDE_DIR}/lua.h" _CONTENT REGEX "^#define LUA_VERSION_(MAJOR|MINOR|RELEASE)[ \t]+\"[0-9]+\"")

    IF(_CONTENT)
      STRING(REGEX REPLACE "^.*#define LUA_VERSION_MAJOR[ \t]+\"([0-9]+)\".*" "\\1" LUA_VERSION_MAJOR "${_CONTENT}")
      STRING(REGEX REPLACE "^.*#define LUA_VERSION_MINOR[ \t]+\"([0-9]+)\".*" "\\1" LUA_VERSION_MINOR "${_CONTENT}")
      STRING(REGEX REPLACE "^.*#define LUA_VERSION_RELEASE[ \t]+\"([0-9]+)\".*" "\\1" LUA_VERSION_RELEASE "${_CONTENT}")
      SET(LUA_VERSION "${LUA_VERSION_MAJOR}.${LUA_VERSION_MINOR}.${LUA_VERSION_RELEASE}")
    ENDIF()
  ENDIF()

  IF(NOT LUA_VERSION)
    SET(LUA_VERSION "unknown")
  ENDIF()

  MESSAGE_VERSION_PACKAGE_HELPER(Lua ${LUA_VERSION} ${LUA_LIBRARIES})
ENDIF()
