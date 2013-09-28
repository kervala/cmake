# Globals variables
# QT
# QT4 or QT5
# QT_BINARY_DIR
# QT_TRANSLATIONS_DIR
# QT_PLUGINS_DIR
# QT_TSS => QT_QMS
# QT_UIS => QT_UIS_HEADERS
# QT_QRCS => QT_QRCS_CPPS
# headers => QT_MOCS_CPPS
# QT_SOURCES
# QT_LANGS
# QT_SHARED_MODULES
# QT4_MODULES
# QT5_MODULES
# QT_MODULES_WANTED
# QT_MODULES_USED

# Force Debug configuration if launched from Qt Creator
IF(NOT CMAKE_BUILD_TYPE AND DESKTOP_FILE MATCHES "qtcreator")
  SET(CMAKE_BUILD_TYPE "Debug" CACHE STRING "" FORCE)
ENDIF(NOT CMAKE_BUILD_TYPE AND DESKTOP_FILE MATCHES "qtcreator")

MACRO(INIT_QT)
  # Init all variables needed by Qt
  SET(QT_SOURCES)
  SET(QT_LANGS)
  SET(QT_MOCS)
  SET(QT_MOCS_CPPS)
  SET(QT_UIS)
  SET(QT_UIS_HEADERS)
  SET(QT_QRCS)
  SET(QT_QRCS_CPPS)
  SET(QT_TSS)
  SET(QT_QMS)
  
  # Regex filter for Qt files
  SET(QT_FILES_FILTER "\\.(ts|qrc|ui)$")
ENDMACRO(INIT_QT)

MACRO(USE_QT_MODULES)
  OPTION(WITH_QT5 "Use Qt 5 instead of Qt 4" ON)

  SET(QT_MODULES_WANTED ${ARGN})
  SET(QT_MODULES_USED)
  SET(QT OFF)
  SET(QT4 OFF)
  SET(QT5 OFF)

  # Qt shared modules
  SET(QT_SHARED_MODULES CLucene Core Gui Help Multimedia Network OpenGL Qml Script ScriptTools Sql Svg Test WebKit Xml XmlPatterns)

  # Qt 4 modules
  SET(QT4_MODULES ${QT_SHARED_MODULES} Main Declarative)

  # Qt 5 modules
  SET(QT5_MODULES ${QT_SHARED_MODULES} Concurrent LinguistTools MultimediaQuick MultimediaWidgets PrintSupport Quick QuickParticles QuickTest Sensors SerialPort V8 Widgets WebKitWidgets)
  
  IF(WITH_QT5)
    # Look for Qt 5 in some environment variables
    SET(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} $ENV{QT5DIR})
    FIND_PACKAGE(Qt5Core QUIET)

    IF(Qt5Core_FOUND)
      LIST(APPEND QT_MODULES_WANTED Core LinguistTools Concurrent)
      LIST(REMOVE_DUPLICATES QT_MODULES_WANTED)
      FOREACH(_MODULE ${QT_MODULES_WANTED})
        IF(QT5_MODULES MATCHES ${_MODULE})
          FIND_PACKAGE(Qt5${_MODULE} REQUIRED)
          IF("${Qt5${_MODULE}_FOUND}")
            LIST(APPEND QT_MODULES_USED ${_MODULE})
            SET(QT5 ON)
            SET(QT ON)
          ENDIF("${Qt5${_MODULE}_FOUND}")
        ENDIF(QT5_MODULES MATCHES ${_MODULE})
      ENDFOREACH(_MODULE)
    ELSE(Qt5Core_FOUND)
      SET(WITH_QT5 OFF)
    ENDIF(Qt5Core_FOUND)
  ENDIF(WITH_QT5)

  IF(NOT WITH_QT5)
    LIST(APPEND QT_MODULES_WANTED Main Core)
    LIST(REMOVE_DUPLICATES QT_MODULES_WANTED)
    FOREACH(_MODULE ${QT_MODULES_WANTED})
      IF(QT4_MODULES MATCHES ${_MODULE})
        LIST(APPEND _COMPONENTS Qt${_MODULE})
      ENDIF(QT4_MODULES MATCHES ${_MODULE})
    ENDFOREACH(_MODULE)
    FIND_PACKAGE(Qt4 COMPONENTS ${_COMPONENTS} REQUIRED)
    INCLUDE(${QT_USE_FILE})
    FOREACH(_MODULE ${QT_MODULES_WANTED})
      STRING(TOUPPER ${_MODULE} _UP_MODULE_NAME)
      IF("${QT_USE_QT${_UP_MODULE_NAME}}")
        LIST(APPEND QT_MODULES_USED ${_MODULE})
        SET(QT4 ON)
        SET(QT ON)
      ENDIF("${QT_USE_QT${_UP_MODULE_NAME}}")
    ENDFOREACH(_MODULE)
  ENDIF(NOT WITH_QT5)

  IF(QT5)
    MESSAGE(STATUS "Found Qt ${Qt5Core_VERSION_STRING}")

    # These variables are not defined with Qt5 CMake modules
    SET(QT_BINARY_DIR "${_qt5Core_install_prefix}/bin")
    SET(QT_LIBRARY_DIR "${_qt5Core_install_prefix}/lib")
    SET(QT_PLUGINS_DIR "${_qt5Core_install_prefix}/plugins")
    SET(QT_TRANSLATIONS_DIR "${_qt5Core_install_prefix}/translations")

    # Fix wrong include directories with Qt 5 under Mac OS X
    INCLUDE_DIRECTORIES("${_qt5Core_install_prefix}/include")
  ENDIF(QT5)
ENDMACRO(USE_QT_MODULES)

MACRO(FILTER_QT_FILES FILE)
  IF(QT)
    IF(${FILE} MATCHES "\\.ts$")
      STRING(REGEX REPLACE "^.*_([a-z-]*)\\.ts$" "\\1" _LANG ${FILE})
      LIST(APPEND QT_LANGS ${_LANG})
      LIST(APPEND QT_TSS ${FILE})
    ELSEIF(${FILE} MATCHES "\\.qrc$")
      LIST(APPEND QT_QRCS ${FILE})
    ELSEIF(${FILE} MATCHES "\\.ui$")
      LIST(APPEND QT_UIS ${FILE})
    ENDIF(${FILE} MATCHES "\\.ts$")
  ENDIF(QT)
ENDMACRO(FILTER_QT_FILES)

MACRO(COMPILE_QT_RESOURCES)
  IF(QT_QRCS)
    # Generate .cpp from .qrc
    IF(QT5)
      QT5_ADD_RESOURCES(QT_QRCS_CPPS ${QT_QRCS})
    ELSE(QT5)
      QT4_ADD_RESOURCES(QT_QRCS_CPPS ${QT_QRCS})
    ENDIF(QT5)
  ENDIF(QT_QRCS)
ENDMACRO(COMPILE_QT_RESOURCES)

MACRO(COMPILE_QT_UIS)
  IF(QT_UIS)
    # Generate .h from .ui
    IF(QT5)
      QT5_WRAP_UI(QT_UIS_HEADERS ${QT_UIS})
    ELSE(QT5)
      QT4_WRAP_UI(QT_UIS_HEADERS ${QT_UIS})
    ENDIF(QT5)

    SOURCE_GROUP("ui" FILES ${QT_UIS})
  ENDIF(QT_UIS)
ENDMACRO(COMPILE_QT_UIS)

MACRO(COMPILE_QT_HEADERS _TARGET)
  IF(QT)
    IF(CMAKE_AUTOMOC)
      SET(QT_MOCS_CPPS "${CMAKE_CURRENT_BINARY_DIR}/${_TARGET}_automoc.cpp")
      SET_SOURCE_FILES_PROPERTIES(${QT_MOCS_CPPS} PROPERTIES GENERATED TRUE)
    ELSE(CMAKE_AUTOMOC)
      SET(_FILES "${ARGN}")
      IF(_FILES)
        # Generate .cpp from .h witout notice messages
        IF(QT5)
          QT5_WRAP_CPP(QT_MOCS_CPPS ${_FILES} OPTIONS -nn)
        ELSE(QT5)
          QT4_WRAP_CPP(QT_MOCS_CPPS ${_FILES} OPTIONS -nn)
        ENDIF(QT5)
      ENDIF(_FILES)
    ENDIF(CMAKE_AUTOMOC)
  ENDIF(QT)
ENDMACRO(COMPILE_QT_HEADERS)

MACRO(COMPILE_QT_TRANSLATIONS)
  IF(QT_TSS)
    SET_SOURCE_FILES_PROPERTIES(${QT_TSS} PROPERTIES OUTPUT_LOCATION "${CMAKE_BINARY_DIR}/translations")

    IF(WITH_UPDATE_TRANSLATIONS)
      SET(_TRANS ${ARGN} ${QT_UIS})
      IF(QT5)
        QT5_CREATE_TRANSLATION(QT_QMS ${_TRANS} ${QT_TSS})
      ELSE(QT5)
        QT4_CREATE_TRANSLATION(QT_QMS ${_TRANS} ${QT_TSS})
      ENDIF(QT5)
    ELSE(WITH_UPDATE_TRANSLATIONS)
      IF(QT5)
        QT5_ADD_TRANSLATION(QT_QMS ${QT_TSS})
      ELSE(QT5)
        QT4_ADD_TRANSLATION(QT_QMS ${QT_TSS})
      ENDIF(QT5)
    ENDIF(WITH_UPDATE_TRANSLATIONS)

    SOURCE_GROUP("translations" FILES ${QT_TSS})
  ENDIF(QT_TSS)
ENDMACRO(COMPILE_QT_TRANSLATIONS)

MACRO(SET_QT_SOURCES)
  IF(QT)
    # Qt generated files
    SET(QT_SOURCES ${QT_MOCS_CPPS} ${QT_UIS_HEADERS} ${QT_QRCS_CPPS} ${QT_QMS})

    IF(QT_SOURCES)
      SOURCE_GROUP("generated" FILES ${QT_SOURCES})
      SET_SOURCES_FLAGS(${QT_SOURCES})
    ENDIF(QT_SOURCES)
  ENDIF(QT)
ENDMACRO(SET_QT_SOURCES)

MACRO(LINK_QT_LIBRARY _TARGET _NAME)
  IF(WIN32)
    SET(_PREFIX "Qt5")
    SET(_EXT "lib")
  ELSE(WIN32)
    SET(_PREFIX "libQt5")
    SET(_EXT "a")
  ENDIF(WIN32)
  SET(_LIB "${QT_LIBRARY_DIR}/${_PREFIX}${_NAME}.${_EXT}")
  IF(EXISTS ${_LIB})
    TARGET_LINK_LIBRARIES(${_TARGET} optimized ${_LIB})
  ENDIF(EXISTS ${_LIB})
  SET(_LIB "${QT_LIBRARY_DIR}/${_PREFIX}${_NAME}d.${_EXT}")
  IF(EXISTS ${_LIB})
    TARGET_LINK_LIBRARIES(${_TARGET} debug ${_LIB})
  ENDIF(EXISTS ${_LIB})
ENDMACRO(LINK_QT_LIBRARY)

MACRO(LINK_QT_PLUGIN _TARGET _TYPE _NAME)
  IF(WIN32)
    SET(_PREFIX "")
    SET(_EXT "lib")
  ELSE(WIN32)
    SET(_PREFIX "lib")
    SET(_EXT "a")
  ENDIF(WIN32)
  SET(_LIB "${QT_PLUGINS_DIR}/${_TYPE}/${_PREFIX}${_NAME}.${_EXT}")
  IF(EXISTS ${_LIB})
    TARGET_LINK_LIBRARIES(${_TARGET} optimized ${_LIB})
  ENDIF(EXISTS ${_LIB})
  SET(_LIB "${QT_PLUGINS_DIR}/${_TYPE}/${_PREFIX}${_NAME}d.${_EXT}")
  IF(EXISTS ${_LIB})
    TARGET_LINK_LIBRARIES(${_TARGET} debug ${_LIB})
  ENDIF(EXISTS ${_LIB})
ENDMACRO(LINK_QT_PLUGIN)

MACRO(LINK_QT_LIBRARIES _TARGET)
  IF(QT)
    IF(QT5)
      QT5_USE_MODULES(${_TARGET} ${QT_MODULES_USED})

      GET_TARGET_PROPERTY(_TYPE ${_TARGET} TYPE)

      # Link to QtMain
      IF(_TYPE STREQUAL EXECUTABLE AND CMAKE_VERSION VERSION_LESS "2.8.11")
        TARGET_LINK_LIBRARIES(${_TARGET} ${Qt5Core_QTMAIN_LIBRARIES})
      ENDIF(_TYPE STREQUAL EXECUTABLE AND CMAKE_VERSION VERSION_LESS "2.8.11")

      # Check if we are using Qt static or shared libraries
      GET_TARGET_PROPERTY(_FILE Qt5::Core IMPORTED_LOCATION_RELEASE)

      IF(_FILE MATCHES "\\.(lib|a)$")
        ADD_DEFINITIONS(-DQT_STATICPLUGIN)
      
        FIND_PACKAGE(MyPNG)
        FIND_PACKAGE(JPEG)

        TARGET_LINK_LIBRARIES(${_TARGET} ${PNG_LIBRARIES} ${JPEG_LIBRARIES})

        FOREACH(_MODULE ${QT_MODULES_USED})
          IF(_MODULE STREQUAL Core)
            LINK_QT_LIBRARY(${_TARGET} PrintSupport)
            LINK_QT_LIBRARY(${_TARGET} PlatformSupport)
            IF(WIN32)
              TARGET_LINK_LIBRARIES(${_TARGET}
                ${WINSDK_LIBRARY_DIR}/Imm32.lib
                ${WINSDK_LIBRARY_DIR}/WS2_32.Lib
                ${WINSDK_LIBRARY_DIR}/OpenGL32.lib
                ${WINSDK_LIBRARY_DIR}/WinMM.Lib)
              LINK_QT_PLUGIN(${_TARGET} platforms qwindows)
            ELSEIF(APPLE)
              FIND_LIBRARY(IOKIT_FRAMEWORK IOKit)
              FIND_LIBRARY(ICUUC_LIBRARY icuuc)
              FIND_LIBRARY(ICUI18N_LIBRARY icui18n)
              FIND_LIBRARY(PCRE16_LIBRARY pcre16)
              TARGET_LINK_LIBRARIES(${_TARGET}
                ${IOKIT_FRAMEWORK}
                ${ICUUC_LIBRARY}
                ${ICUI18N_LIBRARY}
                ${PCRE16_LIBRARY})
              LINK_QT_PLUGIN(${_TARGET} printsupport cocoaprintersupport)
              LINK_QT_PLUGIN(${_TARGET} platforms qcocoa)
            ENDIF(WIN32)
          ENDIF(_MODULE STREQUAL Core)
          IF(_MODULE STREQUAL Network)
            IF(WIN32)
              TARGET_LINK_LIBRARIES(${_TARGET} ${WINSDK_LIBRARY_DIR}/Crypt32.lib)
            ENDIF(WIN32)
          ENDIF(_MODULE STREQUAL Network)
          IF(_MODULE STREQUAL Gui)
            LINK_QT_PLUGIN(${_TARGET} imageformats qico)
            LINK_QT_PLUGIN(${_TARGET} imageformats qmng)
          ENDIF(_MODULE STREQUAL Gui)
          IF(_MODULE STREQUAL Multimedia)
            IF(WIN32)
              TARGET_LINK_LIBRARIES(${_TARGET} ${WINSDK_LIBRARY_DIR}/strmiids.lib)
            ENDIF(WIN32)
          ENDIF(_MODULE STREQUAL Multimedia)
          IF(_MODULE STREQUAL Widgets)
            LINK_QT_PLUGIN(${_TARGET} accessible qtaccessiblewidgets)
          ENDIF(_MODULE STREQUAL Widgets)
          IF(_MODULE STREQUAL Sql)
            LINK_QT_PLUGIN(${_TARGET} sqldrivers qsqlite)
          ENDIF(_MODULE STREQUAL Sql)
          IF(_MODULE STREQUAL Svg)
            LINK_QT_PLUGIN(${_TARGET} imageformats qsvg)
            LINK_QT_PLUGIN(${_TARGET} iconengines qsvgicon)
          ENDIF(_MODULE STREQUAL Svg)
        ENDFOREACH(_MODULE)
      ENDIF(_FILE MATCHES "\\.(lib|a)$")
    ENDIF(QT5)
    IF(QT4)
      TARGET_LINK_LIBRARIES(${_TARGET} ${QT_LIBRARIES})
    ENDIF(QT4)
  ENDIF(QT)
ENDMACRO(LINK_QT_LIBRARIES)

MACRO(INSTALL_QT_TRANSLATIONS _TARGET)
  IF(QT_QMS)
    IF(APPLE)
      ADD_CUSTOM_COMMAND(TARGET ${_TARGET} PRE_BUILD COMMAND mkdir -p ${RESOURCES_DIR}/translations)

      # Copying all Qt translations to bundle
      FOREACH(_QM ${QT_QMS})
        ADD_CUSTOM_COMMAND(TARGET ${_TARGET} POST_BUILD COMMAND cp ARGS ${_QM} ${RESOURCES_DIR}/translations)
      ENDFOREACH(_QM)
    ELSE(APPLE)
      # Install all applications Qt translations
      INSTALL(FILES ${QT_QMS} DESTINATION ${SHARE_PREFIX}/translations)
    ENDIF(APPLE)

    IF(WIN32 OR APPLE)
      # Copy Qt standard translations
      FOREACH(_LANG ${QT_LANGS})
        SET(LANG_FILE "${QT_TRANSLATIONS_DIR}/qt_${_LANG}.qm")
        IF(EXISTS ${LANG_FILE})
          IF(WIN32)
            INSTALL(FILES ${LANG_FILE} DESTINATION ${SHARE_PREFIX}/translations)
          ELSE(WIN32)
            ADD_CUSTOM_COMMAND(TARGET ${_TARGET} POST_BUILD COMMAND cp ARGS ${LANG_FILE} ${RESOURCES_DIR}/translations)
          ENDIF(WIN32)
        ENDIF(EXISTS ${LANG_FILE})
      ENDFOREACH(_LANG)
    ENDIF(WIN32 OR APPLE)
  ENDIF(QT_QMS)
ENDMACRO(INSTALL_QT_TRANSLATIONS)

MACRO(INSTALL_QT_LIBRARIES)
  IF(WIN32 AND QT)
    # Install Qt libraries
    FOREACH(_MODULE ${QT_MODULES_USED})
      IF(QT5)
        SET(_MODULE_NAME "Qt5${_MODULE}")
      ELSEIF(QT4)
        SET(_MODULE_NAME "Qt${_MODULE}4")
      ENDIF(QT5)
      
      # Library
      IF(EXISTS ${QT_BINARY_DIR}/${_MODULE_NAME}.dll)
        INSTALL(FILES "${QT_BINARY_DIR}/${_MODULE_NAME}.dll" DESTINATION ${BIN_PREFIX})
      ENDIF(EXISTS ${QT_BINARY_DIR}/${_MODULE_NAME}.dll)
      
      # Plugins
      IF(QT4)
        IF(_MODULE STREQUAL Gui)
          INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qgif4.dll" DESTINATION ${BIN_PREFIX}/imageformats)
          INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qico4.dll" DESTINATION ${BIN_PREFIX}/imageformats)
          INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qjpeg4.dll" DESTINATION ${BIN_PREFIX}/imageformats)
        ENDIF(_MODULE STREQUAL Gui)
        IF(_MODULE STREQUAL Sql)
          INSTALL(FILES "${QT_PLUGINS_DIR}/sqldrivers/qsqlite4.dll" DESTINATION ${BIN_PREFIX}/sqldrivers)
        ENDIF(_MODULE STREQUAL Sql)
        IF(_MODULE STREQUAL Svg)
          INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qsvg4.dll" DESTINATION ${BIN_PREFIX}/imageformats)
          INSTALL(FILES "${QT_PLUGINS_DIR}/iconengines/qsvgicon4.dll" DESTINATION ${BIN_PREFIX}/iconengines)
        ENDIF(_MODULE STREQUAL Svg)
      ENDIF(QT4)

      IF(QT5)
        IF(_MODULE STREQUAL Core)
          INSTALL(FILES "${QT_PLUGINS_DIR}/platforms/qwindows.dll" DESTINATION ${BIN_PREFIX}/platforms)
        ENDIF(_MODULE STREQUAL Core)
        IF(_MODULE STREQUAL Gui)
          INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qico.dll" DESTINATION ${BIN_PREFIX}/imageformats)
          INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qgif.dll" DESTINATION ${BIN_PREFIX}/imageformats)
          INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qjpeg.dll" DESTINATION ${BIN_PREFIX}/imageformats)
        ENDIF(_MODULE STREQUAL Gui)
        IF(_MODULE STREQUAL Widgets)
          INSTALL(FILES "${QT_PLUGINS_DIR}/accessible/qtaccessiblewidgets.dll" DESTINATION ${BIN_PREFIX}/accessible)
        ENDIF(_MODULE STREQUAL Widgets)
        IF(_MODULE STREQUAL Sql)
          INSTALL(FILES "${QT_PLUGINS_DIR}/sqldrivers/qsqlite.dll" DESTINATION ${BIN_PREFIX}/sqldrivers)
        ENDIF(_MODULE STREQUAL Sql)
        IF(_MODULE STREQUAL Svg)
          INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qsvg.dll" DESTINATION ${BIN_PREFIX}/imageformats)
          INSTALL(FILES "${QT_PLUGINS_DIR}/iconengines/qsvgicon.dll" DESTINATION ${BIN_PREFIX}/iconengines)
        ENDIF(_MODULE STREQUAL Svg)
      ENDIF(QT5)
    ENDFOREACH(_MODULE)

    # Install zlib DLL if found in Qt directory
    IF(EXISTS "${QT_BINARY_DIR}/zlib1.dll")
      INSTALL(FILES "${QT_BINARY_DIR}/zlib1.dll" DESTINATION ${BIN_PREFIX})
    ENDIF(EXISTS "${QT_BINARY_DIR}/zlib1.dll")

    # Install OpenSSL libraries
    FOREACH(_ARG ${EXTERNAL_BINARY_PATH})
      IF(EXISTS "${_ARG}/libeay32.dll")
        INSTALL(FILES
          "${_ARG}/libeay32.dll"
          "${_ARG}/ssleay32.dll"
          DESTINATION ${BIN_PREFIX})
      ENDIF(EXISTS "${_ARG}/libeay32.dll")
    ENDFOREACH(_ARG)
  ENDIF(WIN32 AND QT)
ENDMACRO(INSTALL_QT_LIBRARIES)

MACRO(INSTALL_QT_MISC _TARGET)
  IF(QT4)
    # Copying qt_menu.nib to bundle
    IF(APPLE AND MAC_RESOURCES_DIR)
      ADD_CUSTOM_COMMAND(TARGET ${_TARGET} POST_BUILD COMMAND cp -R ARGS ${MAC_RESOURCES_DIR}/qt_menu.nib ${RESOURCES_DIR})
    ENDIF(APPLE AND MAC_RESOURCES_DIR)
  ENDIF(QT4)
ENDMACRO(INSTALL_QT_MISC)
