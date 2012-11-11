FIND_PACKAGE_HELPER(Lua lua.h "lua51 lua5.1 lua-5.1 lua" "lua51d lua5.1d lua-5.1d luad" QUIET)

IF(LUA_FOUND)
  # include the math library for Unix
  IF(UNIX AND NOT APPLE)
    FIND_LIBRARY(LUA_MATH_LIBRARY m)
    SET(LUA_LIBRARIES ${LUA_LIBRARIES} ${LUA_MATH_LIBRARY} CACHE STRING "Lua Libraries")
    # For Windows and Mac, don't need to explicitly include the math library
  ENDIF(UNIX AND NOT APPLE)

  FILE(STRINGS "${LUA_INCLUDE_DIR}/lua.h" lua_version_str REGEX "^#define[ \t]+LUA_RELEASE[ \t]+\"Lua .+\"")

  STRING(REGEX REPLACE "^#define[ \t]+LUA_RELEASE[ \t]+\"Lua ([^\"]+)\".*" "\\1" LUA_VERSION_STRING "${lua_version_str}")
  UNSET(lua_version_str)
  MESSAGE_VERSION_PACKAGE_HELPER(Lua ${LUA_LIBRARIES} ${LUA_VERSION_STRING})
ENDIF(LUA_FOUND)
