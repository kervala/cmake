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
# QT_MODULES

# Force Debug configuration if launched from Qt Creator
IF(NOT CMAKE_BUILD_TYPE AND DESKTOP_FILE MATCHES "qtcreator")
  SET(CMAKE_BUILD_TYPE "Debug" CACHE STRING "" FORCE)
ENDIF(NOT CMAKE_BUILD_TYPE AND DESKTOP_FILE MATCHES "qtcreator")

# Look for Qt 4 and 5 in some environment variables
SET(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} $ENV{QT5DIR} $ENV{QT4DIR} $ENV{QTDIR})

MACRO(DETECT_QT_VERSION)
  SET(QT4 OFF)
  SET(QT5 OFF)

  IF(DEFINED QT_WRAP_CPP)
    MESSAGE(STATUS "Found Qt 4.x")
    SET(QT4 ON)
  ENDIF(DEFINED QT_WRAP_CPP)

  IF(DEFINED Qt5Core_VERSION_STRING)
    MESSAGE(STATUS "Found Qt ${Qt5Core_VERSION_STRING}")
    SET(QT5 ON)
    SET(QT_BINARY_DIR "${_qt5Core_install_prefix}/bin")
    SET(QT_PLUGINS_DIR "${_qt5Core_install_prefix}/plugins")
    SET(QT_TRANSLATIONS_DIR "${_qt5Core_install_prefix}/translations")
  ENDIF(DEFINED Qt5Core_VERSION_STRING)

  IF(QT4 OR QT5)
    SET(QT ON)
  ENDIF(QT4 OR QT5)

  # Qt shared modules
  SET(QT_MODULES CLucene Core Gui Help Multimedia Network OpenGL Qml Script ScriptTools Sql Svg Test WebKit Xml XmlPatterns)

  IF(QT4)
    # Old modules with Qt 4
    SET(QT_MODULES ${QT_MODULES} Declarative)
  ENDIF(QT4)

  IF(QT5)
    # New modules with Qt 5
    SET(QT_MODULES ${QT_MODULES} Concurrent MultimediaQuick MultimediaWidgets PrintSupport Quick QuickParticles QuickTest Sensors SerialPort V8 Widgets)
  ENDIF(QT5)

  SET(QT_MODULES_USED)
  
  FOREACH(_MODULE ${QT_MODULES})
    IF(QT5)
      SET(_MODULE_NAME "Qt5${_MODULE}")
      SET(_MODULE_FOUND ${${_MODULE_NAME}_FOUND})
    ELSE(QT5)
      SET(_MODULE_NAME "Qt${_MODULE}4")
      STRING(TOUPPER ${_MODULE} _UP_MODULE_NAME)
      SET(_MODULE_FOUND ${QT_USE_QT${_UP_MODULE_NAME}})
    ENDIF(QT5)
    IF (_MODULE_FOUND)
      LIST(APPEND QT_MODULES_USED ${_MODULE})
    ENDIF (_MODULE_FOUND)
  ENDFOREACH(_MODULE)
  
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
ENDMACRO(DETECT_QT_VERSION)

MACRO(FILTER_QT_FILES FILE)
  IF(QT)
#    MESSAGE(STATUS "file = ${FILE}")
    IF(${FILE} MATCHES "\\.ts$")
      STRING(REGEX REPLACE "^.*_([a-z-]*)\\.ts$" "\\1" _LANG ${FILE})
      LIST(APPEND QT_LANGS ${_LANG})
      LIST(APPEND QT_TSS ${FILE})
#      MESSAGE(STATUS "ts = ${QT_TSS} ${FILE}")
    ELSEIF(${FILE} MATCHES "\\.qrc$")
      LIST(APPEND QT_QRCS ${FILE})
#      MESSAGE(STATUS "qrc = ${QT_QRCS} ${FILE}")
    ELSEIF(${FILE} MATCHES "\\.ui$")
      LIST(APPEND QT_UIS ${FILE})
#      MESSAGE(STATUS "uis = ${QT_UIS} ${FILE}")
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
#  MESSAGE(STATUS "ok ${QT_UIS}")
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

MACRO(COMPILE_QT_HEADERS TARGET)
  IF(QT)
    IF(CMAKE_AUTOMOC)
      SET(QT_MOCS_CPPS "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_automoc.cpp")
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

MACRO(LINK_QT_LIBRARIES TARGET)
  IF(QT)
    IF(QT5)
      QT5_USE_MODULES(${TARGET} ${QT_MODULES_USED})
    ENDIF(QT5)
    IF(QT4)
      TARGET_LINK_LIBRARIES(${TARGET} ${QT_LIBRARIES})
    ENDIF(QT4)
  ENDIF(QT)
ENDMACRO(LINK_QT_LIBRARIES)

MACRO(INSTALL_QT_TRANSLATIONS TARGET)
  IF(QT_QMS)
    IF(APPLE)
      ADD_CUSTOM_COMMAND(TARGET ${TARGET} PRE_BUILD COMMAND mkdir -p ${RESOURCES_DIR}/translations)

      # Copying all Qt translations to bundle
      FOREACH(_QM ${QT_QMS})
        ADD_CUSTOM_COMMAND(TARGET ${TARGET} POST_BUILD COMMAND cp ARGS ${_QM} ${RESOURCES_DIR}/translations)
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
            ADD_CUSTOM_COMMAND(TARGET ${TARGET} POST_BUILD COMMAND cp ARGS ${LANG_FILE} ${RESOURCES_DIR}/translations)
          ENDIF(WIN32)
        ENDIF(EXISTS ${LANG_FILE})
      ENDFOREACH(_LANG)
    ENDIF(WIN32 OR APPLE)
  ENDIF(QT_QMS)
ENDMACRO(INSTALL_QT_TRANSLATIONS)

MACRO(INSTALL_QT_LIBRARIES)
  IF(WIN32 AND QT)
    # Install Qt libraries
    FOREACH(_MODULE ${QT_MODULES})
      IF(QT5)
        SET(_MODULE_NAME "Qt5${_MODULE}")
        SET(_MODULE_FOUND ${${_MODULE_NAME}_FOUND})
      ELSE(QT5)
        SET(_MODULE_NAME "Qt${_MODULE}4")
        STRING(TOUPPER ${_MODULE} _UP_MODULE_NAME)
        SET(_MODULE_FOUND ${QT_USE_QT${_UP_MODULE_NAME}})
      ENDIF(QT5)
      IF (_MODULE_FOUND)
        INSTALL(FILES "${QT_BINARY_DIR}/${_MODULE_NAME}.dll" DESTINATION ${BIN_PREFIX})
      ENDIF (_MODULE_FOUND)
    ENDFOREACH(_MODULE)

    IF(QT4)
      IF(QT_USE_QTGUI)
        INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qgif4.dll" DESTINATION ${BIN_PREFIX}/imageformats)
        INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qico4.dll" DESTINATION ${BIN_PREFIX}/imageformats)
        INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qjpeg4.dll" DESTINATION ${BIN_PREFIX}/imageformats)
      ENDIF(QT_USE_QTGUI)
      IF(QT_USE_QTSQL)
        INSTALL(FILES "${QT_PLUGINS_DIR}/sqldrivers/qsqlite4.dll" DESTINATION ${BIN_PREFIX}/sqldrivers)
      ENDIF(QT_USE_QTSQL)
      IF(QT_USE_QTSVG)
        INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qsvg4.dll" DESTINATION ${BIN_PREFIX}/imageformats)
        INSTALL(FILES "${QT_PLUGINS_DIR}/iconengines/qsvgicon4.dll" DESTINATION ${BIN_PREFIX}/iconengines)
      ENDIF(QT_USE_QTSVG)
    ENDIF(QT4)

    IF(QT5)
      IF(Qt5Core_FOUND)
        INSTALL(FILES "${QT_PLUGINS_DIR}/platforms/qwindows.dll" DESTINATION ${BIN_PREFIX}/platforms)
        INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qico.dll" DESTINATION ${BIN_PREFIX}/imageformats)
        INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qgif.dll" DESTINATION ${BIN_PREFIX}/imageformats)
        INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qjpeg.dll" DESTINATION ${BIN_PREFIX}/imageformats)
      ENDIF(Qt5Core_FOUND)
      IF(Qt5Widgets_FOUND)
        INSTALL(FILES "${QT_PLUGINS_DIR}/accessible/qtaccessiblewidgets.dll" DESTINATION ${BIN_PREFIX}/accessible)
      ENDIF(Qt5Widgets_FOUND)
      IF(Qt5Sql_FOUND)
        INSTALL(FILES "${QT_PLUGINS_DIR}/sqldrivers/qsqlite.dll" DESTINATION ${BIN_PREFIX}/sqldrivers)
      ENDIF(Qt5Sql_FOUND)
      IF(Qt5Svg_FOUND)
        INSTALL(FILES "${QT_PLUGINS_DIR}/imageformats/qsvg.dll" DESTINATION ${BIN_PREFIX}/imageformats)
        INSTALL(FILES "${QT_PLUGINS_DIR}/iconengines/qsvgicon.dll" DESTINATION ${BIN_PREFIX}/iconengines)
      ENDIF(Qt5Svg_FOUND)
    ENDIF(QT5)

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

MACRO(INSTALL_QT_MISC TARGET)
  IF(QT)
    # Copying qt_menu.nib to bundle
    IF(APPLE AND MAC_RESOURCES_DIR)
      ADD_CUSTOM_COMMAND(TARGET ${TARGET} POST_BUILD COMMAND cp -R ARGS ${MAC_RESOURCES_DIR}/qt_menu.nib ${RESOURCES_DIR})
    ENDIF(APPLE AND MAC_RESOURCES_DIR)

    IF(QT5)
      # Under Mac OS X, executables should use project label
      GET_TARGET_PROPERTY(_TYPE ${TARGET} TYPE)

      IF(_TYPE STREQUAL EXECUTABLE AND CMAKE_VERSION VERSION_LESS "2.8.11")
        TARGET_LINK_LIBRARIES(${TARGET} ${Qt5Core_QTMAIN_LIBRARIES})
      ENDIF(_TYPE STREQUAL EXECUTABLE AND CMAKE_VERSION VERSION_LESS "2.8.11")
    ENDIF(QT5)
  ENDIF(QT)
ENDMACRO(INSTALL_QT_MISC TARGET)
