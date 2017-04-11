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

FIND_PACKAGE_HELPER(Speex speex/speex.h)

IF(SPEEX_FOUND)
  SET(SPEEXDSP_DIR ${SPEEX_DIR})
  FIND_PACKAGE_HELPER(SpeexDSP speex/speex_resampler.h)

  IF(SPEEXDSP_FOUND)
    SET(SPEEX_LIBRARIES ${SPEEX_LIBRARIES} ${SPEEXDSP_LIBRARIES})
  ENDIF()

  IF(NOT CMAKE_CROSSCOMPILING)
    FILE(WRITE "${CMAKE_BINARY_DIR}/speex_version.cpp"
      "#include <stdio.h>\n#include <speex/speex.h>\n\nint main(int argc, char* argv[])\n{const char *version = NULL;\nif (speex_lib_ctl(SPEEX_LIB_GET_VERSION_STRING, (void*)&version)) return 1;\nprintf(version);\nreturn 0;\n}\n")

    GET_DIRECTORY_PROPERTY(_DIRS DIRECTORY ${CMAKE_SOURCE_DIR} INCLUDE_DIRECTORIES)

    TRY_RUN(_RunResult
      _CompileResult
      ${CMAKE_BINARY_DIR}
      ${CMAKE_BINARY_DIR}/speex_version.cpp
      COMPILE_DEFINITIONS LINK_LIBRARIES ${SPEEX_LIBRARIES}
      CMAKE_FLAGS "-DINCLUDE_DIRECTORIES=${_DIRS};${SPEEX_INCLUDE_DIRS}"
      RUN_OUTPUT_VARIABLE SPEEX_VERSION
    )

    # for debugging purposes
    # COMPILE_OUTPUT_VARIABLE _compileoutput
    FILE(REMOVE "${CMAKE_BINARY_DIR}/speex_version.cpp")
  ELSE()
    SET(SPEEX_VERSION "Unknown")
  ENDIF()

  MESSAGE_VERSION_PACKAGE_HELPER(Speex ${SPEEX_VERSION} ${SPEEX_LIBRARIES})
ENDIF()
