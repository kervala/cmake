FIND_PACKAGE_HELPER(X264 x264.h QUIET)

IF(X264_FOUND)
  PARSE_VERSION_OTHER(${X264_INCLUDE_DIR}/x264_config.h X264_POINTVER)

  SET(X264_VERSION "${X264_POINTVER}")

  PARSE_VERSION_STRING(${X264_VERSION} X264_VERSION_MAJOR X264_VERSION_MINOR X264_VERSION_PATCH)

  MESSAGE_VERSION_PACKAGE_HELPER(X264 ${X264_VERSION} ${X264_LIBRARIES})
ENDIF()
