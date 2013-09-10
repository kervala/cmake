# Look for a directory containing Scribb.
#
# The following values are defined
# SCRIBB_INCLUDE_DIR - where to find vector, etc.
# SCRIBB_LIBRARIES   - link against these to use Scribb
# SCRIBB_FOUND       - True if the Scribb is available.

# also defined, but not for general use are
IF(SCRIBB_LIBRARIES AND SCRIBB_INCLUDE_DIR)
  # in cache already
  SET(Scribb_FIND_QUIETLY TRUE)
ENDIF(SCRIBB_LIBRARIES AND SCRIBB_INCLUDE_DIR)

SET(DEFAULT_PATHS
  /usr/local/lib
  /usr/lib
  /sw/lib
  /opt/local/lib
  /opt/csw/lib
  /opt/lib
  /usr/freeware/lib64)

FIND_PATH(SCRIBB_ROOT_DIR
  lib_soap_ident_client.h
  PATHS
  /usr/local/include
  /usr/include
  /sw/include
  /opt/local/include
  /opt/csw/include
  /opt/include
  PATH_SUFFIXES
  include/scribb
)

FIND_PATH(SCRIBB_INCLUDE_DIR
  lib_soap_ident_client.h
  PATHS
  ${SCRIBB_ROOT_DIR}/include
  /usr/local/include
  /usr/include
  /sw/include
  /opt/local/include
  /opt/csw/include
  /opt/include
  PATH_SUFFIXES
  scribb
)

MACRO(FIND_RELEASE_DEBUG_LIBRARIES name filename path)
  SET(DEFAULT_PATHS
    /usr/local/lib
    /usr/lib
    /sw/lib
    /opt/local/lib
    /opt/csw/lib
    /opt/lib
    /usr/freeware/lib64)

  FIND_LIBRARY(${name}_LIBRARY_DEBUG NAMES ${filename}d PATHS ${path}/lib)
  FIND_LIBRARY(${name}_LIBRARY_RELEASE NAMES ${filename} PATHS ${path}/lib)
  
  IF(${name}_LIBRARY_RELEASE)
    IF(${name}_LIBRARY_DEBUG)
      SET(${name}_LIBRARIES optimized ${${name}_LIBRARY_RELEASE} debug ${${name}_LIBRARY_DEBUG} CACHE PATH "" FORCE)
    ELSE(${name}_LIBRARY_DEBUG)
      SET(${name}_LIBRARIES ${${name}_LIBRARY_RELEASE} CACHE PATH "" FORCE)
    ENDIF(${name}_LIBRARY_DEBUG)
    LIST(APPEND SCRIBB_LIBRARIES ${${name}_LIBRARIES})
  ELSE(${name}_LIBRARY_RELEASE)
    SET(SCRIBB_FOUND FALSE)
  ENDIF(${name}_LIBRARY_RELEASE)
  
ENDMACRO(FIND_RELEASE_DEBUG_LIBRARIES)

SET(SCRIBB_FOUND TRUE)
SET(SCRIBB_LIBRARIES)

FIND_RELEASE_DEBUG_LIBRARIES(SCRIBB_IDENT identclient ${SCRIBB_ROOT_DIR})
FIND_RELEASE_DEBUG_LIBRARIES(SCRIBB_POOL poolclient ${SCRIBB_ROOT_DIR})
FIND_RELEASE_DEBUG_LIBRARIES(SCRIBB_FORM formclient ${SCRIBB_ROOT_DIR})
FIND_RELEASE_DEBUG_LIBRARIES(SCRIBB_DOCUMENT documentclient ${SCRIBB_ROOT_DIR})
FIND_RELEASE_DEBUG_LIBRARIES(SCRIBB_ACTION actionclient ${SCRIBB_ROOT_DIR})
FIND_RELEASE_DEBUG_LIBRARIES(SCRIBB_HWR hwrclient ${SCRIBB_ROOT_DIR})

IF(SCRIBB_INCLUDE_DIR)
  IF(SCRIBB_LIBRARY_RELEASE)
    SET(SCRIBB_FOUND TRUE)

    SET(SCRIBB_LIBRARIES "optimized;${SCRIBB_LIBRARY_RELEASE}")
    IF(SCRIBB_LIBRARY_DEBUG)
      SET(SCRIBB_LIBRARIES "${SCRIBB_LIBRARIES};debug;${SCRIBB_LIBRARY_DEBUG}")
    ENDIF(SCRIBB_LIBRARY_DEBUG)
  ENDIF(SCRIBB_LIBRARY_RELEASE)
ENDIF(SCRIBB_INCLUDE_DIR)

IF(SCRIBB_FOUND)
  IF(NOT SCRIBB_FIND_QUIETLY)
    MESSAGE(STATUS "Found Scribb: ${SCRIBB_LIBRARIES}")
  ENDIF(NOT SCRIBB_FIND_QUIETLY)
ELSE(SCRIBB_FOUND)
  IF(NOT SCRIBB_FIND_QUIETLY)
    MESSAGE(STATUS "Warning: Unable to find Scribb!")
  ENDIF(NOT SCRIBB_FIND_QUIETLY)
ENDIF(SCRIBB_FOUND)

MARK_AS_ADVANCED(SCRIBB_LIBRARY_RELEASE SCRIBB_LIBRARY_DEBUG)
