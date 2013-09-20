# OUTPUT_DIR
# CONTENTS_DIR
# RESOURCES_DIR
# MAC_RESOURCES_DIR
# MAC_LANGS

MACRO(SIGN_FILE_MAC _TARGET)
  IF(IOS)
    IF(NOT IOS_DEVELOPER)
      SET(IOS_DEVELOPER "iPhone Developer")
    ENDIF(NOT IOS_DEVELOPER)
    IF(NOT IOS_DISTRIBUTION)
      SET(IOS_DISTRIBUTION "${IOS_DEVELOPER}")
    ENDIF(NOT IOS_DISTRIBUTION)
    SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES
      XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY[variant=Debug] ${IOS_DEVELOPER}
      XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY[variant=Release] ${IOS_DISTRIBUTION}
      XCODE_ATTRIBUTE_INSTALL_PATH "$(LOCAL_APPS_DIR)"
      XCODE_ATTRIBUTE_INSTALL_PATH_VALIDATE_PRODUCT "YES"
      XCODE_ATTRIBUTE_COMBINE_HIDPI_IMAGES "NO")
  ELSE(IOS)
#   SET_TARGET_PROPERTIES(${target} PROPERTIES
#     XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Mac Developer")
  ENDIF(IOS)
ENDMACRO(SIGN_FILE_MAC)

MACRO(INIT_MAC)
  SET(MAC_LANGS)
  SET(MAC_RESOURCES_fr)
  SET(MAC_RESOURCES_en)
  SET(MAC_RESOURCES_de)
  SET(MAC_RESOURCES_NEUTRAL)
  SET(MAC_FRAMEWORKS)
  SET(MAC_XIBS)
  SET(MAC_STRINGS)
  SET(MAC_ICNSS)
  SET(MAC_INFO_PLIST)
  SET(MAC_ITUNESARTWORK)
  
  # Regex filter for Mac files
  SET(MAC_FILES_FILTER "(\\.(xib|strings|icns|plist|framework)|iTunesArtwork\\.png)$")
ENDMACRO(INIT_MAC)

MACRO(FILTER_MAC_FILES FILE)
  IF(APPLE)
    IF(${FILE} MATCHES "\\.xib$")
      LIST(APPEND MAC_XIBS ${FILE})
      IF(NOT XCODE)
        # Don't include XIB with makefiles because we only need NIB
        SET(_INCLUDE OFF)
      ENDIF(NOT XCODE)
    ELSEIF(${FILE} MATCHES "\\.strings$")
      LIST(APPEND _STRINGS ${FILE})
    ELSEIF(${FILE} MATCHES "iTunesArtwork\\.png$")
        # Don't include iTunesArtwork because it'll be copied in IPA
        SET(_INCLUDE OFF)
        SET(MAC_ITUNESARTWORK ${FILE})
    ELSEIF(${FILE} MATCHES "\\.icns$")
      LIST(APPEND MAC_ICNSS ${FILE})
    ELSEIF(${FILE} MATCHES "Info([a-z0-9_-]*)\\.plist$")
      # Don't include Info.plist because it'll be generated
      LIST(APPEND MAC_INFO_PLIST ${FILE})
      SET(_INCLUDE OFF)
    ELSEIF(${FILE} MATCHES "\\.framework$")
      LIST(APPEND MAC_FRAMEWORKS ${FILE})
      SET(_INCLUDE OFF)
    ENDIF(${FILE} MATCHES "\\.xib$")

    IF(${FILE} MATCHES "/([a-z]+)\\.lproj/")
      # Extract ISO code for language from source directory
      STRING(REGEX REPLACE "^.*/([a-z]+)\\.lproj/.*$" "\\1" _LANG ${FILE})

      # Append new language if not already in the list
      LIST(FIND MAC_LANGS "${_LANG}" _INDEX)
      IF(_INDEX EQUAL -1)
        LIST(APPEND MAC_LANGS ${_LANG})
      ENDIF(_INDEX EQUAL -1)

      # Append file to localized resources list
      LIST(APPEND MAC_RESOURCES_${_LANG} ${FILE})
    ELSE(${FILE} MATCHES "/([a-z]+)\\.lproj/")
      # Append file to neutral resources list
      IF(_INCLUDE)
        LIST(APPEND MAC_RESOURCES_NEUTRAL ${FILE})
      ENDIF(_INCLUDE)
    ENDIF(${FILE} MATCHES "/([a-z]+)\\.lproj/")
  ENDIF(APPLE)
ENDMACRO(FILTER_MAC_FILES)

MACRO(INIT_BUNDLE _TARGET)
    IF(XCODE)
      SET(OUTPUT_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$(CONFIGURATION)/${PRODUCT_FIXED}.app)
    ELSE(XCODE)
      SET(OUTPUT_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PRODUCT_FIXED}.app)
    ENDIF(XCODE)

    IF(NOT IOS)
      SET(_SUBDIR "mac")
      SET(CONTENTS_DIR ${OUTPUT_DIR}/Contents)
      SET(RESOURCES_DIR ${CONTENTS_DIR}/Resources)
    ELSE(NOT IOS)
      SET(_SUBDIR "ios")
      SET(CONTENTS_DIR ${OUTPUT_DIR})
      SET(RESOURCES_DIR ${CONTENTS_DIR})
    ENDIF(NOT IOS)

    IF(NOT MAC_RESOURCES_DIR)
      FOREACH(ITEM ${CMAKE_MODULE_PATH})
        IF(EXISTS "${ITEM}/${_SUBDIR}/Info.plist")
          SET(MAC_RESOURCES_DIR "${ITEM}/${_SUBDIR}")
          BREAK()
        ENDIF(EXISTS "${ITEM}/${_SUBDIR}/Info.plist")
      ENDFOREACH(ITEM)
    ENDIF(NOT MAC_RESOURCES_DIR)

    IF(NOT MACOSX_BUNDLE_INFO_STRING)
      SET(MACOSX_BUNDLE_INFO_STRING ${PRODUCT})
    ENDIF(NOT MACOSX_BUNDLE_INFO_STRING)

    IF(NOT MACOSX_BUNDLE_LONG_VERSION_STRING)
      SET(MACOSX_BUNDLE_LONG_VERSION_STRING "${PRODUCT} version ${VERSION}")
    ENDIF(NOT MACOSX_BUNDLE_LONG_VERSION_STRING)

    IF(NOT MACOSX_BUNDLE_BUNDLE_NAME)
      SET(MACOSX_BUNDLE_BUNDLE_NAME ${PRODUCT})
    ENDIF(NOT MACOSX_BUNDLE_BUNDLE_NAME)

    IF(NOT MACOSX_BUNDLE_SHORT_VERSION_STRING)
      SET(MACOSX_BUNDLE_SHORT_VERSION_STRING ${VERSION})
    ENDIF(NOT MACOSX_BUNDLE_SHORT_VERSION_STRING)

    IF(NOT MACOSX_BUNDLE_BUNDLE_VERSION)
      SET(MACOSX_BUNDLE_BUNDLE_VERSION ${VERSION})
    ENDIF(NOT MACOSX_BUNDLE_BUNDLE_VERSION)

    IF(NOT MACOSX_BUNDLE_COPYRIGHT)
      SET(MACOSX_BUNDLE_COPYRIGHT "Copyright ${YEAR} ${AUTHOR}")
    ENDIF(NOT MACOSX_BUNDLE_COPYRIGHT)

    # Make sure the 'Resources' Directory is correctly created before we build
    ADD_CUSTOM_COMMAND(TARGET ${_TARGET} PRE_BUILD COMMAND mkdir -p ${RESOURCES_DIR})
ENDMACRO(INIT_BUNDLE)

MACRO(SET_TARGET_FLAGS_XCODE _TARGET)
  IF(XCODE)
    IF(IOS AND IOS_VERSION)
      SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES
        XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET ${IOS_VERSION}
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
        XCODE_ATTRIBUTE_VALID_ARCHS "armv7") # armv6 armv7 armv7s
    ENDIF(IOS AND IOS_VERSION)

    IF(WITH_VISIBILITY_HIDDEN)
      SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES
        XCODE_ATTRIBUTE_GCC_SYMBOLS_PRIVATE_EXTERN YES
        XCODE_ATTRIBUTE_GCC_INLINES_ARE_PRIVATE_EXTERN YES)
    ENDIF(WITH_VISIBILITY_HIDDEN)

    IF(NOT WITH_EXCEPTIONS)
      SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES XCODE_ATTRIBUTE_GCC_ENABLE_CPP_EXCEPTIONS NO)
    ENDIF(NOT WITH_EXCEPTIONS)

    IF(NOT WITH_RTTI)
      SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES XCODE_ATTRIBUTE_GCC_ENABLE_CPP_RTTI NO)
    ENDIF(NOT WITH_RTTI)
  ENDIF(XCODE)
ENDMACRO(SET_TARGET_FLAGS_XCODE)

MACRO(INSTALL_MAC_RESOURCES _TARGET)
  # Copy all resources in Resources folder
  IF(MAC_RESOURCES_NEUTRAL)
    SOURCE_GROUP(Resources FILES ${MAC_RESOURCES_NEUTRAL})
    IF(XCODE)
      # Resources are copied by Xcode
      SET_SOURCE_FILES_PROPERTIES(${MAC_RESOURCES_NEUTRAL} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    ELSE(XCODE)
      # We need to copy resources manually
      FOREACH(_RES ${MAC_RESOURCES_NEUTRAL})
        ADD_CUSTOM_COMMAND(TARGET ${_TARGET} PRE_BUILD COMMAND cp ARGS ${_RES} ${RESOURCES_DIR})
      ENDFOREACH(_RES ${MAC_RESOURCES_NEUTRAL})
    ENDIF(XCODE)
  ENDIF(MAC_RESOURCES_NEUTRAL)

  IF(MAC_LANGS)
    FOREACH(_LANG ${MAC_LANGS})
      # Create the directory containing specific language resources
      ADD_CUSTOM_COMMAND(TARGET ${_TARGET} PRE_BUILD COMMAND mkdir -p ${RESOURCES_DIR}/${_LANG}.lproj)
      SOURCE_GROUP("Resources\\${_LANG}.lproj" FILES ${MAC_RESOURCES_${_LANG}})
      FOREACH(_RES ${MAC_RESOURCES_${_LANG}})
        # Copy only Localizable.strings because XIB need to be converted to NIB
        IF(_RES MATCHES "/Localizable.strings$")
          ADD_CUSTOM_COMMAND(TARGET ${_TARGET} PRE_BUILD COMMAND cp ARGS ${_RES} ${RESOURCES_DIR}/${_LANG}.lproj)
        ENDIF(_RES MATCHES "/Localizable.strings$")
      ENDFOREACH(_RES ${MAC_RESOURCES_${_LANG}})
    ENDFOREACH(_LANG ${MAC_LANGS})
  ENDIF(MAC_LANGS)

  # Set a custom plist file for the app bundle
  IF(MAC_RESOURCES_DIR)
    IF(NOT MAC_INFO_PLIST)
      SET(MAC_INFO_PLIST ${MAC_RESOURCES_DIR}/Info.plist)
    ENDIF(NOT MAC_INFO_PLIST)

    SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${MAC_INFO_PLIST})

    IF(NOT XCODE)
      ADD_CUSTOM_COMMAND(TARGET ${_TARGET} POST_BUILD COMMAND cp ARGS ${MAC_RESOURCES_DIR}/PkgInfo ${CONTENTS_DIR})
    ENDIF(NOT XCODE)
  ENDIF(MAC_RESOURCES_DIR)

  IF(MAC_ICNSS)
    # Copying all icons to bundle
    FOREACH(_ICNS ${MAC_ICNSS})
      # If target Mac OS X, use first icon for Bundle
      IF(NOT IOS AND NOT MACOSX_BUNDLE_ICON_FILE)
        GET_FILENAME_COMPONENT(_ICNS_NAME ${_ICNS} NAME)
        SET(MACOSX_BUNDLE_ICON_FILE ${_ICNS_NAME})
      ENDIF(NOT IOS AND NOT MACOSX_BUNDLE_ICON_FILE)
      IF(NOT XCODE)
        ADD_CUSTOM_COMMAND(TARGET ${_TARGET} POST_BUILD COMMAND cp ARGS ${_ICNS} ${RESOURCES_DIR})
      ENDIF(NOT XCODE)
    ENDFOREACH(_ICNS)
  ENDIF(MAC_ICNSS)

  IF(_MISCS AND NOT XCODE)
    # Copying all misc files to bundle
    FOREACH(_MISC ${_MISCS})
      ADD_CUSTOM_COMMAND(TARGET ${_TARGET} POST_BUILD COMMAND cp ARGS ${_MISC} ${RESOURCES_DIR})
    ENDFOREACH(_MISC)
  ENDIF(_MISCS AND NOT XCODE)
ENDMACRO(INSTALL_MAC_RESOURCES)

MACRO(COMPILE_MAC_XIBS _TARGET)
  # Compile the .xib files using the 'ibtool' program with the destination being the app package
  IF(MAC_XIBS)
    IF(NOT XCODE)
      # Make sure we can find the 'ibtool' program. If we can NOT find it we skip generation of this project
      FIND_PROGRAM(IBTOOL ibtool HINTS "/usr/bin" "${OSX_DEVELOPER_ROOT}/usr/bin" NO_CMAKE_FIND_ROOT_PATH)

      IF(${IBTOOL} STREQUAL "IBTOOL-NOTFOUND")
        MESSAGE(SEND_ERROR "ibtool can not be found and is needed to compile the .xib files. It should have been installed with the Apple developer tools. The default system paths were searched in addition to ${OSX_DEVELOPER_ROOT}/usr/bin")
      ENDIF(${IBTOOL} STREQUAL "IBTOOL-NOTFOUND")

      FOREACH(XIB ${MAC_XIBS})
        IF(XIB MATCHES "\\.lproj")
          STRING(REGEX REPLACE "^.*/(([a-z]+)\\.lproj/([a-zA-Z0-9_-]+))\\.xib$" "\\1.nib" NIB ${XIB})
        ELSE(XIB MATCHES "\\.lproj")
          STRING(REGEX REPLACE "^.*/([a-zA-Z0-9_-]+)\\.xib$" "\\1.nib" NIB ${XIB})
        ENDIF(XIB MATCHES "\\.lproj")
        GET_FILENAME_COMPONENT(NIB_OUTPUT_DIR ${RESOURCES_DIR}/${NIB} PATH)
        ADD_CUSTOM_COMMAND(TARGET ${_TARGET} POST_BUILD
          COMMAND ${IBTOOL} --errors --warnings --notices --output-format human-readable-text
            --compile ${RESOURCES_DIR}/${NIB}
            ${XIB}
            --sdk ${CMAKE_IOS_SDK_ROOT}
          COMMENT "Building XIB object ${NIB}")
      ENDFOREACH(XIB)
    ENDIF(NOT XCODE)
  ENDIF(MAC_XIBS)
ENDMACRO(COMPILE_MAC_XIBS)

MACRO(FIX_IOS_BUNDLE _TARGET)
  # Fixing Bundle files for iOS
  IF(IOS)
    ADD_CUSTOM_COMMAND(TARGET ${_TARGET} POST_BUILD
      COMMAND mv ${OUTPUT_DIR}/Contents/MacOS/* ${OUTPUT_DIR}
      COMMAND mv ${OUTPUT_DIR}/Contents/Info.plist ${OUTPUT_DIR}
      COMMAND rm -rf ${OUTPUT_DIR}/Contents)

    # Adding other needed files
    ADD_CUSTOM_COMMAND(TARGET ${_TARGET} POST_BUILD
      COMMAND cp ARGS ${CMAKE_IOS_SDK_ROOT}/ResourceRules.plist ${CONTENTS_DIR})
  ENDIF(IOS)
ENDMACRO(FIX_IOS_BUNDLE)

MACRO(CREATE_IOS_PACKAGE_TARGET _TARGET)
  IF(IOS)
    # Creating .ipa package
    IF(MAC_ITUNESARTWORK)
      CONFIGURE_FILE(${MAC_RESOURCES_DIR}/application.xcent ${CMAKE_BINARY_DIR}/application.xcent)

      SET(IPA_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PRODUCT_FIXED}_ipa)
      SET(IPA ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PRODUCT_FIXED}-${VERSION}.ipa)

      ADD_CUSTOM_TARGET(package
        COMMAND rm -rf "${OUTPUT_DIR}/Contents"
        COMMAND mkdir -p "${IPA_DIR}/Payload"
        COMMAND strip "${CONTENTS_DIR}/${PRODUCT_FIXED}"
        COMMAND security unlock-keychain -p "${KEYCHAIN_PASSWORD}"
        COMMAND CODESIGN_ALLOCATE=${CMAKE_IOS_DEVELOPER_ROOT}/usr/bin/codesign_allocate codesign -fs "${IOS_DISTRIBUTION}" "--resource-rules=${CONTENTS_DIR}/ResourceRules.plist" --entitlements "${CMAKE_BINARY_DIR}/application.xcent" "${CONTENTS_DIR}"
        COMMAND cp -R "${OUTPUT_DIR}" "${IPA_DIR}/Payload"
        COMMAND cp "${MAC_ITUNESARTWORK}" "${IPA_DIR}/iTunesArtwork"
        COMMAND ditto -c -k "${IPA_DIR}" "${IPA}"
        COMMAND rm -rf "${IPA_DIR}"
        COMMENT "Creating IPA archive..."
        SOURCES ${MAC_ITUNESARTWORK}
        VERBATIM)
      ADD_DEPENDENCIES(package ${_TARGET})
      SET_TARGET_LABEL(package "PACKAGE")
    ENDIF(MAC_ITUNESARTWORK)
  ENDIF(IOS)
ENDMACRO(CREATE_IOS_PACKAGE_TARGET)

MACRO(CREATE_IOS_RUN_TARGET _TARGET)
  IF(IOS AND NOT IOS_PLATFORM STREQUAL "OS")
    SET(IOS_SIMULATOR "${CMAKE_IOS_DEVELOPER_ROOT}/Applications/iPhone Simulator.app/Contents/MacOS/iPhone Simulator")
    IF(EXISTS ${IOS_SIMULATOR})
      ADD_CUSTOM_TARGET(run
        COMMAND rm -rf ${OUTPUT_DIR}/Contents
        COMMAND ${IOS_SIMULATOR} -SimulateApplication ${OUTPUT_DIR}/${PRODUCT_FIXED}
        COMMENT "Launching iOS simulator...")
      ADD_DEPENDENCIES(run ${_TARGET})
      SET_TARGET_LABEL(run "RUN")
    ENDIF(EXISTS ${IOS_SIMULATOR})
  ENDIF(IOS AND NOT IOS_PLATFORM STREQUAL "OS")
ENDMACRO(CREATE_IOS_RUN_TARGET)
