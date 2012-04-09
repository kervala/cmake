IF(CRYPTO_DIR)
  SET(BOOSTCRYPTO_DIR ${CRYPTO_DIR})
ENDIF(CRYPTO_DIR)

FIND_PACKAGE_HELPER(BoostCrypto crypto/md5.hpp boost_crypto boost_cryptod)
