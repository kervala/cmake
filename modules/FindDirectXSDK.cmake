# - Find DirectX
# Find the DirectX includes and libraries
#
#  DXSDK_INCLUDE_DIR - where to find baseinterface.h
#  DXSDK_LIBRARIES   - List of libraries when using 3DSMAX.
#  DXSDK_FOUND       - True if MAX SDK found.

IF(DXSDK_DIR)
    # Already in cache, be silent
    SET(DXSDK_FIND_QUIETLY TRUE)
ENDIF(DXSDK_DIR)

FIND_PATH(DXSDK_DIR
  "Include/dxsdkver.h"
  PATHS
  "$ENV{DXSDK_DIR}"
  "C:/Program Files (x86)/Microsoft DirectX SDK (June 2010)"
  "C:/Program Files/Microsoft DirectX SDK (June 2010)"
  "C:/Program Files (x86)/Microsoft DirectX SDK (February 2010)"
  "C:/Program Files/Microsoft DirectX SDK (February 2010)"
  "C:/Program Files (x86)/Microsoft DirectX SDK (November 2007)"
  "C:/Program Files/Microsoft DirectX SDK (November 2007)"
  "C:/Program Files (x86)/Microsoft DirectX SDK"
  "C:/Program Files/Microsoft DirectX SDK"
)

MACRO(FIND_DXSDK_LIBRARY MYLIBRARY MYLIBRARYNAME)        
  FIND_LIBRARY(${MYLIBRARY}
               NAMES ${MYLIBRARYNAME}
               PATHS
               "${DXSDK_LIBRARY_DIR}"
               )
ENDMACRO(FIND_DXSDK_LIBRARY MYLIBRARY MYLIBRARYNAME)

IF(DXSDK_DIR)
  SET(DXSDK_INCLUDE_DIR "${DXSDK_DIR}/Include")

  IF(TARGET_X64)
    SET(DXSDK_LIBRARY_DIR "${DXSDK_DIR}/Lib/x64")
  ELSE(TARGET_X64)
    SET(DXSDK_LIBRARY_DIR "${DXSDK_DIR}/Lib/x86")
  ENDIF(TARGET_X64)

  FIND_DXSDK_LIBRARY(DXSDK_GUID_LIBRARY dxguid)
  FIND_DXSDK_LIBRARY(DXSDK_DINPUT_LIBRARY dinput8)
  FIND_DXSDK_LIBRARY(DXSDK_DSOUND_LIBRARY dsound)
  FIND_DXSDK_LIBRARY(DXSDK_XAUDIO_LIBRARY x3daudio)
  FIND_DXSDK_LIBRARY(DXSDK_D3DX9_LIBRARY d3dx9)
  FIND_DXSDK_LIBRARY(DXSDK_D3D9_LIBRARY d3d9)

  #FIND_DXSDK_LIBRARY(DXSDK_MESH_LIBRARY mesh)
  #FIND_DXSDK_LIBRARY(DXSDK_MAXUTIL_LIBRARY maxutil)
  #FIND_DXSDK_LIBRARY(DXSDK_MAXSCRIPT_LIBRARY maxscrpt)
  #FIND_DXSDK_LIBRARY(DXSDK_PARAMBLK2_LIBRARY paramblk2)
  #FIND_DXSDK_LIBRARY(DXSDK_BMM_LIBRARY bmm)
ENDIF(DXSDK_DIR)

# Handle the QUIETLY and REQUIRED arguments and set DXSDK_FOUND to TRUE if
# all listed variables are TRUE.
INCLUDE(FindPackageHandleStandardArgs)

FIND_PACKAGE_HANDLE_STANDARD_ARGS(DirectXSDK DEFAULT_MSG DXSDK_DIR DXSDK_GUID_LIBRARY DXSDK_DINPUT_LIBRARY)

MARK_AS_ADVANCED(DXSDK_INCLUDE_DIR
  DXSDK_GUID_LIBRARY
  DXSDK_DINPUT_LIBRARY
  DXSDK_DSOUND_LIBRARY
  DXSDK_XAUDIO_LIBRARY
  DXSDK_D3DX9_LIBRARY
  DXSDK_D3D9_LIBRARY)
