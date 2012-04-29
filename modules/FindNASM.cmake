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

  STRING(REGEX REPLACE ".*version ([\\.0-9]+).*" "\\1" NASM_VERSION ${NASM_VERSION})

  IF(NASM_VERSION VERSION_GREATER "2.0")
    MESSAGE(STATUS "Found NASM version ${NASM_VERSION} in ${NASM_EXECUTABLE}")
    SET(NASM_FOUND ON)
  ELSE(NASM_VERSION VERSION_GREATER "2.0")
    MESSAGE(STATUS "Found too old NASM version ${NASM_VERSION} in ${NASM_EXECUTABLE}, disabling ASM")
    SET(NASM_FOUND OFF)
  ENDIF(NASM_VERSION VERSION_GREATER "2.0")
ENDIF(NASM_EXECUTABLE)

# Syntax: SET_TARGET_NASM_LIB(<C++ target> <C++ product> <asm file> [asm file]...)
MACRO(SET_TARGET_NASM_LIB TARGET PRODUCT)
  IF(NOT NASM_FOUND)
    MESSAGE(FATAL_ERROR "Couldn't find NASM to compile ${TARGET}")
  ENDIF(NOT NASM_FOUND)

  FOREACH(ARG ${ARGN})
    LIST(APPEND SRC_ASM ${ARG})
  ENDFOREACH(ARG)

  # Define output format suffix
  IF(TARGET_X64)
    SET(ASM_SUFFIX 64)
  ELSE(TARGET_X64)
    SET(ASM_SUFFIX 32)
  ENDIF(TARGET_X64)

  # Define output format
  IF(WIN32)
    SET(ASM_DEFINITIONS -f win${ASM_SUFFIX} ${ASM_DEFINITIONS})
  ELSEIF(APPLE)
    SET(ASM_DEFINITIONS -f macho${ASM_SUFFIX} ${ASM_DEFINITIONS})
  ELSE(WIN32)
    SET(ASM_DEFINITIONS -f elf${ASM_SUFFIX} ${ASM_DEFINITIONS})
  ENDIF(WIN32)

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
  ENDFOREACH(ASM)

  # Create a library with all .obj files
  SET_TARGET_LIB(${TARGET}_asm STATIC ${SRC_ASM} ${OBJ_ASM})
  SET_TARGET_LABEL(${TARGET}_asm "${PRODUCT} Assembler")

  # Or else we get an error message
  SET_TARGET_PROPERTIES(${TARGET}_asm PROPERTIES LINKER_LANGUAGE C)

  TARGET_LINK_LIBRARIES(${TARGET} ${TARGET}_asm)
ENDMACRO(SET_TARGET_NASM_LIB)
