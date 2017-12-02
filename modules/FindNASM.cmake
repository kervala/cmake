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

SET(NASM_ROOT_PATHS "$ENV{PROGRAMFILES}/nasm" "$ENV{NASM_DIR}")

FIND_PROGRAM(NASM_EXECUTABLE
  NAMES
    nasm
  PATHS
    ${NASM_ROOT_PATH}
    ${NASM_ROOT_PATHS}
)

MARK_AS_ADVANCED(NASM_EXECUTABLE)

IF(NASM_EXECUTABLE)
  EXECUTE_PROCESS(COMMAND ${NASM_EXECUTABLE} -v
    OUTPUT_VARIABLE NASM_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  STRING(REGEX REPLACE ".*version ([\\.0-9]+).*" "\\1" NASM_VERSION "${NASM_VERSION}")

  IF(NASM_VERSION VERSION_GREATER "2.0")
    MESSAGE(STATUS "Found NASM version ${NASM_VERSION} in ${NASM_EXECUTABLE}")
    SET(NASM_FOUND ON)
  ELSE()
    MESSAGE(STATUS "Found too old NASM version ${NASM_VERSION} in ${NASM_EXECUTABLE}, disabling ASM")
    SET(NASM_FOUND OFF)
  ENDIF()
ENDIF()

MACRO(NASM_SET_FLAGS)
  IF(NOT NASM_FOUND)
    MESSAGE(FATAL_ERROR "Couldn't find NASM")
  ENDIF()

  SET(NASM_FLAGS)

  FOREACH(ARG ${ARGN})
    LIST(APPEND NASM_FLAGS ${ARG})
  ENDFOREACH()

  # Define output format suffix
  IF(NASM_ARCH)
    IF(NASM_ARCH STREQUAL "x86_64")
      SET(NASM_SUFFIX 64)
    ELSEIF(NASM_ARCH STREQUAL "i386")
      SET(NASM_SUFFIX 32)
    ELSE()
      MESSAGE(FATAL_ERROR "Unsupported arch ${NASM_ARCH} for NASM")
    ENDIF()
  ELSEIF(TARGET_X64)
    SET(NASM_SUFFIX 64)
  ELSEIF(TARGET_X86)
    SET(NASM_SUFFIX 32)
  ELSE()
    MESSAGE(FATAL_ERROR "Unsupported arch for NASM")
  ENDIF()

  # Define output format
  IF(WIN32)
    SET(NASM_FLAGS -f win${NASM_SUFFIX} ${NASM_FLAGS})
  ELSEIF(APPLE)
    SET(NASM_FLAGS -f macho${NASM_SUFFIX} ${NASM_FLAGS})
  ELSE()
    SET(NASM_FLAGS -f elf${NASM_SUFFIX} ${NASM_FLAGS})
  ENDIF()

  SET(NASM_FLAGS ${NASM_FLAGS} -I${CMAKE_CURRENT_SOURCE_DIR}/)
ENDMACRO()

MACRO(NASM_APPEND_ASM_FILES _FILES)
  IF(NOT NASM_FOUND)
    MESSAGE(FATAL_ERROR "Couldn't find NASM to compile")
  ENDIF()

  SET(_SRC_ASM)
  SET(_OBJ_ASM)

  FOREACH(ARG ${ARGN})
    LIST(APPEND _SRC_ASM ${ARG})
  ENDFOREACH()

  FOREACH(ASM ${_SRC_ASM})
    # Build output filename
    STRING(REPLACE ".asm" ${CMAKE_C_OUTPUT_EXTENSION} OBJ ${ASM})
    GET_FILENAME_COMPONENT(OUTPUT_DIR ${CMAKE_BINARY_DIR} ABSOLUTE)
    STRING(REPLACE ${CMAKE_SOURCE_DIR} ${OUTPUT_DIR} OBJ ${OBJ})

    # Create output directory to avoid error with nmake
    GET_FILENAME_COMPONENT(OUTPUT_DIR ${OBJ} PATH)

    IF(NASM_ARCH)
      GET_FILENAME_COMPONENT(OUTPUT_FILENAME ${OBJ} NAME)
      SET(OUTPUT_DIR ${OUTPUT_DIR}/${NASM_ARCH})
      SET(OBJ ${OUTPUT_DIR}/${OUTPUT_FILENAME})
    ENDIF()

    FILE(MAKE_DIRECTORY ${OUTPUT_DIR})

    # Extract path and name from filename
    GET_FILENAME_COMPONENT(INPUT_DIR ${ASM} PATH)
    GET_FILENAME_COMPONENT(BASEFILE ${ASM} NAME)

    # Compile .asm file with nasm
    ADD_CUSTOM_COMMAND(OUTPUT ${OBJ}
      COMMAND ${NASM_EXECUTABLE} ${NASM_FLAGS} -I${INPUT_DIR}/ -o ${OBJ} ${ASM}
      DEPENDS ${ASM}
      COMMENT "Compiling ${BASEFILE}")

    SET_PROPERTY(SOURCE ${OBJ} APPEND PROPERTY OBJECT_DEPENDS ${ASM})

    SET_SOURCE_FILES_PROPERTIES(${OBJ} PROPERTIES GENERATED TRUE)
    SET_SOURCE_FILES_PROPERTIES(${ASM} PROPERTIES HEADER_FILE_ONLY TRUE)

    # Append resulting object file to the list
    LIST(APPEND _OBJ_ASM ${OBJ})
  ENDFOREACH()

  SOURCE_GROUP(asm FILES ${_SRC_ASM})
  SOURCE_GROUP(obj FILES ${_OBJ_ASM})

  LIST(APPEND ${_FILES} ${_SRC_ASM} ${_OBJ_ASM})
ENDMACRO()
