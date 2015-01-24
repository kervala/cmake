FIND_PACKAGE_HELPER(PthreadWin32 pthread.h RELEASE pthreadVSE2 DEBUG pthreadVSE2d QUIET)

IF(PTHREADWIN32_FOUND)
  FILE(STRINGS "${PTHREADWIN32_INCLUDE_DIR}/pthread.h" PTHREAD_VERSION_STR
    REGEX "^#define[\t ]+PTW32_VERSION[\t ]+([0-9,])+.*")

  STRING(REGEX REPLACE "^.*PTW32_VERSION[\t ]+([0-9]+),([0-9]+),([0-9]+).*$"
    "\\1;\\2;\\3" PTHREAD_VERSION_LIST "${PTHREAD_VERSION_STR}")
  list(GET PTHREAD_VERSION_LIST 0 PTHREADWIN32_VERSION_MAJOR)
  list(GET PTHREAD_VERSION_LIST 1 PTHREADWIN32_VERSION_MINOR)
  list(GET PTHREAD_VERSION_LIST 2 PTHREADWIN32_VERSION_PATCH)
  
  SET(PTHREADWIN32_VERSION "${PTHREADWIN32_VERSION_MAJOR}.${PTHREADWIN32_VERSION_MINOR}.${PTHREADWIN32_VERSION_PATCH}")

  MESSAGE_VERSION_PACKAGE_HELPER(PthreadWin32 ${PTHREADWIN32_VERSION} ${PTHREADWIN32_LIBRARIES})
ENDIF()

MARK_AS_ADVANCED(CRYPTO_INCLUDE_DIR SSL_INCLUDE_DIR)