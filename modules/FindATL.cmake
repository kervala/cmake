# - Locate ATL libraries
# This module defines
#  ATL_FOUND, if false, do not try to link to ATL
#  ATL_LIBRARY_DIR, where to find libraries
#  ATL_INCLUDE_DIR, where to find headers

IF(NOT ATL_DIR)
  # If ATL has been found, remember their directory
  IF(VC_DIR)
    SET(ATL_STANDARD_DIR "${VC_DIR}/atlmfc")
  ENDIF(VC_DIR)

  FIND_PATH(ATL_DIR
    include/atlbase.h
    HINTS
    ${ATL_STANDARD_DIR}
  )
ENDIF(NOT ATL_DIR)

# Display an error message if ATL are not found, ATL_FOUND is updated
# User will be able to update ATL_DIR to the correct directory
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(ATL DEFAULT_MSG ATL_DIR)

IF(ATL_FOUND)
  SET(ATL_INCLUDE_DIR "${ATL_DIR}/include")
  INCLUDE_DIRECTORIES(${ATL_INCLUDE_DIR})

  # Using 32 or 64 bits libraries
  IF(TARGET_X64)
    SET(ATL_LIBRARY_DIR "${ATL_DIR}/lib/amd64")
  ELSE(TARGET_X64)
    SET(ATL_LIBRARY_DIR "${ATL_DIR}/lib")
  ENDIF(TARGET_X64)

  # Add ATL libraries directory to default library path
  LINK_DIRECTORIES(${ATL_LIBRARY_DIR})
ENDIF(ATL_FOUND)

# TODO: create a macro which set MFC_DEFINITIONS, MFC_LIBRARY_DIR and MFC_INCLUDE_DIR for a project
