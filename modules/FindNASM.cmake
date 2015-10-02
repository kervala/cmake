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

# Syntax: SET_TARGET_NASM_LIB(<C++ target> <C++ product> <asm file> [asm file]...)
MACRO(SET_TARGET_NASM_LIB TARGET PRODUCT)
  IF(NOT NASM_FOUND)
    MESSAGE(FATAL_ERROR "Couldn't find NASM to compile ${TARGET}")
  ENDIF()

  FOREACH(ARG ${ARGN})
    LIST(APPEND SRC_ASM ${ARG})
  ENDFOREACH()

  # Define output format suffix
  IF(TARGET_X64)
    SET(ASM_SUFFIX 64)
  ELSE()
    SET(ASM_SUFFIX 32)
  ENDIF()

  # Define output format
  IF(WIN32)
    SET(ASM_DEFINITIONS -f win${ASM_SUFFIX} ${ASM_DEFINITIONS})
  ELSEIF(APPLE)
    SET(ASM_DEFINITIONS -f macho${ASM_SUFFIX} ${ASM_DEFINITIONS})
  ELSE()
    SET(ASM_DEFINITIONS -f elf${ASM_SUFFIX} ${ASM_DEFINITIONS})
  ENDIF()

  SET(ASM_DEFINITIONS ${ASM_DEFINITIONS} -I${CMAKE_CURRENT_SOURCE_DIR}/)

  FOREACH(ASM ${SRC_ASM})
    # Build output filename
    STRING(REPLACE ".asm" ${CMAKE_C_OUTPUT_EXTENSION} OBJ ${ASM})
    GET_FILENAME_COMPONENT(OUTPUT_DIR ${CMAKE_BINARY_DIR} ABSOLUTE)
    STRING(REPLACE ${CMAKE_SOURCE_DIR} ${OUTPUT_DIR} OBJ ${OBJ})

    # Create output directory to avoid error with nmake
    GET_FILENAME_COMPONENT(OUTPUT_DIR ${OBJ} PATH)
    FILE(MAKE_DIRECTORY ${OUTPUT_DIR})

    # Extract path and name from filename
    GET_FILENAME_COMPONENT(INPUT_DIR ${ASM} PATH)
    GET_FILENAME_COMPONENT(BASEFILE ${ASM} NAME)

    # Compile .asm file with nasm
    ADD_CUSTOM_COMMAND(OUTPUT ${OBJ}
      COMMAND ${NASM_EXECUTABLE} ${ASM_DEFINITIONS} -I${INPUT_DIR}/ -o ${OBJ} ${ASM}
      DEPENDS ${ASM}
      COMMENT "Compiling ${BASEFILE}")

    # Append resulting object file to the list
    LIST(APPEND OBJ_ASM ${OBJ})
  ENDFOREACH()

  # Create a library with all .obj files
  SET_TARGET_LIB(${TARGET}_asm PRIVATE ${SRC_ASM} ${OBJ_ASM})
  SET_TARGET_LABEL(${TARGET}_asm "${PRODUCT} Assembler")

  # Or else we get an error message
  SET_TARGET_PROPERTIES(${TARGET}_asm PROPERTIES LINKER_LANGUAGE C)

  TARGET_LINK_LIBRARIES(${TARGET} ${TARGET}_asm)
ENDMACRO()
