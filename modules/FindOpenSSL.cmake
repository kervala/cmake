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

SET(Crypto_FIND_REQUIRED ${OpenSSL_FIND_REQUIRED})
SET(SSL_FIND_REQUIRED ${OpenSSL_FIND_REQUIRED})

FIND_PACKAGE_HELPER(Crypto openssl/ssl.h RELEASE libeay32 DEBUG libeay32d QUIET)
FIND_PACKAGE_HELPER(SSL openssl/ssl.h RELEASE ssleay32 DEBUG ssleay32d QUIET)

function(from_hex HEX DEC)
  string(TOUPPER "${HEX}" HEX)
  set(_res 0)
  string(LENGTH "${HEX}" _strlen)

  while (_strlen GREATER 0)
    math(EXPR _res "${_res} * 16")
    string(SUBSTRING "${HEX}" 0 1 NIBBLE)
    string(LENGTH "${HEX}" LEN)
    math(EXPR LEN "${LEN} - 1")
    string(SUBSTRING "${HEX}" 1 ${LEN} HEX)
    if (NIBBLE STREQUAL "A")
      math(EXPR _res "${_res} + 10")
    elseif (NIBBLE STREQUAL "B")
      math(EXPR _res "${_res} + 11")
    elseif (NIBBLE STREQUAL "C")
      math(EXPR _res "${_res} + 12")
    elseif (NIBBLE STREQUAL "D")
      math(EXPR _res "${_res} + 13")
    elseif (NIBBLE STREQUAL "E")
      math(EXPR _res "${_res} + 14")
    elseif (NIBBLE STREQUAL "F")
      math(EXPR _res "${_res} + 15")
    else(NIBBLE STREQUAL "A")
      math(EXPR _res "${_res} + ${NIBBLE}")
    endif(NIBBLE STREQUAL "A")

    string(LENGTH "${HEX}" _strlen)
  endwhile(_strlen GREATER 0)

  set(${DEC} ${_res} PARENT_SCOPE)
endfunction(from_hex)

IF(CRYPTO_FOUND AND SSL_FOUND)
  SET(OPENSSL_FOUND ON)
  SET(OPENSSL_INCLUDE_DIR ${CRYPTO_INCLUDE_DIR})
  SET(OPENSSL_INCLUDE_DIRS ${OPENSSL_INCLUDE_DIR})
  SET(OPENSSL_LIBRARIES ${SSL_LIBRARIES} ${CRYPTO_LIBRARIES})

  IF(WITH_STATIC_EXTERNAL)
    FIND_PACKAGE(MyZLIB)
    SET(OPENSSL_LIBRARIES ${OPENSSL_LIBRARIES} ${ZLIB_LIBRARIES} ${CMAKE_DL_LIBS})
  ENDIF()

  IF(WIN32)
    SET(OPENSSL_LIBRARIES ${OPENSSL_LIBRARIES} Crypt32)
  ENDIF()
  
  IF(OPENSSL_INCLUDE_DIR AND EXISTS "${OPENSSL_INCLUDE_DIR}/openssl/opensslv.h")
    file(STRINGS "${OPENSSL_INCLUDE_DIR}/openssl/opensslv.h" openssl_version_str
         REGEX "^#[\t ]*define[\t ]+OPENSSL_VERSION_NUMBER[\t ]+0x([0-9a-fA-F])+.*")

    # The version number is encoded as 0xMNNFFPPS: major minor fix patch status
    # The status gives if this is a developer or prerelease and is ignored here.
    # Major, minor, and fix directly translate into the version numbers shown in
    # the string. The patch field translates to the single character suffix that
    # indicates the bug fix state, which 00 -> nothing, 01 -> a, 02 -> b and so
    # on.

    string(REGEX REPLACE "^.*OPENSSL_VERSION_NUMBER[\t ]+0x([0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F]).*$"
           "\\1;\\2;\\3;\\4;\\5" OPENSSL_VERSION_LIST "${openssl_version_str}")
    list(GET OPENSSL_VERSION_LIST 0 OPENSSL_VERSION_MAJOR)
    list(GET OPENSSL_VERSION_LIST 1 OPENSSL_VERSION_MINOR)
    from_hex("${OPENSSL_VERSION_MINOR}" OPENSSL_VERSION_MINOR)
    list(GET OPENSSL_VERSION_LIST 2 OPENSSL_VERSION_FIX)
    from_hex("${OPENSSL_VERSION_FIX}" OPENSSL_VERSION_FIX)
    list(GET OPENSSL_VERSION_LIST 3 OPENSSL_VERSION_PATCH)

    if (NOT OPENSSL_VERSION_PATCH STREQUAL "00")
      from_hex("${OPENSSL_VERSION_PATCH}" _tmp)
      # 96 is the ASCII code of 'a' minus 1
      math(EXPR OPENSSL_VERSION_PATCH_ASCII "${_tmp} + 96")
      unset(_tmp)
      # Once anyone knows how OpenSSL would call the patch versions beyond 'z'
      # this should be updated to handle that, too. This has not happened yet
      # so it is simply ignored here for now.
      string(ASCII "${OPENSSL_VERSION_PATCH_ASCII}" OPENSSL_VERSION_PATCH_STRING)
    endif()

    SET(OPENSSL_VERSION "${OPENSSL_VERSION_MAJOR}.${OPENSSL_VERSION_MINOR}.${OPENSSL_VERSION_FIX}${OPENSSL_VERSION_PATCH_STRING}")
  ENDIF()

  MESSAGE_VERSION_PACKAGE_HELPER(OpenSSL ${OPENSSL_VERSION} ${OPENSSL_LIBRARIES})
ENDIF()

MARK_AS_ADVANCED(CRYPTO_INCLUDE_DIR SSL_INCLUDE_DIR)
