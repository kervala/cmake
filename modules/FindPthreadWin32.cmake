#
#  CMake custom modules
#  Copyright (C) 2011-2015  Cedric OCHS
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

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
