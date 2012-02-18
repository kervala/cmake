# - Locate ATL libraries
# This module defines
#  ATL_FOUND, if false, do not try to link to ATL
#  ATL_LIBRARY_DIR, where to find libraries
#  ATL_INCLUDE_DIR, where to find headers

SET(CUSTOM_ATL_DIR FALSE)

# If using STLport and ATL have been found, remember its directory
IF(WITH_STLPORT AND ATL_FOUND AND VC_DIR)
  SET(ATL_STANDARD_DIR "${VC_DIR}/atlmfc")
ENDIF(WITH_STLPORT AND ATL_FOUND AND VC_DIR)

# If using STLport or ATL haven't been found, search for afxwin.h
IF(WITH_STLPORT OR NOT ATL_FOUND)
  FIND_PATH(ATL_DIR
    include/atlbase.h
    PATHS
    ${ATL_STANDARD_DIR}
  )

  IF(ATL_FIND_REQUIRED)
    SET(ATL_FIND_REQUIRED TRUE)
  ENDIF(ATL_FIND_REQUIRED)

  # Display an error message if ATL are not found, ATL_FOUND is updated
  # User will be able to update ATL_DIR to the correct directory
  INCLUDE(FindPackageHandleStandardArgs)
  FIND_PACKAGE_HANDLE_STANDARD_ARGS(ATL DEFAULT_MSG ATL_DIR)

  IF(ATL_FOUND)
    SET(ATL_INCLUDE_DIR "${ATL_DIR}/include")
    INCLUDE_DIRECTORIES(${ATL_INCLUDE_DIR})
  ENDIF(ATL_FOUND)
ENDIF(WITH_STLPORT OR NOT ATL_FOUND)

# Only if using a custom path
IF(ATL_DIR)
  # Using 32 or 64 bits libraries
  IF(TARGET_X64)
    SET(ATL_LIBRARY_DIR "${ATL_DIR}/lib/amd64")
  ELSE(TARGET_X64)
    SET(ATL_LIBRARY_DIR "${ATL_DIR}/lib")
  ENDIF(TARGET_X64)

  # Add ATL libraries directory to default library path
  LINK_DIRECTORIES(${ATL_LIBRARY_DIR})
ENDIF(ATL_DIR)

IF(ATL_FOUND)
  # Set definitions for using ATL in DLL
#  SET(ATL_DEFINITIONS -D_AFXDLL)
ENDIF(ATL_FOUND)

# TODO: create a macro which set ATL_DEFINITIONS, ATL_LIBRARY_DIR and ATL_INCLUDE_DIR for a project
