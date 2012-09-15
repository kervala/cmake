SET(COMMON_MODULE_FOUND TRUE)

# Force Release configuration for compiler checks
SET(CMAKE_TRY_COMPILE_CONFIGURATION "Release")

# Check .desktop file under Gnome
SET(DESKTOP_FILE $ENV{GIO_LAUNCHED_DESKTOP_FILE})

# Check build directory
IF(NOT DESKTOP_FILE)
  SET(DESKTOP_FILE ${CMAKE_BINARY_DIR})
ENDIF(NOT DESKTOP_FILE)

# Force Debug configuration if launched from Qt Creator
IF(NOT CMAKE_BUILD_TYPE AND DESKTOP_FILE MATCHES "qtcreator")
  SET(CMAKE_BUILD_TYPE "Debug" CACHE STRING "" FORCE)
ENDIF(NOT CMAKE_BUILD_TYPE AND DESKTOP_FILE MATCHES "qtcreator")

# Force Release configuration by default
IF(NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE "Release" CACHE STRING "" FORCE)
ENDIF(NOT CMAKE_BUILD_TYPE)

###
# Helper macro that generates .pc and installs it.
# Argument: name - the name of the .pc package, e.g. "mylib.pc"
###
MACRO(GEN_PKGCONFIG name)
  IF(NOT WIN32 AND WITH_INSTALL_LIBRARIES)
    CONFIGURE_FILE(${name}.in "${CMAKE_CURRENT_BINARY_DIR}/${name}")
    IF(CMAKE_LIBRARY_ARCHITECTURE)
      INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/${name}" DESTINATION lib/${CMAKE_LIBRARY_ARCHITECTURE}/pkgconfig)
    ELSE(CMAKE_LIBRARY_ARCHITECTURE)
      INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/${name}" DESTINATION lib/pkgconfig)
    ENDIF(CMAKE_LIBRARY_ARCHITECTURE)
  ENDIF(NOT WIN32 AND WITH_INSTALL_LIBRARIES)
ENDMACRO(GEN_PKGCONFIG)

###
# Helper macro that generates config.h from config.h.in or config.h.cmake
###
MACRO(GEN_CONFIG_H)
  IF(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/config.h.cmake)
    GEN_CONFIG_H_CUSTOM(${CMAKE_CURRENT_SOURCE_DIR}/config.h.cmake config.h)
  ELSEIF(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/config.h.in)
    GEN_CONFIG_H_CUSTOM(${CMAKE_CURRENT_SOURCE_DIR}/config.h.in config.h)
  ENDIF(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/config.h.cmake)
ENDMACRO(GEN_CONFIG_H)

MACRO(GEN_CONFIG_H_CUSTOM src dst)
  # convert relative to absolute paths
  IF(WIN32)
    IF(NOT TARGET_ICON)
      IF(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET}.ico)
        SET(TARGET_ICON "${CMAKE_CURRENT_SOURCE_DIR}/${TARGET}.ico")
      ELSEIF(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/icons/${TARGET}.ico)
        SET(TARGET_ICON "${CMAKE_CURRENT_SOURCE_DIR}/icons/${TARGET}.ico")
      ENDIF(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET}.ico)
    ENDIF(NOT TARGET_ICON)
  ENDIF(WIN32)

  CONFIGURE_FILE(${src} ${CMAKE_CURRENT_BINARY_DIR}/${dst})
  INCLUDE_DIRECTORIES(${CMAKE_CURRENT_BINARY_DIR})
  ADD_DEFINITIONS(-DHAVE_CONFIG_H)
ENDMACRO(GEN_CONFIG_H_CUSTOM)

MACRO(GEN_INIT_D name)
  IF(NOT WIN32)
    CONFIGURE_FILE("${CMAKE_CURRENT_SOURCE_DIR}/${name}.in" "${CMAKE_CURRENT_SOURCE_DIR}/${name}")
  ENDIF(NOT WIN32)
ENDMACRO(GEN_INIT_D)

###
# Helper macro that generates revision.h from revision.h.in
###
MACRO(GEN_REVISION_H)
  IF(EXISTS ${CMAKE_SOURCE_DIR}/revision.h.in)
    # Search GetRevision.cmake in each directory from CMAKE_MODULE_PATH
    FOREACH(ITEM ${CMAKE_MODULE_PATH})
      IF(EXISTS "${ITEM}/GetRevision.cmake")
        SET(GET_REVISION_DIR ${ITEM})
        MESSAGE(STATUS "Found GetRevision module in ${ITEM}")
        BREAK()
      ENDIF(EXISTS "${ITEM}/GetRevision.cmake")
    ENDFOREACH(ITEM)

    IF(EXISTS "${CMAKE_SOURCE_DIR}/.svn/")
      FIND_PACKAGE(Subversion)

      IF(NOT SUBVERSION_FOUND)
        SET(GET_REVISION_DIR 0)
      ENDIF(SUBVERSION_FOUND)
    ENDIF(EXISTS "${CMAKE_SOURCE_DIR}/.svn/")

    IF(EXISTS "${CMAKE_SOURCE_DIR}/.hg/")
      FIND_PACKAGE(Mercurial)

      IF(NOT MERCURIAL_FOUND)
        SET(GET_REVISION_DIR 0)
      ENDIF(NOT MERCURIAL_FOUND)
    ENDIF(EXISTS "${CMAKE_SOURCE_DIR}/.hg/")

    IF(GET_REVISION_DIR)
      INCLUDE_DIRECTORIES(${CMAKE_BINARY_DIR})
      ADD_DEFINITIONS(-DHAVE_REVISION_H)
      SET(HAVE_REVISION_H ON)

      # a custom target that is always built
      ADD_CUSTOM_TARGET(revision ALL)

      # creates revision.h using cmake script
      ADD_CUSTOM_COMMAND(TARGET revision
        PRE_BUILD
        COMMAND ${CMAKE_COMMAND}
        -DSOURCE_DIR=${CMAKE_SOURCE_DIR}
        -DCMAKE_MODULE_PATH="${CMAKE_MODULE_PATH}"
        -P ${GET_REVISION_DIR}/GetRevision.cmake)

      # revision.h is a generated file
      SET_SOURCE_FILES_PROPERTIES(${CMAKE_BINARY_DIR}/revision.h
        PROPERTIES GENERATED TRUE
        HEADER_FILE_ONLY TRUE)
    ENDIF(GET_REVISION_DIR)
  ENDIF(EXISTS ${CMAKE_SOURCE_DIR}/revision.h.in)
ENDMACRO(GEN_REVISION_H)

MACRO(PARSE_VERSION FILENAME VAR_MAJOR VAR_MINOR VAR_PATCH)
  IF(EXISTS ${FILENAME})
    FILE(STRINGS ${FILENAME} VERSION_MAJOR REGEX "^#define ${VAR_MAJOR} ([0-9]+)$")
    FILE(STRINGS ${FILENAME} VERSION_MINOR REGEX "^#define ${VAR_MINOR} ([0-9]+)$")
    FILE(STRINGS ${FILENAME} VERSION_PATCH REGEX "^#define ${VAR_PATCH} ([0-9]+)$")

    STRING(REGEX REPLACE "^#define ${VAR_MAJOR} ([0-9]+)$" "\\1" VERSION_MAJOR "${VERSION_MAJOR}")
    STRING(REGEX REPLACE "^#define ${VAR_MINOR} ([0-9]+)$" "\\1" VERSION_MINOR "${VERSION_MINOR}")
    STRING(REGEX REPLACE "^#define ${VAR_PATCH} ([0-9]+)$" "\\1" VERSION_PATCH "${VERSION_PATCH}")
  ENDIF(EXISTS ${FILENAME})
ENDMACRO(PARSE_VERSION)

MACRO(PARSE_VERSION_STRING VERSION_STRING _VAR_MAJOR _VAR_MINOR _VAR_PATCH)
  IF(${VERSION_STRING} MATCHES "[0-9]+")
    STRING(REGEX REPLACE "([0-9]+).*" "\\1" ${_VAR_MAJOR} "${VERSION_STRING}")
    IF(${VERSION_STRING} MATCHES "[0-9]+\\.[0-9]+")
      STRING(REGEX REPLACE "${${_VAR_MAJOR}}\\.([0-9]+).*" "\\1" ${_VAR_MINOR} "${VERSION_STRING}")
      IF(${VERSION_STRING} MATCHES "[0-9]+\\.[0-9]+\\.[0-9]+")
        STRING(REGEX REPLACE "${${_VAR_MAJOR}}\\.${${_VAR_MINOR}}\\.([0-9]+).*" "\\1" ${_VAR_PATCH} "${VERSION_STRING}")
      ELSE(${VERSION_STRING} MATCHES "[0-9]+\\.[0-9]+\\.[0-9]+")
        SET(${_VAR_PATCH} 0)
      ENDIF(${VERSION_STRING} MATCHES "[0-9]+\\.[0-9]+\\.[0-9]+")
    ELSE(${VERSION_STRING} MATCHES "[0-9]+\\.[0-9]+")
      SET(${_VAR_MINOR} 0)
    ENDIF(${VERSION_STRING} MATCHES "[0-9]+\\.[0-9]+")
  ELSE(${VERSION_STRING} MATCHES "[0-9]+")
    SET(${_VAR_MAJOR} 0)
  ENDIF(${VERSION_STRING} MATCHES "[0-9]+")
ENDMACRO(PARSE_VERSION_STRING)

MACRO(CONVERT_VERSION_NUMBER VAR_MAJOR VAR_MINOR VAR_PATCH _VERSION_NUMBER)
  SET(${_VERSION_NUMBER} ${VAR_MAJOR})
  IF(${VAR_MINOR} LESS 10)
    SET(${_VERSION_NUMBER} "${${_VERSION_NUMBER}}0${VAR_MINOR}")
  ENDIF(${VAR_MINOR} LESS 10)
  IF(${VAR_PATCH} LESS 10)
    SET(${_VERSION_NUMBER} "${${_VERSION_NUMBER}}0${VAR_PATCH}")
  ENDIF(${VAR_PATCH} LESS 10)
ENDMACRO(CONVERT_VERSION_NUMBER)

MACRO(SIGN_FILE target)
  IF(WITH_SIGN_FILE AND WIN32 AND WINSDK_SIGNTOOL AND ${CMAKE_BUILD_TYPE} STREQUAL "Release")
    GET_TARGET_PROPERTY(filename ${target} LOCATION)
#    ADD_CUSTOM_COMMAND(
#      TARGET ${target}
#      POST_BUILD
#      COMMAND ${WINSDK_SIGNTOOL} sign ${filename}
#      VERBATIM)
  ENDIF(WITH_SIGN_FILE AND WIN32 AND WINSDK_SIGNTOOL AND ${CMAKE_BUILD_TYPE} STREQUAL "Release")

  IF(APPLE)
    IF(IOS)
      SET_TARGET_PROPERTIES(${target} PROPERTIES
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer"
        XCODE_ATTRIBUTE_INSTALL_PATH "$(LOCAL_APPS_DIR)"
        XCODE_ATTRIBUTE_INSTALL_PATH_VALIDATE_PRODUCT "YES")
    ELSE(IOS)
#      SET_TARGET_PROPERTIES(${target} PROPERTIES
#        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Mac Developer")
    ENDIF(IOS)
  ENDIF(APPLE)
ENDMACRO(SIGN_FILE)

###
#
###
MACRO(SET_TARGET_SERVICE name)
  IF(NOT BUILD_FLAGS_SETUP)
    SETUP_BUILD_FLAGS()
  ENDIF(NOT BUILD_FLAGS_SETUP)

  ADD_EXECUTABLE(${name} ${ARGN})
  SET_TARGET_FLAGS(${name})

  INSTALL(TARGETS ${name} RUNTIME DESTINATION ${SBIN_PREFIX})
  SIGN_FILE(${name})
ENDMACRO(SET_TARGET_SERVICE)

###
#
###
MACRO(SET_TARGET_CONSOLE_EXECUTABLE name)
  IF(NOT BUILD_FLAGS_SETUP)
    SETUP_BUILD_FLAGS()
  ENDIF(NOT BUILD_FLAGS_SETUP)

  ADD_EXECUTABLE(${name} ${ARGN})
  SET_TARGET_FLAGS(${name})

#  IF(APPLE)
#    SET_TARGET_PROPERTIES(${name} PROPERTIES LINK_FLAGS "-Wl,-sectcreate,__TEXT,__info_plist,${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${TARGET}.app/Info.plist")
#  ENDIF(APPLE)

  INSTALL(TARGETS ${name} RUNTIME DESTINATION ${BIN_PREFIX})
  SIGN_FILE(${name})
ENDMACRO(SET_TARGET_CONSOLE_EXECUTABLE)

###
#
###
MACRO(SET_TARGET_GUI_EXECUTABLE name)
  IF(NOT BUILD_FLAGS_SETUP)
    SETUP_BUILD_FLAGS()
  ENDIF(NOT BUILD_FLAGS_SETUP)

  SET(_SOURCES)
  SET(_HEADERS)
  SET(_RESOURCES)
  SET(_XIBS)
  SET(_ICNSS)
  SET(_INFO_PLIST)
  SET(_LANGS)
  SET(_ITUNESARTWORK)
  SET(_MISCS)
  SET(_FRAMEWORKS)

  # Qt
  SET(_TSS)
  SET(_QRCS)
  SET(_UIS)

  FOREACH(ARG ${ARGN})
    IF(ARG MATCHES "\\.(cpp|mm|m|c|cxx|cc)$")
      LIST(APPEND _SOURCES ${ARG})
    ELSEIF(ARG MATCHES "\\.(h|pch|hpp|hh|hxx)$")
      LIST(APPEND _HEADERS ${ARG})
    ELSE(ARG MATCHES "\\.(cpp|mm|m|c|cxx|cc)$")
      SET(_INCLUDE ON)
      IF(ARG MATCHES "\\.xib$")
        LIST(APPEND _XIBS ${ARG})
        IF(NOT XCODE)
          # Don't include XIB with makefiles because we only need NIB
          SET(_INCLUDE OFF)
        ENDIF(NOT XCODE)
      ELSEIF(ARG MATCHES "iTunesArtwork\\.png$")
          # Don't include iTunesArtwork because it'll be copied in IPA
          SET(_INCLUDE OFF)
          SET(_ITUNESARTWORK ${ARG})
      ELSEIF(ARG MATCHES "\\.ts$")
        STRING(REGEX REPLACE "^.*_([a-z-]*)\\.ts$" "\\1" _LANG ${ARG})
        LIST(APPEND _LANGS ${_LANG})
        LIST(APPEND _TSS ${ARG})
      ELSEIF(ARG MATCHES "\\.qrc$")
        LIST(APPEND _QRCS ${ARG})
      ELSEIF(ARG MATCHES "\\.ui$")
        LIST(APPEND _UIS ${ARG})
      ELSEIF(ARG MATCHES "\\.icns$")
        LIST(APPEND _ICNSS ${ARG})
      ELSEIF(ARG MATCHES "Info\\.plist$")
        # Don't include Info.plist because it'll be generated
        LIST(APPEND _INFO_PLIST ${ARG})
        SET(_INCLUDE OFF)
      ELSEIF(ARG MATCHES "\\.framework$")
        LIST(APPEND _FRAMEWORKS ${ARG})
        SET(_INCLUDE OFF)
      ELSE(ARG MATCHES "\\.xib$")
        # Miscellaneous file
        LIST(APPEND _MISCS ${ARG})
      ENDIF(ARG MATCHES "\\.xib$")
      IF(_INCLUDE)
        LIST(APPEND _RESOURCES ${ARG})
      ENDIF(_INCLUDE)
    ENDIF(ARG MATCHES "\\.(cpp|mm|m|c|cxx|cc)$")
  ENDFOREACH(ARG ${ARGN})

  # Specific Qt macros
  IF(QT_WRAP_CPP)
    IF(_TSS)
      IF(WITH_UPDATE_TRANSLATIONS)
        SET(_TRANS ${_SOURCES} ${_HEADERS} ${_UIS})
        QT4_CREATE_TRANSLATION(QT_QMS ${_TRANS} ${_TSS})
      ELSE(WITH_UPDATE_TRANSLATIONS)
        QT4_ADD_TRANSLATION(QT_QMS ${_TSS})
      ENDIF(WITH_UPDATE_TRANSLATIONS)

      SOURCE_GROUP("translations" FILES ${_TSS})
    ENDIF(_TSS)

    IF(_QRCS)
      # Generate .cpp from .qrc
      QT4_ADD_RESOURCES(QT_QRCS ${_QRCS})
    ENDIF(_QRCS)

    IF(_UIS)
      # Generate .h from .ui
      QT4_WRAP_UI(QT_HEADERS ${_UIS})
      SOURCE_GROUP("ui" FILES ${_UIS})
    ENDIF(_UIS)

    IF(_HEADERS)
      # Generate .cxx from .h witout notice messages
      QT4_WRAP_CPP(QT_MOCS ${_HEADERS} OPTIONS -nn)
    ENDIF(_HEADERS)

    # Qt generated files
    SET(QT_SOURCES ${QT_MOCS} ${QT_HEADERS} ${QT_QRCS} ${QT_QMS})

    IF(QT_SOURCES)
      SOURCE_GROUP("generated" FILES ${QT_SOURCES})
    ENDIF(QT_SOURCES)
  ENDIF(QT_WRAP_CPP)

  ADD_EXECUTABLE(${name} WIN32 MACOSX_BUNDLE ${_SOURCES} ${_HEADERS} ${QT_SOURCES} ${_RESOURCES} ${_FRAMEWORKS})
  SET_TARGET_FLAGS(${name})
  SET_SOURCES_FLAGS(${_SOURCES})

  IF(APPLE)
    IF(XCODE)
      SET(OUTPUT_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/$(CONFIGURATION)/${PRODUCT}.app)
    ELSE(XCODE)
      SET(OUTPUT_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PRODUCT}.app)
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

    IF(XCODE)
      # Copy all resources in Resources folder
      IF(_RESOURCES)
        SET_SOURCE_FILES_PROPERTIES(${_RESOURCES} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
      ENDIF(_RESOURCES)
    ELSE(XCODE)
      # Make sure the 'Resources' Directory is correctly created before we build
      ADD_CUSTOM_COMMAND(TARGET ${name} PRE_BUILD COMMAND mkdir -p ${RESOURCES_DIR})
    ENDIF(XCODE)

    # Set a custom plist file for the app bundle
    IF(MAC_RESOURCES_DIR)
      IF(NOT _INFO_PLIST)
        SET(_INFO_PLIST ${MAC_RESOURCES_DIR}/Info.plist)
      ENDIF(NOT _INFO_PLIST)

      SET_TARGET_PROPERTIES(${name} PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${_INFO_PLIST})

      IF(NOT XCODE)
        ADD_CUSTOM_COMMAND(TARGET ${name} POST_BUILD COMMAND cp ARGS ${MAC_RESOURCES_DIR}/PkgInfo ${CONTENTS_DIR})
      ENDIF(NOT XCODE)
    ENDIF(MAC_RESOURCES_DIR)

    # extract translatable strings from xib
    # ibtool --generate-strings-file Example.strings en.lpoj/Example.xib

    # extract translatable strings from sources
    # genstrings -o en.lproj *.m

    # replace english expressions by french
    # ibtool --strings-file fr.lproj/Example.strings en.lproj/Example.xib --write fr.lproj/Example.xib

    # convert Info.plist to binary
    # plutil -convert binary1 Info.plist

    # Compile the .xib files using the 'ibtool' program with the destination being the app package
    IF(_XIBS)
      IF(NOT XCODE)
        # Make sure we can find the 'ibtool' program. If we can NOT find it we skip generation of this project
        FIND_PROGRAM(IBTOOL ibtool HINTS "/usr/bin" "${OSX_DEVELOPER_ROOT}/usr/bin" NO_CMAKE_FIND_ROOT_PATH)

        IF(${IBTOOL} STREQUAL "IBTOOL-NOTFOUND")
          MESSAGE(SEND_ERROR "ibtool can not be found and is needed to compile the .xib files. It should have been installed with the Apple developer tools. The default system paths were searched in addition to ${OSX_DEVELOPER_ROOT}/usr/bin")
        ENDIF(${IBTOOL} STREQUAL "IBTOOL-NOTFOUND")

        FOREACH(XIB ${_XIBS})
          IF(XIB MATCHES "\\.lproj")
            STRING(REGEX REPLACE "^.*/(([a-z]+)\\.lproj/([a-zA-Z_-]+))\\.xib$" "\\1.nib" NIB ${XIB})
          ELSE(XIB MATCHES "\\.lproj")
            STRING(REGEX REPLACE "^.*/([a-zA-Z_-]+)\\.xib$" "\\1.nib" NIB ${XIB})
          ENDIF(XIB MATCHES "\\.lproj")
          GET_FILENAME_COMPONENT(NIB_OUTPUT_DIR ${RESOURCES_DIR}/${NIB} PATH)
          ADD_CUSTOM_COMMAND(TARGET ${name} PRE_BUILD COMMAND mkdir -p ${NIB_OUTPUT_DIR})
          ADD_CUSTOM_COMMAND(TARGET ${name} POST_BUILD
            COMMAND ${IBTOOL} --errors --warnings --notices --output-format human-readable-text
              --compile ${RESOURCES_DIR}/${NIB}
              ${XIB}
            COMMENT "Building XIB object ${NIB}")
        ENDFOREACH(XIB)
      ENDIF(NOT XCODE)
    ENDIF(_XIBS)

    # Fix Qt bundle
    IF(_QMS)
      ADD_CUSTOM_COMMAND(TARGET ${name} PRE_BUILD COMMAND mkdir -p ${RESOURCES_DIR}/translations)
      # Copying all Qt translations to bundle
      FOREACH(_QM ${_QMS})
        ADD_CUSTOM_COMMAND(TARGET ${name} POST_BUILD COMMAND cp ARGS ${_QM} ${RESOURCES_DIR}/translations)
      ENDFOREACH(_QM)

      FOREACH(_LANG ${_LANGS})
        SET(LANG_FILE "${QT_TRANSLATIONS_DIR}/qt_${_LANG}.qm")
        IF(EXISTS ${LANG_FILE})
          ADD_CUSTOM_COMMAND(TARGET ${name} POST_BUILD COMMAND cp ARGS ${LANG_FILE} ${RESOURCES_DIR}/translations)
        ENDIF(EXISTS ${LANG_FILE})
      ENDFOREACH(_LANG)

      # Copying qt_menu.nib to bundle
      IF(MAC_RESOURCES_DIR)
        ADD_CUSTOM_COMMAND(TARGET ${name} POST_BUILD COMMAND cp -R ARGS ${MAC_RESOURCES_DIR}/qt_menu.nib ${RESOURCES_DIR})
      ENDIF(MAC_RESOURCES_DIR)
    ENDIF(_QMS)

    IF(_ICNSS)
      # Copying all icons to bundle
      FOREACH(_ICNS ${_ICNSS})
        # If target Mac OS X, use first icon for Bundle
        IF(NOT IOS AND NOT MACOSX_BUNDLE_ICON_FILE)
          GET_FILENAME_COMPONENT(_ICNS_NAME ${_ICNS} NAME)
          SET(MACOSX_BUNDLE_ICON_FILE ${_ICNS_NAME})
        ENDIF(NOT IOS AND NOT MACOSX_BUNDLE_ICON_FILE)
        IF(NOT XCODE)
          ADD_CUSTOM_COMMAND(TARGET ${name} POST_BUILD COMMAND cp ARGS ${_ICNS} ${RESOURCES_DIR})
        ENDIF(NOT XCODE)
      ENDFOREACH(_ICNS)
    ENDIF(_ICNSS)

    IF(_MISCS AND NOT XCODE)
      # Copying all misc files to bundle
      FOREACH(_MISC ${_MISCS})
        ADD_CUSTOM_COMMAND(TARGET ${name} POST_BUILD COMMAND cp ARGS ${_MISC} ${RESOURCES_DIR})
      ENDFOREACH(_MISC)
    ENDIF(_MISCS AND NOT XCODE)

    IF(NOT XCODE)
      # Fixing Bundle files for iOS
      IF(IOS)
        ADD_CUSTOM_COMMAND(TARGET ${name} POST_BUILD
          COMMAND mv ${OUTPUT_DIR}/Contents/MacOS/* ${OUTPUT_DIR})
        ADD_CUSTOM_COMMAND(TARGET ${name} POST_BUILD
          COMMAND mv ${OUTPUT_DIR}/Contents/Info.plist ${OUTPUT_DIR})
        ADD_CUSTOM_COMMAND(TARGET ${name} POST_BUILD
          COMMAND rm -rf ${OUTPUT_DIR}/Contents)

        # Creating .ipa package
        IF(_ITUNESARTWORK)
          SET(IPA ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PRODUCT}_ipa)
          ADD_CUSTOM_TARGET(package
            COMMAND rm -rf ${OUTPUT_DIR}/Contents
            COMMAND mkdir -p ${IPA}/Payload
            COMMAND security unlock-keychain
            COMMAND CODESIGN_ALLOCATE=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/codesign_allocate codesign -fs "iPhone Developer" ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PRODUCT}.app
            COMMAND cp -R ${OUTPUT_DIR} ${IPA}/Payload
            COMMAND cp ${_ITUNESARTWORK} ${IPA}/iTunesArtwork
            COMMAND ditto -c -k ${IPA} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PRODUCT}.ipa
            COMMAND rm -rf ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PRODUCT}_ipa
            COMMENT "Creating IPA archive..."
            SOURCES ${_ITUNESARTWORK})
          ADD_DEPENDENCIES(package ${name})
          SET_TARGET_LABEL(package "PACKAGE")
        ENDIF(_ITUNESARTWORK)
      ENDIF(IOS)

      IF(IOS AND NOT IOS_PLATFORM STREQUAL "OS")
        SET(IOS_SIMULATOR "${CMAKE_IOS_DEVELOPER_ROOT}/Applications/iPhone Simulator.app/Contents/MacOS/iPhone Simulator")
        IF(EXISTS ${IOS_SIMULATOR})
          ADD_CUSTOM_TARGET(run
            COMMAND rm -rf ${OUTPUT_DIR}/Contents
            COMMAND ${IOS_SIMULATOR} -SimulateApplication ${OUTPUT_DIR}/${PRODUCT}
            COMMENT "Launching iOS simulator...")
          ADD_DEPENDENCIES(run ${name})
          SET_TARGET_LABEL(run "RUN")
        ENDIF(EXISTS ${IOS_SIMULATOR})
      ENDIF(IOS AND NOT IOS_PLATFORM STREQUAL "OS")
    ENDIF(NOT XCODE)
  ELSE(APPLE)
    IF(QT_QMS)
      # Install all applications Qt translations
      INSTALL(FILES ${QT_QMS} DESTINATION ${SHARE_PREFIX}/translations)

      IF(WIN32)
        FOREACH(_LANG ${_LANGS})
          SET(LANG_FILE "${QT_TRANSLATIONS_DIR}/qt_${_LANG}.qm")
          IF(EXISTS ${LANG_FILE})
            INSTALL(FILES ${LANG_FILE} DESTINATION ${SHARE_PREFIX}/translations)
          ENDIF(EXISTS ${LANG_FILE})
        ENDFOREACH(_LANG)

        # Install Qt libraries
        IF(QT_USE_QTCORE)
          INSTALL(FILES "${QT_BINARY_DIR}/QtCore4.dll" DESTINATION ${BIN_PREFIX})
        ENDIF(QT_USE_QTCORE)
        IF(QT_USE_QTGUI)
          INSTALL(FILES "${QT_BINARY_DIR}/QtGui4.dll" DESTINATION ${BIN_PREFIX})
        ENDIF(QT_USE_QTGUI)
        IF(QT_USE_QTNETWORK)
          INSTALL(FILES "${QT_BINARY_DIR}/QtNetwork4.dll" DESTINATION ${BIN_PREFIX})
        ENDIF(QT_USE_QTNETWORK)
        IF(QT_USE_QTXML)
          INSTALL(FILES "${QT_BINARY_DIR}/QtXml4.dll" DESTINATION ${BIN_PREFIX})
        ENDIF(QT_USE_QTXML)
        IF(QT_USE_QTSQL)
          INSTALL(FILES "${QT_BINARY_DIR}/QtSql4.dll" DESTINATION ${BIN_PREFIX})
          INSTALL(FILES "${QT_PLUGINS_DIR}/sqldrivers/qsqlite4.dll" DESTINATION ${BIN_PREFIX}/sqldrivers)
        ENDIF(QT_USE_QTSQL)
        IF(QT_USE_QTSVG)
          INSTALL(FILES "${QT_BINARY_DIR}/QtSvg4.dll" DESTINATION ${BIN_PREFIX})
        ENDIF(QT_USE_QTSVG)

        FOREACH(_ARG ${EXTERNAL_BINARY_PATH})
          IF(EXISTS "${_ARG}/zlib1.dll")
            # Install other libraries
            INSTALL(FILES
              "${_ARG}/zlib1.dll"
              "${_ARG}/libeay32.dll"
              "${_ARG}/ssleay32.dll"
              DESTINATION ${BIN_PREFIX})
          ENDIF(EXISTS "${_ARG}/zlib1.dll")
        ENDFOREACH(_ARG)
      ENDIF(WIN32)
    ENDIF(QT_QMS)

    INCLUDE(InstallRequiredSystemLibraries)
  ENDIF(APPLE)

  IF(MSVC)
    SET_TARGET_PROPERTIES(${name} PROPERTIES LINK_FLAGS "/MANIFESTDEPENDENCY:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' publicKeyToken='6595b64144ccf1df' language='*' processorArchitecture='*'\"")
  ENDIF(MSVC)

  INSTALL(TARGETS ${name} RUNTIME DESTINATION ${BIN_PREFIX} BUNDLE DESTINATION ${BIN_PREFIX})
  SIGN_FILE(${name})
ENDMACRO(SET_TARGET_GUI_EXECUTABLE)

###
#
###
MACRO(SET_TARGET_LIB name)
  IF(NOT BUILD_FLAGS_SETUP)
    SETUP_BUILD_FLAGS()
  ENDIF(NOT BUILD_FLAGS_SETUP)

  # By default we're using project default
  SET(IS_STATIC ${WITH_STATIC})
  SET(IS_SHARED ${WITH_SHARED})
  SET(IS_PRIVATE OFF)

  SET(_SOURCES_STATIC)
  SET(_SOURCES_SHARED)
  SET(_HEADERS)
  SET(_RESOURCES)
  SET(_LANGS)
  SET(_MISCS)

  # Qt
  SET(_TSS)
  SET(_QRCS)
  SET(_UIS)

  # If user specify STATIC or SHARED, override project default
  FOREACH(ARG ${ARGN})
    IF(ARG STREQUAL STATIC)
      SET(IS_STATIC ON)
      SET(IS_SHARED OFF)
    ELSEIF(ARG STREQUAL SHARED)
      SET(IS_SHARED ON)
      SET(IS_STATIC OFF)
    ELSEIF(ARG STREQUAL PRIVATE)
      SET(IS_PRIVATE ON)
    ELSEIF(ARG MATCHES "\\.(cpp|mm|m|c|cxx|cc|rc|def|obj|asm)$")
      LIST(APPEND _SOURCES_SHARED ${ARG})
      IF(NOT ARG MATCHES "\\.def$" AND NOT ARG MATCHES "\\.rc$")
        LIST(APPEND _SOURCES_STATIC ${ARG})
      ENDIF(NOT ARG MATCHES "\\.def$" AND NOT ARG MATCHES "\\.rc$")
    ELSEIF(ARG MATCHES "\\.(h|pch|hpp|hh|hxx)$")
      LIST(APPEND _HEADERS ${ARG})
    ELSE(ARG STREQUAL STATIC)
      SET(_INCLUDE ON)
      IF(ARG MATCHES "\\.ts$")
        STRING(REGEX REPLACE "^.*_([a-z-]*)\\.ts$" "\\1" _LANG ${ARG})
        LIST(APPEND _LANGS ${_LANG})
        LIST(APPEND _TSS ${ARG})
      ELSEIF(ARG MATCHES "\\.qrc$")
        LIST(APPEND _QRCS ${ARG})
      ELSEIF(ARG MATCHES "\\.ui$")
        LIST(APPEND _UIS ${ARG})
      ELSE(ARG MATCHES "\\.xib$")
        # Miscellaneous file
        LIST(APPEND _MISCS ${ARG})
      ENDIF(ARG MATCHES "\\.ts$")
      IF(_INCLUDE)
        LIST(APPEND _RESOURCES ${ARG})
      ENDIF(_INCLUDE)
    ENDIF(ARG STREQUAL STATIC)
  ENDFOREACH(ARG ${ARGN})

  # Specific Qt macros
  IF(QT_WRAP_CPP)
    IF(_TSS)
      IF(WITH_UPDATE_TRANSLATIONS)
        SET(_TRANS ${_SOURCES} ${_HEADERS} ${_UIS})
        QT4_CREATE_TRANSLATION(QT_QMS ${_TRANS} ${_TSS})
      ELSE(WITH_UPDATE_TRANSLATIONS)
        QT4_ADD_TRANSLATION(QT_QMS ${_TSS})
      ENDIF(WITH_UPDATE_TRANSLATIONS)

      SOURCE_GROUP("translations" FILES ${_TSS})
    ENDIF(_TSS)

    IF(_QRCS)
      # Generate .cpp from .qrc
      QT4_ADD_RESOURCES(QT_QRCS ${_QRCS})
    ENDIF(_QRCS)

    IF(_UIS)
      # Generate .h from .ui
      QT4_WRAP_UI(QT_HEADERS ${_UIS})
      SOURCE_GROUP("ui" FILES ${_UIS})
    ENDIF(_UIS)

    IF(_HEADERS)
      # Generate .cxx from .h witout notice messages
      QT4_WRAP_CPP(QT_MOCS ${_HEADERS} OPTIONS -nn)
    ENDIF(_HEADERS)

    # Qt generated files
    SET(QT_SOURCES ${QT_MOCS} ${QT_HEADERS} ${QT_QRCS} ${QT_QMS})

    IF(QT_SOURCES)
      SOURCE_GROUP("generated" FILES ${QT_SOURCES})
    ENDIF(QT_SOURCES)
  ENDIF(QT_WRAP_CPP)

  IF(NOT APPLE)
    IF(QT_QMS)
      # Install all libraries Qt translations
      INSTALL(FILES ${QT_QMS} DESTINATION ${SHARE_PREFIX}/translations)
    ENDIF(QT_QMS)
  ENDIF(NOT APPLE)

  IF(IS_PRIVATE)
    SET(IS_STATIC ON)
    SET(IS_SHARED OFF)
  ENDIF(IS_PRIVATE)

  SET(STATIC_LIB OFF)

  SET_SOURCES_FLAGS(${_SOURCES_STATIC})

  # If library mode is not specified, prepend it
  IF(IS_SHARED)
    ADD_LIBRARY(${name} SHARED ${_SOURCES_SHARED} ${_HEADERS} ${QT_SOURCES} ${_RESOURCES})
    IF(IS_STATIC)
      ADD_LIBRARY(${name}_static STATIC ${_SOURCES_STATIC} ${_HEADERS} ${QT_SOURCES} ${_RESOURCES})
      SET(STATIC_LIB ON)
      IF(NOT WIN32)
        SET_TARGET_PROPERTIES(${name}_static PROPERTIES OUTPUT_NAME ${name})
      ENDIF(NOT WIN32)
    ENDIF(IS_STATIC)
  ELSEIF(IS_STATIC)
    ADD_LIBRARY(${name} STATIC ${_SOURCES_STATIC} ${_HEADERS} ${QT_SOURCES} ${_RESOURCES})
  ENDIF(IS_SHARED)

  IF(IS_SHARED)
    SIGN_FILE(${name})
  ENDIF(IS_SHARED)

  IF(IS_STATIC OR IS_SHARED)
    SET_TARGET_FLAGS(${name})
  ENDIF(IS_STATIC OR IS_SHARED)

  IF(STATIC_LIB)
    SET_TARGET_FLAGS(${name}_static)
  ENDIF(STATIC_LIB)

  IF(IS_STATIC OR IS_SHARED)
    # To prevent other libraries to be linked to the same libraries
    SET_TARGET_PROPERTIES(${name} PROPERTIES LINK_INTERFACE_LIBRARIES "")

    IF(STATIC_LIB)
      SET_TARGET_PROPERTIES(${name}_static PROPERTIES LINK_INTERFACE_LIBRARIES "")
    ENDIF(STATIC_LIB)

    IF(WITH_PREFIX_LIB)
      SET_TARGET_PROPERTIES(${name} PROPERTIES PREFIX "lib")
      IF(STATIC_LIB)
        SET_TARGET_PROPERTIES(${name}_static PROPERTIES PREFIX "lib")
      ENDIF(STATIC_LIB)
    ENDIF(WITH_PREFIX_LIB)

    IF(WIN32)
      # DLLs are in bin directory under Windows
      SET(LIBRARY_DEST ${BIN_PREFIX})
    ELSE(WIN32)
      SET(LIBRARY_DEST ${LIB_PREFIX})
    ENDIF(WIN32)

    IF(NOT IS_PRIVATE)
      # copy both DLL and LIB files
      INSTALL(TARGETS ${name} RUNTIME DESTINATION ${BIN_PREFIX} LIBRARY DESTINATION ${LIBRARY_DEST} ARCHIVE DESTINATION ${LIB_PREFIX})
      IF(STATIC_LIB)
        INSTALL(TARGETS ${name}_static RUNTIME DESTINATION ${BIN_PREFIX} LIBRARY DESTINATION ${LIBRARY_DEST} ARCHIVE DESTINATION ${LIB_PREFIX})
      ENDIF(STATIC_LIB)
      # copy also PDB files in installation directory for Visual C++
      IF(MSVC)
        IF(IS_STATIC)
          IF(STATIC_LIB)
            # get final location for Debug configuration
            GET_TARGET_PROPERTY(OUTPUT_FULLPATH ${name}_static LOCATION_Debug)
          ELSE(STATIC_LIB)
            # get final location for Debug configuration
            GET_TARGET_PROPERTY(OUTPUT_FULLPATH ${name} LOCATION_Debug)
          ENDIF(STATIC_LIB)
          # replace extension by .pdb
          STRING(REGEX REPLACE "\\.([a-zA-Z0-9_]+)$" ".pdb" OUTPUT_FULLPATH ${OUTPUT_FULLPATH})
          # copy PDB file together with LIB
          INSTALL(FILES ${OUTPUT_FULLPATH} DESTINATION ${LIB_PREFIX} CONFIGURATIONS Debug)
        ENDIF(IS_STATIC)
        IF(IS_SHARED)
          # get final location for Debug configuration
          GET_TARGET_PROPERTY(OUTPUT_FULLPATH ${name} LOCATION_Debug)
          # replace extension by .pdb
          STRING(REGEX REPLACE "\\.([a-zA-Z0-9_]+)$" ".pdb" OUTPUT_FULLPATH ${OUTPUT_FULLPATH})
          # copy PDB file together with DLL
          INSTALL(FILES ${OUTPUT_FULLPATH} DESTINATION ${BIN_PREFIX} CONFIGURATIONS Debug)
        ENDIF(IS_SHARED)
      ENDIF(MSVC)
    ELSE(NOT IS_PRIVATE)
      IF(IS_SHARED)
        # copy only DLL because we don't need development files
        INSTALL(TARGETS ${name} RUNTIME DESTINATION ${BIN_PREFIX} LIBRARY DESTINATION ${LIBRARY_DEST})
      ENDIF(IS_SHARED)
    ENDIF(NOT IS_PRIVATE)
  ELSE(IS_STATIC OR IS_SHARED)
    MESSAGE(FATAL_ERROR "You can't disable both static and shared libraries")
  ENDIF(IS_STATIC OR IS_SHARED)
ENDMACRO(SET_TARGET_LIB)

###
#
###
MACRO(SET_TARGET_PLUGIN name)
  IF(NOT BUILD_FLAGS_SETUP)
    SETUP_BUILD_FLAGS()
  ENDIF(NOT BUILD_FLAGS_SETUP)

  IF(WITH_STATIC_PLUGINS)
    ADD_LIBRARY(${name} STATIC ${ARGN})
  ELSE(WITH_STATIC_PLUGINS)
    ADD_LIBRARY(${name} MODULE ${ARGN})
    SIGN_FILE(${name})
  ENDIF(WITH_STATIC_PLUGINS)

  SET_TARGET_FLAGS(${name})

  IF(PLUGIN_PREFIX)
    IF(WIN32)
      # DLL is in bin directory under Windows
      SET(PLUGIN_DEST ${PLUGIN_PREFIX})
    ELSE(WIN32)
      SET(PLUGIN_DEST ${PLUGIN_PREFIX})
    ENDIF(WIN32)

    IF(WITH_INSTALL_LIBRARIES AND WITH_STATIC_PLUGINS)
      INSTALL(TARGETS ${name} LIBRARY DESTINATION ${PLUGIN_DEST} ARCHIVE DESTINATION ${LIB_PREFIX})
    ELSE(WITH_INSTALL_LIBRARIES AND WITH_STATIC_PLUGINS)
      IF(NOT WITH_STATIC_PLUGINS)
        INSTALL(TARGETS ${name} LIBRARY DESTINATION ${PLUGIN_DEST} ARCHIVE DESTINATION ${LIB_PREFIX})
      ENDIF(NOT WITH_STATIC_PLUGINS)
    ENDIF(WITH_INSTALL_LIBRARIES AND WITH_STATIC_PLUGINS)
  ENDIF(PLUGIN_PREFIX)
ENDMACRO(SET_TARGET_PLUGIN)

MACRO(SET_TARGET_LABEL name label)
  SET_TARGET_PROPERTIES(${name} PROPERTIES PROJECT_LABEL ${label})

  # Under Mac OS X, executables should use project label
  GET_TARGET_PROPERTY(type ${name} TYPE)

  IF(${type} STREQUAL EXECUTABLE AND APPLE)
    SET_TARGET_PROPERTIES(${name} PROPERTIES OUTPUT_NAME ${label})
  ENDIF(${type} STREQUAL EXECUTABLE AND APPLE)
ENDMACRO(SET_TARGET_LABEL)

MACRO(SET_TARGET_EXTENSION name extension)
  SET_TARGET_PROPERTIES(${name} PROPERTIES SUFFIX .${extension})
ENDMACRO(SET_TARGET_EXTENSION)

MACRO(SET_TARGET_FLAGS name)
  IF(NAMESPACE)
    STRING(REGEX REPLACE "^lib" "" new_name ${name})
    SET(filename "${NAMESPACE}_${new_name}")
    # TODO: check if name != new_name and prepend "lib" prefix before namespace
  ENDIF(NAMESPACE)

  IF(HAVE_REVISION_H)
    # explicitly say that the executable depends on revision.h
    ADD_DEPENDENCIES(${name} revision)
  ENDIF(HAVE_REVISION_H)

  GET_TARGET_PROPERTY(type ${name} TYPE)

  IF(filename)
    SET_TARGET_PROPERTIES(${name} PROPERTIES OUTPUT_NAME ${filename})
  ENDIF(filename)

  IF(${type} STREQUAL SHARED_LIBRARY)
    # Set versions only if target is a shared library
    IF(DEFINED VERSION)
      SET_TARGET_PROPERTIES(${name} PROPERTIES VERSION ${VERSION})
    ENDIF(DEFINED VERSION)
    IF(DEFINED VERSION_MAJOR AND NOT ANDROID)
      SET_TARGET_PROPERTIES(${name} PROPERTIES SOVERSION ${VERSION_MAJOR})
    ENDIF(DEFINED VERSION_MAJOR AND NOT ANDROID)
    IF(LIB_FULL_PREFIX)
      SET_TARGET_PROPERTIES(${name} PROPERTIES INSTALL_NAME_DIR ${LIB_FULL_PREFIX})
    ELSEIF(LIB_PREFIX)
      SET_TARGET_PROPERTIES(${name} PROPERTIES INSTALL_NAME_DIR ${CMAKE_INSTALL_PREFIX}/${LIB_PREFIX})
    ENDIF(LIB_FULL_PREFIX)
  ENDIF(${type} STREQUAL SHARED_LIBRARY)

  IF(${type} STREQUAL EXECUTABLE AND MSVC)
    SET_TARGET_PROPERTIES(${name} PROPERTIES
      VERSION ${VERSION}
      SOVERSION ${VERSION_MAJOR}
      COMPILE_FLAGS "/GA"
      LINK_FLAGS "/VERSION:${VERSION}")
  ENDIF(${type} STREQUAL EXECUTABLE AND MSVC)

  IF(NOT ${type} STREQUAL STATIC_LIBRARY)
    IF(NOT MSVC AND NOT WITH_SYMBOLS)
      IF(APPLE)
        SET_TARGET_PROPERTIES(${name} PROPERTIES LINK_FLAGS_RELEASE "-Wl,-dead_strip -Wl,-x")
      ELSE(APPLE)
        SET_TARGET_PROPERTIES(${name} PROPERTIES LINK_FLAGS_RELEASE "-Wl,-s")
      ENDIF(APPLE)
    ENDIF(NOT MSVC AND NOT WITH_SYMBOLS)
  ENDIF(NOT ${type} STREQUAL STATIC_LIBRARY)

  IF(WITH_STLPORT)
    TARGET_LINK_LIBRARIES(${name} ${STLPORT_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT})
    IF(MSVC)
      SET_TARGET_PROPERTIES(${name} PROPERTIES COMPILE_FLAGS "/X")
    ENDIF(MSVC)
  ENDIF(WITH_STLPORT)

  IF(XCODE)
    IF(IOS AND IOS_VERSION)
      SET_TARGET_PROPERTIES(${name} PROPERTIES
        XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET ${IOS_VERSION}
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2")
    ENDIF(IOS AND IOS_VERSION)

    IF(WITH_VISIBILITY_HIDDEN)
      SET_TARGET_PROPERTIES(${name} PROPERTIES
        XCODE_ATTRIBUTE_GCC_SYMBOLS_PRIVATE_EXTERN YES
        XCODE_ATTRIBUTE_GCC_INLINES_ARE_PRIVATE_EXTERN YES)
    ENDIF(WITH_VISIBILITY_HIDDEN)

    SET_TARGET_PROPERTIES(${target} PROPERTIES XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES)
  ENDIF(XCODE)

  IF(WIN32)
    SET_TARGET_PROPERTIES(${name} PROPERTIES DEBUG_POSTFIX "d" RELEASE_POSTFIX "")
  ENDIF(WIN32)
ENDMACRO(SET_TARGET_FLAGS)

# Set special flags to sources depending on specific language based on their extension
MACRO(SET_SOURCES_FLAGS SOURCES)
  SET(_C)
  SET(_CPP)
  SET(_OBJC)

  FOREACH(_SRC SOURCES)
    IF(_SRC MATCHES "\\.c$")
      LIST(APPEND _C ${_SRC})
    ELSEIF(_SRC MATCHES "\\.(cpp|cxx|cc)$")
      LIST(APPEND _CPP ${_SRC})
    ELSEIF(_SRC MATCHES "\\.(mm|m)$")
      LIST(APPEND _OBJC ${_SRC})
    ENDIF(_SRC MATCHES "\\.c$")
  ENDFOREACH(_SRC)

  IF(_OBJC)
    SET_SOURCE_FILES_PROPERTIES(${_OBJC} PROPERTIES COMPILE_FLAGS "-fobjc-arc -fobjc-abi-version=2 -fobjc-legacy-dispatch")
  ENDIF(_OBJC)
ENDMACRO(SET_SOURCES_FLAGS)

###
# Checks build vs. source location. Prevents In-Source builds.
###
MACRO(CHECK_OUT_OF_SOURCE)
  IF(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
    MESSAGE(FATAL_ERROR "

CMake generation for this project is not allowed within the source directory!
Remove the CMakeCache.txt file and try again from another folder, e.g.:

   rm CMakeCache.txt
   mkdir cmake
   cd cmake
   cmake ..
    ")
  ENDIF(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})

ENDMACRO(CHECK_OUT_OF_SOURCE)

# Set option default value
MACRO(SET_OPTION_DEFAULT NAME VALUE)
  SET(${NAME}_DEFAULT ${VALUE})
ENDMACRO(SET_OPTION_DEFAULT)

MACRO(ADD_OPTION NAME DESCRIPTION)
  IF(${NAME}_DEFAULT)
    SET(${NAME}_DEFAULT ON)
  ELSE(${NAME}_DEFAULT)
    SET(${NAME}_DEFAULT OFF)
  ENDIF(${NAME}_DEFAULT)
  
  OPTION(${NAME} ${DESCRIPTION} ${${NAME}_DEFAULT})
ENDMACRO(ADD_OPTION)

MACRO(INIT_DEFAULT_OPTIONS)
  # Undefined options are set to OFF
  SET_OPTION_DEFAULT(WITH_RTTI ON)
  SET_OPTION_DEFAULT(WITH_EXCEPTIONS ON)
  SET_OPTION_DEFAULT(WITH_LOGGING ON)
  SET_OPTION_DEFAULT(WITH_PCH ON)
  SET_OPTION_DEFAULT(WITH_INSTALL_LIBRARIES ON)

  IF(WIN32)
    SET_OPTION_DEFAULT(WITH_STATIC ON)
  ELSE(WIN32)
    IF(IOS OR ANDROID)
      SET_OPTION_DEFAULT(WITH_STATIC ON)
    ELSE(IOS OR ANDROID)
      SET_OPTION_DEFAULT(WITH_SHARED ON)
    ENDIF(IOS OR ANDROID)
    SET_OPTION_DEFAULT(WITH_UNIX_STRUCTURE ON)
  ENDIF(WIN32)

  # Check if CMake is launched from a Debian packaging script
  SET(DEB_HOST_GNU_CPU $ENV{DEB_HOST_GNU_CPU})

  # Don't strip if generating a .deb
  IF(DEB_HOST_GNU_CPU)
    SET_OPTION_DEFAULT(WITH_SYMBOLS ON)
  ENDIF(DEB_HOST_GNU_CPU)

  # Hidden visibility is required for C++ on iOS and Android
  IF(IOS OR ANDROID)
    SET_OPTION_DEFAULT(WITH_VISIBILITY_HIDDEN ON)
  ENDIF(IOS OR ANDROID)

  # Tells SETUP_DEFAULT_OPTIONS to not initialize options again
  SET(DEFAULT_OPTIONS_INIT ON)
ENDMACRO(INIT_DEFAULT_OPTIONS)

MACRO(SETUP_DEFAULT_OPTIONS)
  # Initialize default options if not already done
  IF(NOT DEFAULT_OPTIONS_INIT)
    INIT_DEFAULT_OPTIONS()
  ENDIF(NOT DEFAULT_OPTIONS_INIT)

  ADD_OPTION(WITH_WARNINGS            "Show all compilation warnings")
  ADD_OPTION(WITH_LOGGING             "Enable logs")
  ADD_OPTION(WITH_COVERAGE            "With Code Coverage Support")
  ADD_OPTION(WITH_PCH                 "Use Precompiled Headers to speed up compilation")
  ADD_OPTION(WITH_STATIC              "Compile static libraries")
  ADD_OPTION(WITH_SHARED              "Compile dynamic libraries")
  ADD_OPTION(WITH_STATIC_PLUGINS      "Compile plugins as static or dynamic")
  ADD_OPTION(WITH_STATIC_EXTERNAL     "Use only static external libraries")
  ADD_OPTION(WITH_UNIX_STRUCTURE      "Use UNIX structure (bin, include, lib)")
  ADD_OPTION(WITH_INSTALL_LIBRARIES   "Install development files (includes and static libraries)")

  ADD_OPTION(WITH_STLPORT             "Use STLport instead of standard STL")
  ADD_OPTION(WITH_RTTI                "Enable RTTI support")
  ADD_OPTION(WITH_EXCEPTIONS          "Enable exceptions support")
  ADD_OPTION(WITH_TESTS               "Compile tests projects")
  ADD_OPTION(WITH_SYMBOLS             "Keep debug symbols in binaries")

  ADD_OPTION(WITH_UPDATE_TRANSLATIONS "Update Qt translations")

  # Specific Windows options
  IF(WIN32)
    ADD_OPTION(WITH_SIGN_FILE         "Sign executables and libraries")
    ADD_OPTION(WITH_PREFIX_LIB        "Force lib prefix for libraries")
  ELSE(WIN32)
    ADD_OPTION(WITH_VISIBILITY_HIDDEN "Hide all symbols by default")
  ENDIF(WIN32)

  SET(DEFAULT_OPTIONS_SETUP ON)
ENDMACRO(SETUP_DEFAULT_OPTIONS)

MACRO(INIT_BUILD_FLAGS)
  IF(NOT DEFAULT_OPTIONS_SETUP)
    SETUP_DEFAULT_OPTIONS()
  ENDIF(NOT DEFAULT_OPTIONS_SETUP)

  # Redirect output files
  SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
  SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

  # DLL should be in the same directory as EXE under Windows
  IF(WIN32)
    SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
  ELSE(WIN32)
    SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
  ENDIF(WIN32)

  SET(CMAKE_CONFIGURATION_TYPES "Debug;Release" CACHE STRING "" FORCE)

  IF(NOT CMAKE_BUILD_TYPE MATCHES "Debug" AND NOT CMAKE_BUILD_TYPE MATCHES "Release")
    # enforce release mode if it's neither Debug nor Release
    SET(CMAKE_BUILD_TYPE "Release" CACHE STRING "" FORCE)
  ENDIF(NOT CMAKE_BUILD_TYPE MATCHES "Debug" AND NOT CMAKE_BUILD_TYPE MATCHES "Release")

  SET(HOST_CPU ${CMAKE_HOST_SYSTEM_PROCESSOR})

  IF(HOST_CPU MATCHES "amd64")
    SET(HOST_CPU "x86_64")
  ELSEIF(HOST_CPU MATCHES "i.86")
    SET(HOST_CPU "x86")
  ENDIF(HOST_CPU MATCHES "amd64")
  
  # Determine target CPU
  IF(NOT TARGET_CPU)
    SET(TARGET_CPU $ENV{DEB_HOST_GNU_CPU})
  ENDIF(NOT TARGET_CPU)

  # If not specified, use the same CPU as host
  IF(NOT TARGET_CPU)
    SET(TARGET_CPU ${CMAKE_SYSTEM_PROCESSOR})
  ENDIF(NOT TARGET_CPU)

  IF(TARGET_CPU MATCHES "amd64")
    SET(TARGET_CPU "x86_64")
  ELSEIF(TARGET_CPU MATCHES "i.86")
    SET(TARGET_CPU "x86")
  ENDIF(TARGET_CPU MATCHES "amd64")

  # DEB_HOST_ARCH_ENDIAN is 'little' or 'big'
  # DEB_HOST_ARCH_BITS is '32' or '64'

  IF(${CMAKE_CXX_COMPILER_ID} MATCHES "Clang")
    SET(CLANG ON)
    MESSAGE(STATUS "Using Clang compiler")
  ENDIF(${CMAKE_CXX_COMPILER_ID} MATCHES "Clang")

  IF(CMAKE_GENERATOR MATCHES "Xcode")
    SET(XCODE ON)
    MESSAGE(STATUS "Generating Xcode project")
  ENDIF(CMAKE_GENERATOR MATCHES "Xcode")

  # If target and host CPU are the same
  IF("${HOST_CPU}" STREQUAL "${TARGET_CPU}")
    # x86-compatible CPU
    IF(HOST_CPU MATCHES "x86")
      IF(NOT CMAKE_SIZEOF_VOID_P)
        INCLUDE (CheckTypeSize)
        CHECK_TYPE_SIZE("void*"  CMAKE_SIZEOF_VOID_P)
      ENDIF(NOT CMAKE_SIZEOF_VOID_P)

      # Using 32 or 64 bits libraries
      IF(CMAKE_SIZEOF_VOID_P EQUAL 8)
        SET(TARGET_CPU "x86_64")
      ELSE(CMAKE_SIZEOF_VOID_P EQUAL 8)
        SET(TARGET_CPU "x86")
      ENDIF(CMAKE_SIZEOF_VOID_P EQUAL 8)
    ELSEIF(HOST_CPU MATCHES "arm")
      SET(TARGET_CPU "arm")
    ELSE(HOST_CPU MATCHES "x86")
      SET(TARGET_CPU "unknown")
      MESSAGE(STATUS "Unknown architecture: ${HOST_CPU}")
    ENDIF(HOST_CPU MATCHES "x86")
    # TODO: add checks for PPC
  ELSE("${HOST_CPU}" STREQUAL "${TARGET_CPU}")
    MESSAGE(STATUS "Compiling on ${HOST_CPU} for ${TARGET_CPU}")
  ENDIF("${HOST_CPU}" STREQUAL "${TARGET_CPU}")

  IF(NOT CMAKE_OSX_ARCHITECTURES)
    IF(TARGET_CPU STREQUAL "x86_64")
      SET(TARGET_X64 1)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -DHAVE_X86_64")
    ELSEIF(TARGET_CPU STREQUAL "x86")
      SET(TARGET_X86 1)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -DHAVE_X86")
    ELSEIF(TARGET_CPU STREQUAL "armv7")
      SET(TARGET_ARM 1)
      SET(TARGET_ARMV7 1)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -DHAVE_ARM")
    ELSEIF(TARGET_CPU STREQUAL "armv6")
      SET(TARGET_ARM 1)
      SET(TARGET_ARMV6 1)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -DHAVE_ARM")
    ELSEIF(TARGET_CPU STREQUAL "armv5")
      SET(TARGET_ARM 1)
      SET(TARGET_ARMV5 1)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -DHAVE_ARM")
    ELSEIF(TARGET_CPU STREQUAL "arm")
      SET(TARGET_ARM 1)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -DHAVE_ARM")
    ENDIF(TARGET_CPU STREQUAL "x86_64")
  ENDIF(NOT CMAKE_OSX_ARCHITECTURES)

  # Fix library paths suffixes for Debian MultiArch
  SET(DEBIAN_MULTIARCH $ENV{DEB_HOST_MULTIARCH})

  IF(DEBIAN_MULTIARCH)
    SET(CMAKE_LIBRARY_ARCHITECTURE ${DEBIAN_MULTIARCH})
  ENDIF(DEBIAN_MULTIARCH)

  IF(CMAKE_LIBRARY_ARCHITECTURE)
    SET(CMAKE_LIBRARY_PATH /lib/${CMAKE_LIBRARY_ARCHITECTURE} /usr/lib/${CMAKE_LIBRARY_ARCHITECTURE} ${CMAKE_LIBRARY_PATH})
    IF(TARGET_X64)
      SET(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} /lib64 /usr/lib64)
    ENDIF(TARGET_X64)
    IF(TARGET_X86)
      SET(CMAKE_LIBRARY_PATH ${CMAKE_LIBRARY_PATH} /lib32 /usr/lib32)
    ENDIF(TARGET_X86)
  ENDIF(CMAKE_LIBRARY_ARCHITECTURE)

  IF(APPLE AND NOT IOS)
    SET(CMAKE_INCLUDE_PATH /opt/local/include ${CMAKE_INCLUDE_PATH})
    SET(CMAKE_LIBRARY_PATH /opt/local/lib ${CMAKE_LIBRARY_PATH})
  ENDIF(APPLE AND NOT IOS)

  IF(MSVC)
    IF(MSVC10)
      SET(PLATFORM_CFLAGS "/Gy- /MP ${PLATFORM_CFLAGS}")
      # /Ox is working with VC++ 2010, but custom optimizations don't exist
      SET(RELEASE_CFLAGS "/Ox /GF /GS- ${RELEASE_CFLAGS}")
      # without inlining it's unusable, use custom optimizations again
      SET(DEBUG_CFLAGS "/Od /Ob1 /GF- ${DEBUG_CFLAGS}")
    ELSEIF(MSVC90)
      # don't use a /O[012x] flag if you want custom optimizations
      SET(RELEASE_CFLAGS "/Ob2 /Oi /Ot /Oy /GT /GF /GS- ${RELEASE_CFLAGS}")
      # without inlining it's unusable, use custom optimizations again
      SET(DEBUG_CFLAGS "/Ob1 /GF- ${DEBUG_CFLAGS}")
    ELSEIF(MSVC80)
      SET(PLATFORM_CFLAGS "/Wp64 ${PLATFORM_CFLAGS}")
      # don't use a /O[012x] flag if you want custom optimizations
      SET(RELEASE_CFLAGS "/Ox /GF /GS- ${RELEASE_CFLAGS}")
      # without inlining it's unusable, use custom optimizations again
      SET(DEBUG_CFLAGS "/Od /Ob1 ${DEBUG_CFLAGS}")
    ELSE(MSVC10)
      MESSAGE(FATAL_ERROR "Can't determine compiler version ${MSVC_VERSION}")
    ENDIF(MSVC10)

    IF(WITH_LOGGING)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} /DENABLE_LOGS")
    ENDIF(WITH_LOGGING)

    SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} /D_CRT_SECURE_NO_DEPRECATE /D_CRT_SECURE_NO_WARNINGS /D_CRT_NONSTDC_NO_WARNINGS /DWIN32 /D_WINDOWS /Zm1000 /wd4250")
    SET(PLATFORM_CXXFLAGS ${PLATFORM_CFLAGS})

    # Exceptions are only set for C++
    IF(WITH_EXCEPTIONS)
      SET(PLATFORM_CXXFLAGS "${PLATFORM_CXXFLAGS} /EHsc")
    ELSE(WITH_EXCEPTIONS)
      SET(PLATFORM_CXXFLAGS "${PLATFORM_CXXFLAGS} -DBOOST_NO_EXCEPTIONS -D_HAS_EXCEPTIONS=0")
    ENDIF(WITH_EXCEPTIONS)

    # RTTI is only set for C++
    IF(WITH_RTTI)
#      SET(PLATFORM_CXXFLAGS "${PLATFORM_CXXFLAGS} /GR")
    ELSE(WITH_RTTI)
      SET(PLATFORM_CXXFLAGS "${PLATFORM_CXXFLAGS} /GR-")
    ENDIF(WITH_RTTI)

    IF(TARGET_X64)
      # Fix a bug with Intellisense
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} /D_WIN64")
      # Fix a compilation error for some big C++ files
      SET(RELEASE_CFLAGS "${RELEASE_CFLAGS} /bigobj")
    ELSE(TARGET_X64)
      # Allows 32 bits applications to use 3 GB of RAM
      SET(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} /LARGEADDRESSAWARE")
    ENDIF(TARGET_X64)

    IF(WITH_SYMBOLS)
      SET(RELEASE_CFLAGS "/Zi ${RELEASE_CFLAGS}")
      SET(RELEASE_LINKFLAGS "/DEBUG ${RELEASE_LINKFLAGS}")
    ELSE(WITH_SYMBOLS)
      SET(RELEASE_LINKFLAGS "/RELEASE ${RELEASE_LINKFLAGS}")
    ENDIF(WITH_SYMBOLS)

    SET(DEBUG_CFLAGS "/Zi /MDd /RTC1 /RTCc /D_DEBUG /DDEBUG ${DEBUG_CFLAGS}")
    SET(RELEASE_CFLAGS "/MD /DNDEBUG ${RELEASE_CFLAGS}")
    SET(DEBUG_LINKFLAGS "/DEBUG /OPT:NOREF /OPT:NOICF /NODEFAULTLIB:msvcrt ${MSVC_INCREMENTAL_YES_FLAG} ${DEBUG_LINKFLAGS}")
    SET(RELEASE_LINKFLAGS "/OPT:REF /OPT:ICF /INCREMENTAL:NO ${RELEASE_LINKFLAGS}")

    IF(WITH_WARNINGS)
      SET(DEBUG_CFLAGS "/W4 ${DEBUG_CFLAGS}")
    ELSE(WITH_WARNINGS)
      SET(DEBUG_CFLAGS "/W3 ${DEBUG_CFLAGS}")
    ENDIF(WITH_WARNINGS)
  ELSE(MSVC)
    IF(WIN32)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -DWIN32 -D_WIN32")

      IF(CLANG)
        SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -nobuiltininc")
      ENDIF(CLANG)
    ENDIF(WIN32)

    IF(APPLE)
      IF(IOS)
        SET(CMAKE_OSX_DEPLOYMENT_TARGET "10.7" CACHE PATH "" FORCE)
      ELSE(IOS)
        IF(NOT CMAKE_OSX_DEPLOYMENT_TARGET)
          SET(CMAKE_OSX_DEPLOYMENT_TARGET "10.5" CACHE PATH "" FORCE)
        ENDIF(NOT CMAKE_OSX_DEPLOYMENT_TARGET)
      ENDIF(IOS)

      IF(XCODE)
        IF(IOS)
          SET(CMAKE_OSX_SYSROOT "iphoneos" CACHE PATH "" FORCE)
        ELSE(IOS)
          SET(CMAKE_OSX_SYSROOT "macosx" CACHE PATH "" FORCE)
        ENDIF(IOS)
      ELSE(XCODE)
        IF(IOS)
          IF(IOS_VERSION)
            PARSE_VERSION_STRING(${IOS_VERSION} IOS_VERSION_MAJOR IOS_VERSION_MINOR IOS_VERSION_PATCH)
            CONVERT_VERSION_NUMBER(${IOS_VERSION_MAJOR} ${IOS_VERSION_MINOR} ${IOS_VERSION_PATCH} IOS_VERSION_NUMBER)

            SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -D__IPHONE_OS_VERSION_MIN_REQUIRED=${IOS_VERSION_NUMBER}")
          ENDIF(IOS_VERSION)

          IF(CMAKE_OSX_ARCHITECTURES)
            SET(TARGETS_COUNT 0)
            FOREACH(_ARCH ${CMAKE_OSX_ARCHITECTURES})
              IF(_ARCH STREQUAL "i386")
                SET(TARGET_X86 1)
                MATH(EXPR TARGETS_COUNT "${TARGETS_COUNT}+1")
              ELSEIF(_ARCH STREQUAL "armv7")
                SET(TARGET_ARMV7 1)
                SET(TARGET_ARM 1)
                MATH(EXPR TARGETS_COUNT "${TARGETS_COUNT}+1")
              ELSEIF(_ARCH STREQUAL "armv6")
                SET(TARGET_ARMV6 1)
                SET(TARGET_ARM 1)
                MATH(EXPR TARGETS_COUNT "${TARGETS_COUNT}+1")
              ENDIF(_ARCH STREQUAL "i386")
            ENDFOREACH(_ARCH)
          ENDIF(CMAKE_OSX_ARCHITECTURES)

          IF(CMAKE_IOS_SYSROOT)
            IF(TARGETS_COUNT EQUAL 1)
              IF(TARGET_ARM)
                IF(TARGET_ARMV7)
                  SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -arch armv7")
                ELSE(TARGET_ARMV7)
                  SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -arch armv6")
                ENDIF(TARGET_ARMV7)

                SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -mthumb -DHAVE_ARM -isysroot${CMAKE_IOS_SYSROOT}")

                SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -miphoneos-version-min=${IOS_VERSION}")
                SET(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} -Wl,-iphoneos_version_min,${IOS_VERSION}")
              ENDIF(TARGET_ARM)
            ELSE(TARGETS_COUNT EQUAL 1)
              IF(TARGET_ARMV6)
                SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -Xarch_armv6 -mthumb -Xarch_armv6 -DHAVE_ARM -Xarch_armv6 -isysroot${CMAKE_IOS_SYSROOT}")

                SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -Xarch_armv6 -miphoneos-version-min=${IOS_VERSION}")
                SET(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} -Xarch_armv6 -Wl,-iphoneos_version_min,${IOS_VERSION}")
              ENDIF(TARGET_ARMV6)
		  
              IF(TARGET_ARMV7)
                SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -Xarch_armv7 -mthumb -Xarch_armv7 -DHAVE_ARM -Xarch_armv7 -isysroot${CMAKE_IOS_SYSROOT}")

                SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -Xarch_armv7 -miphoneos-version-min=${IOS_VERSION}")
                SET(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} -Xarch_armv7 -Wl,-iphoneos_version_min,${IOS_VERSION}")
              ENDIF(TARGET_ARMV7)
            ENDIF(TARGETS_COUNT EQUAL 1)
          ENDIF(CMAKE_IOS_SYSROOT)

          IF(CMAKE_IOS_SIMULATOR_SYSROOT AND TARGET_X86)
            IF(TARGETS_COUNT EQUAL 1)
              SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -arch i386")
            ELSE(TARGETS_COUNT EQUAL 1)
              SET(XARCH "-Xarch_i386 ")
            ENDIF(TARGETS_COUNT EQUAL 1)

            SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} ${XARCH}-DHAVE_X86 ${XARCH}-isysroot${CMAKE_IOS_SIMULATOR_SYSROOT}")

            # Always force -mmacosx-version-min to override environement variable
            SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} ${XARCH}-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
            SET(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} ${XARCH}-Wl,-macosx_version_min,${CMAKE_OSX_DEPLOYMENT_TARGET}")
          ENDIF(CMAKE_IOS_SIMULATOR_SYSROOT AND TARGET_X86)
        ELSE(IOS)
          IF(NOT CMAKE_OSX_ARCHITECTURES)
            IF(TARGET_CPU STREQUAL "x86")
              SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -arch i386 -Xarch_i386 -DHAVE_X86")
              SET(TARGET_X86 1)
            ENDIF(TARGET_CPU STREQUAL "x86")

            IF(TARGET_CPU STREQUAL "x86_64")
              SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -arch x86_64 -Xarch_x86_64 -DHAVE_X64")
              SET(TARGET_X64 1)
            ENDIF(TARGET_CPU STREQUAL "x86_64")
          ENDIF(NOT CMAKE_OSX_ARCHITECTURES)

          FOREACH(_SDK ${_CMAKE_OSX_SDKS})
            IF(${_SDK} MATCHES "MacOSX${CMAKE_OSX_DEPLOYMENT_TARGET}\\.sdk")
              SET(CMAKE_OSX_SYSROOT ${_SDK} CACHE PATH "" FORCE)
            ENDIF(${_SDK} MATCHES "MacOSX${CMAKE_OSX_DEPLOYMENT_TARGET}\\.sdk")
          ENDFOREACH(_SDK)

          IF(CMAKE_OSX_SYSROOT)
            SET(PLATFORM_CFLAGS "-isysroot ${CMAKE_OSX_SYSROOT} ${PLATFORM_CFLAGS}")
          ELSE(CMAKE_OSX_SYSROOT)
            MESSAGE(FATAL_ERROR "CMAKE_OSX_SYSROOT can't be determinated")
          ENDIF(CMAKE_OSX_SYSROOT)

          # Always force -mmacosx-version-min to override environement variable
          SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
          SET(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} -Wl,-macosx_version_min,${CMAKE_OSX_DEPLOYMENT_TARGET}")
        ENDIF(IOS)

        SET(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} -Wl,-headerpad_max_install_names")

        IF(HAVE_FLAG_SEARCH_PATHS_FIRST)
          SET(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} -Wl,-search_paths_first")
        ENDIF(HAVE_FLAG_SEARCH_PATHS_FIRST)
      ENDIF(XCODE)
    ENDIF(APPLE)

    IF(APPLE)
      IF(NOT XCODE)
      ENDIF(NOT XCODE)
    ELSE(APPLE)
      IF(HOST_CPU STREQUAL "x86_64" AND TARGET_CPU STREQUAL "x86")
        SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -m32 -march=i686")
      ENDIF(HOST_CPU STREQUAL "x86_64" AND TARGET_CPU STREQUAL "x86")

      IF(HOST_CPU STREQUAL "x86" AND TARGET_CPU STREQUAL "x86_64")
        SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -m64")
      ENDIF(HOST_CPU STREQUAL "x86" AND TARGET_CPU STREQUAL "x86_64")
    ENDIF(APPLE)

    SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -D_REENTRANT")

    IF(WITH_LOGGING)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -DENABLE_LOGS")
    ENDIF(WITH_LOGGING)

    IF(WITH_COVERAGE)
      SET(PLATFORM_CFLAGS "-fprofile-arcs -ftest-coverage ${PLATFORM_CFLAGS}")
    ENDIF(WITH_COVERAGE)

    IF(WITH_WARNINGS)
      SET(PLATFORM_CFLAGS "-Wall ${PLATFORM_CFLAGS}")
      IF(CLANG)
        SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -std=gnu99")
      ELSE(CLANG)
        SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -ansi")
      ENDIF(CLANG)
    ENDIF(WITH_WARNINGS)

    IF(ANDROID)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -I${NDKROOT}/platforms/android-${ANDROID_SDK}/usr/include")
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fomit-frame-pointer -fno-strict-aliasing -finline-limit=64")
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -DANDROID -D__ARM_ARCH_5__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5TE__")
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -Wno-psabi -Wa,--noexecstack")

# -Wl,-soname,libnative-activity.so
# -llog -landroid -lEGL -lGLESv1_CM -llog -lc -lm

      IF(TARGET_ARM)
        SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -mthumb")
        IF(TARGET_ARMV7)
          SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -march=armv7-a -mfloat-abi=softfp -mfpu=vfp")
        ELSE(TARGET_ARMV7)
          SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -march=armv5te -mtune=xscale -msoft-float")
        ENDIF(TARGET_ARMV7)
      ENDIF(TARGET_ARM)
      SET(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} --sysroot=${NDKROOT}/platforms/android-${ANDROID_SDK}/arch-arm")
      SET(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} -L${NDKROOT}/platforms/android-${ANDROID_SDK}/arch-arm/usr/lib")
      SET(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} -Wl,-z,noexecstack")
    ENDIF(ANDROID)

    # Fix "relocation R_X86_64_32 against.." error on x64 platforms
    IF(TARGET_X64 AND WITH_STATIC AND NOT WITH_STATIC_PLUGINS)
      SET(PLATFORM_CFLAGS "-fPIC ${PLATFORM_CFLAGS}")
    ENDIF(TARGET_X64 AND WITH_STATIC AND NOT WITH_STATIC_PLUGINS)

    IF(WITH_VISIBILITY_HIDDEN AND NOT XCODE)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -fvisibility=hidden")
    ENDIF(WITH_VISIBILITY_HIDDEN AND NOT XCODE)

    SET(PLATFORM_CXXFLAGS ${PLATFORM_CFLAGS})

    IF(WITH_VISIBILITY_HIDDEN AND NOT XCODE)
      SET(PLATFORM_CXXFLAGS "${PLATFORM_CXXFLAGS} -fvisibility-inlines-hidden")
    ENDIF(WITH_VISIBILITY_HIDDEN AND NOT XCODE)

    # Exceptions are only set for C++
    IF(WITH_EXCEPTIONS)
      SET(PLATFORM_CXXFLAGS "${PLATFORM_CXXFLAGS} -fexceptions")
    ELSE(WITH_EXCEPTIONS)
      SET(PLATFORM_CXXFLAGS "${PLATFORM_CXXFLAGS} -fno-exceptions -DBOOST_NO_EXCEPTIONS")
    ENDIF(WITH_EXCEPTIONS)

    # RTTI is only set for C++
    IF(WITH_RTTI)
      SET(PLATFORM_CXXFLAGS "${PLATFORM_CXXFLAGS} -frtti")
    ELSE(WITH_RTTI)
      SET(PLATFORM_CXXFLAGS "${PLATFORM_CXXFLAGS} -fno-rtti")
    ENDIF(WITH_RTTI)

    IF(NOT APPLE)
      SET(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} -Wl,--no-undefined -Wl,--as-needed")
    ENDIF(NOT APPLE)

    IF(WITH_SYMBOLS)
      SET(RELEASE_CFLAGS "${RELEASE_CFLAGS} -g")
    ENDIF(WITH_SYMBOLS)

    SET(DEBUG_CFLAGS "-D_DEBUG -g -DDEBUG ${DEBUG_CFLAGS}")
    SET(RELEASE_CFLAGS "-DNDEBUG -O3 ${RELEASE_CFLAGS}")
    SET(DEBUG_LINKFLAGS "${DEBUG_LINKFLAGS}")
    SET(RELEASE_LINKFLAGS "${RELEASE_LINKFLAGS}")
  ENDIF(MSVC)

  INCLUDE(PCHSupport OPTIONAL)

  SET(BUILD_FLAGS_INIT ON)
ENDMACRO(INIT_BUILD_FLAGS)

MACRO(SETUP_BUILD_FLAGS)
  IF(NOT BUILD_FLAGS_INIT)
    INIT_BUILD_FLAGS()
  ENDIF(NOT BUILD_FLAGS_INIT)

  SET(CMAKE_C_FLAGS ${PLATFORM_CFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_CXX_FLAGS ${PLATFORM_CXXFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_EXE_LINKER_FLAGS ${PLATFORM_LINKFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_MODULE_LINKER_FLAGS ${PLATFORM_LINKFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_SHARED_LINKER_FLAGS ${PLATFORM_LINKFLAGS} CACHE STRING "" FORCE)

  ## Debug
  SET(CMAKE_C_FLAGS_DEBUG ${DEBUG_CFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_CXX_FLAGS_DEBUG ${DEBUG_CFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_EXE_LINKER_FLAGS_DEBUG ${DEBUG_LINKFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_MODULE_LINKER_FLAGS_DEBUG ${DEBUG_LINKFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_SHARED_LINKER_FLAGS_DEBUG ${DEBUG_LINKFLAGS} CACHE STRING "" FORCE)

  ## Release
  SET(CMAKE_C_FLAGS_RELEASE ${RELEASE_CFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_CXX_FLAGS_RELEASE ${RELEASE_CFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_EXE_LINKER_FLAGS_RELEASE ${RELEASE_LINKFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_MODULE_LINKER_FLAGS_RELEASE ${RELEASE_LINKFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_SHARED_LINKER_FLAGS_RELEASE ${RELEASE_LINKFLAGS} CACHE STRING "" FORCE)

  SET(BUILD_FLAGS_SETUP ON)
ENDMACRO(SETUP_BUILD_FLAGS)

MACRO(SETUP_PREFIX_PATHS name)
  IF(NOT BUILD_FLAGS_SETUP)
    SETUP_BUILD_FLAGS()
  ENDIF(NOT BUILD_FLAGS_SETUP)

  IF(UNIX)
    ## Allow override of install_prefix/etc path.
    IF(NOT ETC_PREFIX)
      SET(ETC_PREFIX "etc/${name}")
      SET(ETC_FULL_PREFIX "${CMAKE_INSTALL_PREFIX}/${ETC_PREFIX}")
    ELSE(NOT ETC_PREFIX)
      SET(ETC_FULL_PREFIX ${ETC_PREFIX})
    ENDIF(NOT ETC_PREFIX)

    ## Allow override of install_prefix/share path.
    IF(NOT SHARE_PREFIX)
      SET(SHARE_PREFIX "share/${name}")
      SET(SHARE_FULL_PREFIX "${CMAKE_INSTALL_PREFIX}/${SHARE_PREFIX}")
    ELSE(NOT SHARE_PREFIX)
      SET(SHARE_FULL_PREFIX ${SHARE_PREFIX})
    ENDIF(NOT SHARE_PREFIX)

    ## Allow override of install_prefix/sbin path.
    IF(NOT SBIN_PREFIX)
      SET(SBIN_PREFIX "sbin")
      SET(SBIN_FULL_PREFIX "${CMAKE_INSTALL_PREFIX}/${SBIN_PREFIX}")
    ELSE(NOT SBIN_PREFIX)
      SET(SBIN_FULL_PREFIX ${SBIN_PREFIX})
    ENDIF(NOT SBIN_PREFIX)

    ## Allow override of install_prefix/bin path.
    IF(NOT BIN_PREFIX)
      SET(BIN_PREFIX "bin")
      SET(BIN_FULL_PREFIX "${CMAKE_INSTALL_PREFIX}/${BIN_PREFIX}")
    ELSE(NOT BIN_PREFIX)
      SET(BIN_FULL_PREFIX ${BIN_PREFIX})
    ENDIF(NOT BIN_PREFIX)

    ## Allow override of install_prefix/include path.
    IF(NOT INCLUDE_PREFIX)
      SET(INCLUDE_PREFIX "include")
      SET(INCLUDE_FULL_PREFIX "${CMAKE_INSTALL_PREFIX}/${INCLUDE_PREFIX}")
    ELSE(NOT INCLUDE_PREFIX)
      SET(INCLUDE_FULL_PREFIX ${INCLUDE_PREFIX})
    ENDIF(NOT INCLUDE_PREFIX)

    ## Allow override of install_prefix/lib path.
    IF(NOT LIB_PREFIX)
      IF(CMAKE_LIBRARY_ARCHITECTURE)
        SET(LIB_PREFIX "lib/${CMAKE_LIBRARY_ARCHITECTURE}")
      ELSE(CMAKE_LIBRARY_ARCHITECTURE)
        SET(LIB_PREFIX "lib")
      ENDIF(CMAKE_LIBRARY_ARCHITECTURE)
      SET(LIB_FULL_PREFIX "${CMAKE_INSTALL_PREFIX}/${LIB_PREFIX}")
    ELSE(NOT LIB_PREFIX)
      SET(LIB_FULL_PREFIX ${LIB_PREFIX})
    ENDIF(NOT LIB_PREFIX)

    ## Allow override of install_prefix/lib path.
    IF(NOT PLUGIN_PREFIX)
      IF(CMAKE_LIBRARY_ARCHITECTURE)
        SET(PLUGIN_PREFIX "lib/${CMAKE_LIBRARY_ARCHITECTURE}/${name}")
      ELSE(CMAKE_LIBRARY_ARCHITECTURE)
        SET(PLUGIN_PREFIX "lib/${name}")
      ENDIF(CMAKE_LIBRARY_ARCHITECTURE)
      SET(PLUGIN_FULL_PREFIX "${CMAKE_INSTALL_PREFIX}/${PLUGIN_PREFIX}")
    ELSE(NOT PLUGIN_PREFIX)
      SET(PLUGIN_FULL_PREFIX ${PLUGIN_PREFIX})
    ENDIF(NOT PLUGIN_PREFIX)

    # Aliases for automake compatibility
    SET(prefix ${CMAKE_INSTALL_PREFIX})
    SET(exec_prefix ${BIN_FULL_PREFIX})
    SET(libdir ${LIB_FULL_PREFIX})
    SET(includedir ${INCLUDE_FULL_PREFIX})
  ENDIF(UNIX)
  IF(WIN32)
    IF(TARGET_X64)
      SET(LIB_SUFFIX "64")
    ENDIF(TARGET_X64)

    IF(WITH_UNIX_STRUCTURE)
      SET(ETC_PREFIX "etc/${name}")
      SET(SHARE_PREFIX "share/${name}")
      SET(SBIN_PREFIX "bin${LIB_SUFFIX}")
      SET(BIN_PREFIX "bin${LIB_SUFFIX}")
      SET(INCLUDE_PREFIX "include")
      SET(LIB_PREFIX "lib${LIB_SUFFIX}") # static libs
      SET(PLUGIN_PREFIX "bin${LIB_SUFFIX}")
    ELSE(WITH_UNIX_STRUCTURE)
      SET(ETC_PREFIX ".")
      SET(SHARE_PREFIX ".")
      SET(SBIN_PREFIX ".")
      SET(BIN_PREFIX ".")
      SET(INCLUDE_PREFIX "include")
      SET(LIB_PREFIX "lib${LIB_SUFFIX}")
      SET(PLUGIN_PREFIX ".")
    ENDIF(WITH_UNIX_STRUCTURE)
    SET(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION ${BIN_PREFIX})
  ENDIF(WIN32)
ENDMACRO(SETUP_PREFIX_PATHS)

MACRO(SETUP_EXTERNAL)
  IF(NOT BUILD_FLAGS_SETUP)
    SETUP_BUILD_FLAGS()
  ENDIF(NOT BUILD_FLAGS_SETUP)

  IF(WIN32)
    FIND_PACKAGE(External REQUIRED)

    IF(MSVC10)
      IF(NOT MSVC10_REDIST_DIR)
        # If you have VC++ 2010 Express, put x64/Microsoft.VC100.CRT/*.dll in ${EXTERNAL_PATH}/redist
        SET(MSVC10_REDIST_DIR "${EXTERNAL_PATH}/redist")
      ENDIF(NOT MSVC10_REDIST_DIR)

      IF(NOT VC_DIR)
        IF(NOT VC_ROOT_DIR)
          GET_FILENAME_COMPONENT(VC_ROOT_DIR "[HKEY_CURRENT_USER\\Software\\Microsoft\\VisualStudio\\10.0_Config;InstallDir]" ABSOLUTE)
          # VC_ROOT_DIR is set to "registry" when a key is not found
          IF(VC_ROOT_DIR MATCHES "registry")
            GET_FILENAME_COMPONENT(VC_ROOT_DIR "[HKEY_CURRENT_USER\\Software\\Microsoft\\VCExpress\\10.0_Config;InstallDir]" ABSOLUTE)
            IF(VC_ROOT_DIR MATCHES "registry")
              SET(VS100COMNTOOLS $ENV{VS100COMNTOOLS})
              IF(VS100COMNTOOLS)
                FILE(TO_CMAKE_PATH ${VS100COMNTOOLS} VC_ROOT_DIR)
              ENDIF(VS100COMNTOOLS)
              IF(NOT VC_ROOT_DIR)
                MESSAGE(FATAL_ERROR "Unable to find VC++ 2010 directory!")
              ENDIF(NOT VC_ROOT_DIR)
            ENDIF(VC_ROOT_DIR MATCHES "registry")
          ENDIF(VC_ROOT_DIR MATCHES "registry")
        ENDIF(NOT VC_ROOT_DIR)
        # convert IDE fullpath to VC++ path
        STRING(REGEX REPLACE "Common7/.*" "VC" VC_DIR ${VC_ROOT_DIR})
      ENDIF(NOT VC_DIR)
    ELSE(MSVC10)
      IF(NOT VC_DIR)
        IF(${CMAKE_MAKE_PROGRAM} MATCHES "Common7")
          # convert IDE fullpath to VC++ path
          STRING(REGEX REPLACE "Common7/.*" "VC" VC_DIR ${CMAKE_MAKE_PROGRAM})
        ELSE(${CMAKE_MAKE_PROGRAM} MATCHES "Common7")
          # convert compiler fullpath to VC++ path
          STRING(REGEX REPLACE "VC/bin/.+" "VC" VC_DIR ${CMAKE_CXX_COMPILER})
        ENDIF(${CMAKE_MAKE_PROGRAM} MATCHES "Common7")
      ENDIF(NOT VC_DIR)
    ENDIF(MSVC10)
  ELSE(WIN32)
    FIND_PACKAGE(External QUIET)

    IF(APPLE)
      IF(WITH_STATIC_EXTERNAL)
        # Look only for static libraries because systems libraries are using Frameworks
        SET(CMAKE_FIND_LIBRARY_SUFFIXES .a)
      ELSE(WITH_STATIC_EXTERNAL)
        SET(CMAKE_FIND_LIBRARY_SUFFIXES .dylib .so .a)
      ENDIF(WITH_STATIC_EXTERNAL)
    ELSE(APPLE)
      IF(WITH_STATIC_EXTERNAL)
        SET(CMAKE_FIND_LIBRARY_SUFFIXES .a .so)
      ELSE(WITH_STATIC_EXTERNAL)
        SET(CMAKE_FIND_LIBRARY_SUFFIXES .so .a)
      ENDIF(WITH_STATIC_EXTERNAL)
    ENDIF(APPLE)
  ENDIF(WIN32)

  IF(WITH_STLPORT)
    FIND_PACKAGE(STLport REQUIRED)
    INCLUDE_DIRECTORIES(${STLPORT_INCLUDE_DIR})
    IF(MSVC)
      SET(VC_INCLUDE_DIR "${VC_DIR}/include")

      FIND_PACKAGE(WindowsSDK REQUIRED)
      # use VC++ and Windows SDK include paths
      INCLUDE_DIRECTORIES(${VC_INCLUDE_DIR} ${WINSDK_INCLUDE_DIR})
    ENDIF(MSVC)
  ENDIF(WITH_STLPORT)
ENDMACRO(SETUP_EXTERNAL)

MACRO(FIND_PACKAGE_HELPER NAME INCLUDE RELEASE DEBUG)
  # Looks for a directory containing NAME.
  #
  # NAME is the name of the library, lowercase and uppercase can be mixed
  # It should be EXACTLY (same case) the same part as XXXX in FindXXXX.cmake
  #
  # INCLUDE is the file to check for includes
  # RELEASE is the list of libraries to check in release mode
  # DEBUG is the list of libraries to check in debug mode
  # SUFFIXES (optional) is the PATH_SUFFIXES to check for include file
  #
  # For DEBUG and RELEASE, several names can be separated by semi-columns or spaces.
  # The first match will be used in the specified order and next matches will be ignored
  #
  # The following values are defined
  # NAME_INCLUDE_DIR - where to find NAME
  # NAME_LIBRARIES   - link against these to use NAME
  # NAME_FOUND       - True if NAME is available.

  # Fixes names if invalid characters are found  
  IF("${NAME}" MATCHES "^[a-zA-Z0-9]+$")
    SET(NAME_FIXED ${NAME})
  ELSE("${NAME}" MATCHES "^[a-zA-Z0-9]+$")
    # if invalid characters are detected, replace them by valid ones
    STRING(REPLACE "+" "p" NAME_FIXED ${NAME})
  ENDIF("${NAME}" MATCHES "^[a-zA-Z0-9]+$")

  # Create uppercase and lowercase versions of NAME
  STRING(TOUPPER ${NAME} UPNAME)
  STRING(TOLOWER ${NAME} LOWNAME)

  STRING(TOUPPER ${NAME_FIXED} UPNAME_FIXED)
  STRING(TOLOWER ${NAME_FIXED} LOWNAME_FIXED)

  SET(SUFFIXES)

  FOREACH(_ARG ${ARGN})
    IF(_ARG STREQUAL "QUIET")
      SET(${NAME}_FIND_QUIETLY ON)
    ELSE(_ARG STREQUAL "QUIET")
      SET(SUFFIXES ${_ARG})
    ENDIF(_ARG STREQUAL "QUIET")
  ENDFOREACH(_ARG)

  IF(NOT SUFFIXES)
    SET(SUFFIXES ${LOWNAME} ${LOWNAME_FIXED} ${NAME})
  ENDIF(NOT SUFFIXES)

  # Replace spaces by semi-columns to fix a bug
  STRING(REPLACE " " ";" RELEASE_FIXED ${RELEASE})
  STRING(REPLACE " " ";" DEBUG_FIXED ${DEBUG})

  IF(NOT WIN32 AND NOT IOS)
    FIND_PACKAGE(PkgConfig QUIET)
    SET(MODULES ${LOWNAME} ${RELEASE_FIXED})
    LIST(REMOVE_DUPLICATES MODULES)
    IF(PKG_CONFIG_EXECUTABLE)
      PKG_SEARCH_MODULE(PKG_${NAME_FIXED} ${MODULES})
    ENDIF(PKG_CONFIG_EXECUTABLE)
  ENDIF(NOT WIN32 AND NOT IOS)

  SET(INCLUDE_PATHS)
  SET(LIBRARY_PATHS)

  IF(DEFINED ${UPNAME_FIXED}_DIR)
    LIST(APPEND INCLUDE_PATHS ${${UPNAME_FIXED}_DIR}/include ${${UPNAME_FIXED}_DIR})
    LIST(APPEND LIBRARY_PATHS ${${UPNAME_FIXED}_DIR}/lib${LIB_SUFFIX})
  ENDIF(DEFINED ${UPNAME_FIXED}_DIR)

  IF(DEFINED ${UPNAME}_DIR)
    LIST(APPEND INCLUDE_PATHS ${${UPNAME}_DIR}/include ${${UPNAME}_DIR})
    LIST(APPEND LIBRARY_PATHS ${${UPNAME}_DIR}/lib${LIB_SUFFIX})
  ENDIF(DEFINED ${UPNAME}_DIR)

  SET(LIBRARY_PATHS ${LIBRARY_PATHS}
    $ENV{${UPNAME}_DIR}/lib${LIB_SUFFIX}
    $ENV{${UPNAME_FIXED}_DIR}/lib${LIB_SUFFIX})

  # Search for include directory
  FIND_PATH(${UPNAME_FIXED}_INCLUDE_DIR 
    ${INCLUDE}
    HINTS ${PKG_${NAME_FIXED}_INCLUDE_DIRS}
    PATHS
    ${INCLUDE_PATHS}
    $ENV{${UPNAME}_DIR}/include
    $ENV{${UPNAME_FIXED}_DIR}/include
    $ENV{${UPNAME}_DIR}
    $ENV{${UPNAME_FIXED}_DIR}
    /usr/local/include
    /usr/include
    /sw/include
    /opt/local/include
    /opt/csw/include
    /opt/include
    PATH_SUFFIXES
    ${SUFFIXES}
  )

  IF(CMAKE_LIBRARY_ARCHITECTURE)
    SET(LIBRARY_PATHS "/lib/${CMAKE_LIBRARY_ARCHITECTURE};/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}")
  ENDIF(CMAKE_LIBRARY_ARCHITECTURE)

  IF(UNIX)
    SET(LIBRARY_PATHS ${LIBRARY_PATHS}
      /usr/local/lib
      /usr/lib
      /usr/local/X11R6/lib
      /usr/X11R6/lib
      /sw/lib
      /opt/local/lib
      /opt/csw/lib
      /opt/lib
      /usr/freeware/lib${LIB_SUFFIX})
  ENDIF(UNIX)

  # Search for release library
  FIND_LIBRARY(${UPNAME_FIXED}_LIBRARY_RELEASE
    NAMES
    ${RELEASE_FIXED}
    HINTS ${PKG_${NAME_FIXED}_LIBRARY_DIRS}
    PATHS
    ${LIBRARY_PATHS}
    NO_CMAKE_SYSTEM_PATH
  )

  # Search for debug library
  FIND_LIBRARY(${UPNAME_FIXED}_LIBRARY_DEBUG
    NAMES
    ${DEBUG_FIXED}
    HINTS ${PKG_${NAME_FIXED}_LIBRARY_DIRS}
    PATHS
    ${LIBRARY_PATHS}
    NO_CMAKE_SYSTEM_PATH
  )

  IF(${UPNAME_FIXED}_INCLUDE_DIR)
    IF(${UPNAME_FIXED}_LIBRARY_RELEASE)
      # Set also _INCLUDE_DIRS
      SET(${UPNAME_FIXED}_INCLUDE_DIRS ${${UPNAME_FIXED}_INCLUDE_DIR})
      # Library has been found if only one library and include are found
      SET(${UPNAME_FIXED}_FOUND TRUE)
      SET(${UPNAME_FIXED}_LIBRARIES ${${UPNAME_FIXED}_LIBRARY_RELEASE})
      SET(${UPNAME_FIXED}_LIBRARY ${${UPNAME_FIXED}_LIBRARY_RELEASE})
      IF(${UPNAME_FIXED}_LIBRARY_DEBUG)
        # If debug version is found, use the right one
        SET(${UPNAME_FIXED}_LIBRARIES optimized ${${UPNAME_FIXED}_LIBRARIES} debug ${${UPNAME_FIXED}_LIBRARY_DEBUG})
      ENDIF(${UPNAME_FIXED}_LIBRARY_DEBUG)
    ENDIF(${UPNAME_FIXED}_LIBRARY_RELEASE)
  ENDIF(${UPNAME_FIXED}_INCLUDE_DIR)

  IF(${UPNAME_FIXED}_FOUND)
    IF(NOT ${NAME}_FIND_QUIETLY)
      MESSAGE(STATUS "Found ${NAME}: ${${UPNAME_FIXED}_LIBRARIES}")
    ENDIF(NOT ${NAME}_FIND_QUIETLY)
  ELSE(${UPNAME_FIXED}_FOUND)
    IF(${NAME}_FIND_REQUIRED)
      MESSAGE(FATAL_ERROR "Error: Unable to find ${NAME}!")
    ENDIF(${NAME}_FIND_REQUIRED)
    IF(NOT ${NAME}_FIND_QUIETLY)
      MESSAGE(STATUS "Warning: Unable to find ${NAME}!")
    ENDIF(NOT ${NAME}_FIND_QUIETLY)
  ENDIF(${UPNAME_FIXED}_FOUND)

  MARK_AS_ADVANCED(${UPNAME_FIXED}_LIBRARY_RELEASE ${UPNAME_FIXED}_LIBRARY_DEBUG)
ENDMACRO(FIND_PACKAGE_HELPER)

MACRO(MESSAGE_VERSION_PACKAGE_HELPER NAME LIBRARIES VERSION)
  MESSAGE(STATUS "Found ${NAME}: ${LIBRARIES} (found version ${VERSION})")
ENDMACRO(MESSAGE_VERSION_PACKAGE_HELPER)
