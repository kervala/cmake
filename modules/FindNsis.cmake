SET(NSIS_ROOT_PATHS "$ENV{PROGRAMFILES}/NSIS" "$ENV{NSIS_DIR}")

FIND_PROGRAM(NSIS_EXECUTABLE
  NAMES
    makensis
  PATHS
    ${NSIS_ROOT_PATH}
    ${NSIS_ROOT_PATH}/Bin
    ${NSIS_ROOT_PATHS}
  DOC "makensis command line")

MARK_AS_ADVANCED(NSIS_EXECUTABLE)

IF(NSIS_EXECUTABLE)
  EXECUTE_PROCESS(COMMAND ${NSIS_EXECUTABLE} -version
    OUTPUT_VARIABLE NSIS_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  STRING(REGEX REPLACE ".*v([\\.0-9]+).*" "\\1" NSIS_VERSION "${NSIS_VERSION}")

  MESSAGE(STATUS "Found NSIS version ${NSIS_VERSION} in ${NSIS_EXECUTABLE}")

  SET(NSIS_FOUND ON)
ENDIF(NSIS_EXECUTABLE)

MACRO(ADD_NSIS_PACKAGE SCRIPT)
  SET(NSIS_OPTIONS "")
  FOREACH(arg ${ARGN})
    # Fix path for Windows
    STRING(REPLACE "/" "\\" arg ${arg})
    SET(NSIS_OPTIONS ${NSIS_OPTIONS} -D${arg})
  ENDFOREACH(arg)

  SET(NSIS_COMMANDS ${NSIS_COMMANDS} COMMAND ${NSIS_EXECUTABLE} ${NSIS_OPTIONS} ${SCRIPT})
  SET(NSIS_SOURCES ${NSIS_SOURCES} "${SCRIPT}")
ENDMACRO(ADD_NSIS_PACKAGE)

MACRO(MAKE_NSIS_TARGET)
  ADD_CUSTOM_TARGET(package ${NSIS_COMMANDS} SOURCES ${NSIS_SOURCES})

  SET_TARGET_LABEL(package "PACKAGE")
ENDMACRO(MAKE_NSIS_TARGET)
