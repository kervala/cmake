FIND_PACKAGE_HELPER(Neolib NeoLib.h QUIET)

IF(NEOLIB_FOUND)
  SET(NEOLIB_DEFINITIONS "-DSERIALISATION_USE_BOOST_SHARED")

  IF(WIN32)
    SET(Boost_USE_STATIC_LIBS ON)
    SET(Boost_USE_MULTITHREADED ON)
    SET(Boost_USE_STATIC_RUNTIME OFF)
  ENDIF(WIN32)

  FIND_PACKAGE(Boost 1.42 COMPONENTS date_time filesystem system thread)

  IF(Boost_FOUND)
    SET(NEOLIB_INCLUDE_DIRS ${NEOLIB_INCLUDE_DIRS} ${Boost_INCLUDE_DIR})
    SET(NEOLIB_LIBRARIES ${NEOLIB_LIBRARIES} ${Boost_LIBRARIES})
  ENDIF(Boost_FOUND)

  FIND_PACKAGE(OpenSSL)

  IF(OPENSSL_FOUND)
    SET(NEOLIB_INCLUDE_DIRS ${NEOLIB_INCLUDE_DIRS} ${OPENSSL_INCLUDE_DIR})
    SET(NEOLIB_LIBRARIES ${NEOLIB_LIBRARIES} ${OPENSSL_LIBRARIES})
  ENDIF(OPENSSL_FOUND)

  IF(WIN32)
    SET(NEOLIB_LIBRARIES ${NEOLIB_LIBRARIES} Ws2_32)
  ENDIF(WIN32)

  PARSE_VERSION_OTHER(${NEOLIB_INCLUDE_DIR}/NeoLib.h NEOLIB_VERSION_MAJOR NEOLIB_VERSION_MINOR NEOLIB_VERSION_PATCH)
  SET(NEOLIB_VERSION "${NEOLIB_VERSION_MAJOR}.${NEOLIB_VERSION_MINOR}.${NEOLIB_VERSION_PATCH}")

  MESSAGE_VERSION_PACKAGE_HELPER(Neolib ${NEOLIB_VERSION} ${NEOLIB_LIBRARIES})
ENDIF(NEOLIB_FOUND)
