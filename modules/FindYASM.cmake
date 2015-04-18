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

SET(YASM_ROOT_PATHS "$ENV{PROGRAMFILES}/yasm" "$ENV{YASM_DIR}")

FIND_PROGRAM(YASM_EXECUTABLE
  NAMES
    yasm-1.3.0-win64.exe
    yasm-1.3.0-win32.exe
    yasm-1.2.0-win64.exe
    yasm-1.2.0-win32.exe
    yasm
  PATHS
    ${YASM_ROOT_PATH}
    ${YASM_ROOT_PATHS}
)

MARK_AS_ADVANCED(YASM_EXECUTABLE)

IF(YASM_EXECUTABLE)
  EXECUTE_PROCESS(COMMAND ${YASM_EXECUTABLE} --version
    OUTPUT_VARIABLE YASM_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  STRING(REGEX REPLACE "yasm ([\\.0-9]+).*" "\\1" YASM_VERSION "${YASM_VERSION}")

  IF(YASM_VERSION VERSION_GREATER "1.0")
    MESSAGE(STATUS "Found YASM version ${YASM_VERSION} in ${YASM_EXECUTABLE}")
    SET(YASM_FOUND ON)
  ELSE()
    MESSAGE(STATUS "Found too old YASM version ${YASM_VERSION} in ${YASM_EXECUTABLE}, disabling ASM")
    SET(YASM_FOUND OFF)
  ENDIF()
ENDIF()

MACRO(YASM_SET_FLAGS)
  IF(NOT YASM_FOUND)
    MESSAGE(FATAL_ERROR "Couldn't find YASM")
  ENDIF()
  
  SET(YASM_FLAGS)
  
  FOREACH(ARG ${ARGN})
    LIST(APPEND YASM_FLAGS ${ARG})
  ENDFOREACH()
  
  # Define output format suffix
  IF(TARGET_X64)
    SET(YASM_SUFFIX 64)
    SET(YASM_FLAGS -m amd64 ${YASM_FLAGS})
  ELSEIF(TARGET_X86)
    SET(YASM_SUFFIX 32)
    SET(YASM_FLAGS -m x86 ${YASM_FLAGS})
  ENDIF()

  # Define output format
  IF(WIN32)
    SET(YASM_FLAGS -f win${YASM_SUFFIX} ${YASM_FLAGS})
  ELSEIF(APPLE)
    SET(YASM_FLAGS -f macho${YASM_SUFFIX} ${YASM_FLAGS})
  ELSE()
    SET(YASM_FLAGS -f elf${YASM_SUFFIX} ${YASM_FLAGS})
  ENDIF()

  SET(YASM_FLAGS ${YASM_FLAGS} -I${CMAKE_CURRENT_SOURCE_DIR}/)
ENDMACRO()

MACRO(YASM_APPEND_ASM_FILES _FILES)
  IF(NOT YASM_FOUND)
    MESSAGE(FATAL_ERROR "Couldn't find YASM to compile")
  ENDIF()
  
  SET(_SRC_ASM)
  
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
    FILE(MAKE_DIRECTORY ${OUTPUT_DIR})

    # Extract path and name from filename
    GET_FILENAME_COMPONENT(INPUT_DIR ${ASM} PATH)
    GET_FILENAME_COMPONENT(BASEFILE ${ASM} NAME)

    # Compile .asm file with yasm
    ADD_CUSTOM_COMMAND(OUTPUT ${OBJ}
      COMMAND ${YASM_EXECUTABLE} ${YASM_FLAGS} -I${INPUT_DIR}/ -o ${OBJ} ${ASM}
      DEPENDS ${ASM}
      COMMENT "Compiling ${BASEFILE}")

    SET_PROPERTY(SOURCE ${OBJ} APPEND PROPERTY OBJECT_DEPENDS ${ASM})

    SET_SOURCE_FILES_PROPERTIES(${OBJ} PROPERTIES GENERATED TRUE)
    SET_SOURCE_FILES_PROPERTIES(${ASM} PROPERTIES HEADER_FILE_ONLY TRUE)

    # Append resulting object file to the list
    LIST(APPEND OBJ_ASM ${OBJ})
  ENDFOREACH()
  
  SOURCE_GROUP(asm FILES ${_SRC_ASM})
  SOURCE_GROUP(obj FILES ${OBJ_ASM})
  
  LIST(APPEND ${_FILES} ${_SRC_ASM} ${OBJ_ASM})
ENDMACRO()
