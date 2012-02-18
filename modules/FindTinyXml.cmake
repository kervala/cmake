FIND_PACKAGE_HELPER(TinyXml tinyxml.h "tinyxmlstl tinyxml" "tinyxmlstld tinyxmld")

IF(TINYXML_FOUND)
  SET(TINYXML_DEFINITIONS "-DTIXML_USE_STL")
ENDIF(TINYXML_FOUND)
