FIND_PACKAGE(ZLIB REQUIRED)

IF(ZLIB_FOUND)
  FIND_PACKAGE_HELPER(PNG png.h "png libpng png15 libpng15 png14 libpng14 png12 libpng12" "pngd libpngd png15d libpng15d png14d libpng14d png12d libpng12d")

  IF(PNG_FOUND)
    # png.h includes zlib.h. Sigh.
    SET(PNG_INCLUDE_DIRS ${PNG_PNG_INCLUDE_DIR} ${ZLIB_INCLUDE_DIR})
    SET(PNG_LIBRARIES ${PNG_LIBRARY} ${ZLIB_LIBRARIES})

    IF(CYGWIN)
      IF(BUILD_SHARED_LIBS)
        # No need to define PNG_USE_DLL here, because it's default for Cygwin.
      ELSE(BUILD_SHARED_LIBS)
        SET(PNG_DEFINITIONS -DPNG_STATIC)
      ENDIF(BUILD_SHARED_LIBS)
    ENDIF(CYGWIN)
  ENDIF(PNG_FOUND)
ENDIF(ZLIB_FOUND)
