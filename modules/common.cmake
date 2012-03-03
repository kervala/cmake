SET(COMMON_MODULE_FOUND TRUE)

###
# Helper macro that generates .pc and installs it.
# Argument: name - the name of the .pc package, e.g. "mylib.pc"
###
MACRO(GEN_PKGCONFIG name)
  IF(NOT WIN32)
    CONFIGURE_FILE(${name}.in "${CMAKE_CURRENT_BINARY_DIR}/${name}")
    INSTALL(FILES "${CMAKE_CURRENT_BINARY_DIR}/${name}" DESTINATION lib/pkgconfig)
  ENDIF(NOT WIN32)
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
    INCLUDE_DIRECTORIES(${CMAKE_BINARY_DIR})
    ADD_DEFINITIONS(-DHAVE_REVISION_H)
    SET(HAVE_REVISION_H ON)

    # a custom target that is always built
    ADD_CUSTOM_TARGET(revision ALL
      DEPENDS ${CMAKE_BINARY_DIR}/revision.h)

    # creates revision.h using cmake script
    ADD_CUSTOM_COMMAND(OUTPUT ${CMAKE_BINARY_DIR}/revision.h
      COMMAND ${CMAKE_COMMAND}
      -DSOURCE_DIR=${CMAKE_SOURCE_DIR}
      -P ${CMAKE_SOURCE_DIR}/CMakeModules/GetRevision.cmake)

    # revision.h is a generated file
    SET_SOURCE_FILES_PROPERTIES(${CMAKE_BINARY_DIR}/revision.h
      PROPERTIES GENERATED TRUE
      HEADER_FILE_ONLY TRUE)
  ENDIF(EXISTS ${CMAKE_SOURCE_DIR}/revision.h.in)
ENDMACRO(GEN_REVISION_H)

MACRO(SIGN_FILE target)
  IF(WITH_SIGN_FILE AND WIN32 AND WINSDK_SIGNTOOL AND ${CMAKE_BUILD_TYPE} STREQUAL "Release")
    GET_TARGET_PROPERTY(filename ${target} LOCATION)
#    ADD_CUSTOM_COMMAND(
#      TARGET ${target}
#      POST_BUILD
#      COMMAND ${WINSDK_SIGNTOOL} sign ${filename}
#      VERBATIM)
  ENDIF(WITH_SIGN_FILE AND WIN32 AND WINSDK_SIGNTOOL AND ${CMAKE_BUILD_TYPE} STREQUAL "Release")
ENDMACRO(SIGN_FILE)

###
#
###
MACRO(SET_TARGET_SERVICE name)
  IF(NOT BUILD_FLAGS_SETUP)
    SETUP_BUILD_FLAGS()
  ENDIF(NOT BUILD_FLAGS_SETUP)

  ADD_EXECUTABLE(${name} ${ARGN})
  SET_DEFAULT_PROPS(${name})

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
  SET_DEFAULT_PROPS(${name})

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

  ADD_EXECUTABLE(${name} WIN32 ${ARGN})
  SET_DEFAULT_PROPS(${name})

  IF(WIN32)
    SET_TARGET_PROPERTIES(${name} PROPERTIES LINK_FLAGS "/MANIFESTDEPENDENCY:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' publicKeyToken='6595b64144ccf1df' language='*' processorArchitecture='*'\"")
  ENDIF(WIN32)

  INSTALL(TARGETS ${name} RUNTIME DESTINATION ${BIN_PREFIX})
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
  SET(IS_FOUND OFF)

  # If user specify STATIC or SHARED, override project default
  FOREACH(ARG ${ARGN})
    IF(ARG STREQUAL STATIC)
      SET(IS_FOUND ON)
      SET(IS_STATIC ON)
    ELSEIF(ARG STREQUAL SHARED)
      SET(IS_FOUND ON)
      SET(IS_STATIC OFF)
    ENDIF(ARG STREQUAL STATIC)
  ENDFOREACH(ARG ${ARGN})

  # If library mode is not specified, prepend it
  IF(NOT IS_FOUND)
    IF(IS_STATIC)
      ADD_LIBRARY(${name} STATIC ${ARGN})
    ELSE(IS_STATIC)
      ADD_LIBRARY(${name} SHARED ${ARGN})
    ENDIF(IS_STATIC)
  ELSE(NOT IS_FOUND)
    ADD_LIBRARY(${name} ${ARGN})
  ENDIF(NOT IS_FOUND)

  IF(IS_STATIC)
    SIGN_FILE(${name})
  ENDIF(IS_STATIC)

  SET_DEFAULT_PROPS(${name})

  # To prevent other libraries to be linked to the same libraries
  SET_TARGET_PROPERTIES(${name} PROPERTIES LINK_INTERFACE_LIBRARIES "")

  IF(WITH_PREFIX_LIB)
    SET_TARGET_PROPERTIES(${name} PROPERTIES PREFIX "lib")
  ENDIF(WITH_PREFIX_LIB)

  IF(WIN32)
    # DLLs are in bin directory under Windows
    SET(LIBRARY_DEST ${BIN_PREFIX})
  ELSE(WIN32)
    SET(LIBRARY_DEST ${LIB_PREFIX})
  ENDIF(WIN32)

  IF(WITH_INSTALL_LIBRARIES)
    # copy both DLL and LIB files
    INSTALL(TARGETS ${name} RUNTIME DESTINATION ${BIN_PREFIX} LIBRARY DESTINATION ${LIBRARY_DEST} ARCHIVE DESTINATION ${LIB_PREFIX})
    # copy also PDB files in installation directory for Visual C++
    IF(MSVC)
      # get final location for Debug configuration
      GET_TARGET_PROPERTY(OUTPUT_FULLPATH ${name} LOCATION_Debug)
      # replace extension by .pdb
	  STRING(REGEX REPLACE "\\.([a-zA-Z0-9_]+)$" ".pdb" OUTPUT_FULLPATH ${OUTPUT_FULLPATH})
      IF(IS_STATIC)
        # copy PDB file together with LIB
        INSTALL(FILES ${OUTPUT_FULLPATH} DESTINATION ${LIB_PREFIX} CONFIGURATIONS Debug)
      ELSE(IS_STATIC)
        # copy PDB file together with DLL
        INSTALL(FILES ${OUTPUT_FULLPATH} DESTINATION ${BIN_PREFIX} CONFIGURATIONS Debug)
      ENDIF(IS_STATIC)
    ENDIF(MSVC)
  ELSE(WITH_INSTALL_LIBRARIES)
    IF(NOT IS_STATIC)
      # copy only DLL because we don't need development files
      INSTALL(TARGETS ${name} RUNTIME DESTINATION ${BIN_PREFIX} LIBRARY DESTINATION ${LIBRARY_DEST})
    ENDIF(NOT IS_STATIC)
  ENDIF(WITH_INSTALL_LIBRARIES)
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

  SET_DEFAULT_PROPS(${name})

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
ENDMACRO(SET_TARGET_LABEL)

MACRO(SET_TARGET_EXTENSION name extension)
  SET_TARGET_PROPERTIES(${name} PROPERTIES SUFFIX .${extension})
ENDMACRO(SET_TARGET_EXTENSION)

MACRO(SET_DEFAULT_PROPS name)
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
    SET_TARGET_PROPERTIES(${name} PROPERTIES
      VERSION ${VERSION}
      SOVERSION ${VERSION_MAJOR})
    IF(LIB_PREFIX)
      SET_TARGET_PROPERTIES(${name} PROPERTIES INSTALL_NAME_DIR ${LIB_PREFIX})
    ENDIF(LIB_PREFIX)
  ENDIF(${type} STREQUAL SHARED_LIBRARY)

  IF(${type} STREQUAL EXECUTABLE AND MSVC)
    SET_TARGET_PROPERTIES(${name} PROPERTIES
      VERSION ${VERSION}
      SOVERSION ${VERSION_MAJOR}
      COMPILE_FLAGS "/GA"
      LINK_FLAGS "/VERSION:${VERSION}")
  ENDIF(${type} STREQUAL EXECUTABLE AND MSVC)

  IF(WITH_STLPORT)
    TARGET_LINK_LIBRARIES(${name} ${STLPORT_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT})
    IF(MSVC)
      SET_TARGET_PROPERTIES(${name} PROPERTIES COMPILE_FLAGS "/X")
    ENDIF(MSVC)
  ENDIF(WITH_STLPORT)

  IF(WIN32)
    SET_TARGET_PROPERTIES(${name} PROPERTIES DEBUG_POSTFIX "d" RELEASE_POSTFIX "")
  ENDIF(WIN32)
ENDMACRO(SET_DEFAULT_PROPS)

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
    SET_OPTION_DEFAULT(WITH_UNIX_STRUCTURE ON)
  ENDIF(WIN32)

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
  ADD_OPTION(WITH_STATIC              "Compile libraries as static or dynamic")
  ADD_OPTION(WITH_STATIC_PLUGINS      "Compile plugins as static or dynamic")
  ADD_OPTION(WITH_STATIC_EXTERNAL     "Use only static external libraries")
  ADD_OPTION(WITH_UNIX_STRUCTURE      "Use UNIX structure (bin, include, lib)")
  ADD_OPTION(WITH_INSTALL_LIBRARIES   "Install development files (includes and static libraries)")

  ADD_OPTION(WITH_STLPORT             "Use STLport instead of standard STL")
  ADD_OPTION(WITH_RTTI                "Enable RTTI support")
  ADD_OPTION(WITH_EXCEPTIONS          "Enable exceptions support")
  ADD_OPTION(WITH_TESTS               "Compile tests projects")

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

  SET(HOST_CPU ${CMAKE_SYSTEM_PROCESSOR})

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
    ENDIF(HOST_CPU MATCHES "x86")
    # TODO: add checks for ARM and PPC
  ELSE("${HOST_CPU}" STREQUAL "${TARGET_CPU}")
    MESSAGE(STATUS "Compiling on ${HOST_CPU} for ${TARGET_CPU}")
  ENDIF("${HOST_CPU}" STREQUAL "${TARGET_CPU}")

  IF(TARGET_CPU STREQUAL "x86_64")
    SET(TARGET_X64 1)
    SET(PLATFORM_CFLAGS "-DHAVE_X86_64")
  ELSEIF(TARGET_CPU STREQUAL "x86")
    SET(TARGET_X86 1)
    SET(PLATFORM_CFLAGS "-DHAVE_X86")
  ENDIF(TARGET_CPU STREQUAL "x86_64")

  # Fix library paths suffixes for Debian MultiArch
  IF(NOT CMAKE_LIBRARY_ARCHITECTURE)
    SET(CMAKE_LIBRARY_ARCHITECTURE $ENV{DEB_HOST_MULTIARCH})
  ENDIF(NOT CMAKE_LIBRARY_ARCHITECTURE)

  IF(CMAKE_LIBRARY_ARCHITECTURE)
    SET(CMAKE_LIBRARY_PATH "/lib/${CMAKE_LIBRARY_ARCHITECTURE};/usr/lib/${CMAKE_LIBRARY_ARCHITECTURE};${CMAKE_LIBRARY_PATH}")
  ENDIF(CMAKE_LIBRARY_ARCHITECTURE)

  IF(MSVC)
    IF(MSVC10)
      SET(PLATFORM_CFLAGS "/Gy- /MP ${PLATFORM_CFLAGS}")
      # /Ox is working with VC++ 2010, but custom optimizations don't exist
      SET(RELEASE_CFLAGS "/Ox /GF /GS- ${RELEASE_CFLAGS}")
      # without inlining it's unusable, use custom optimizations again
      SET(DEBUG_CFLAGS "/Od /Ob1 /GF- ${DEBUG_CFLAGS}")
      SET(INCREMENTAL_SUPPORTED TRUE)
	ELSEIF(MSVC90)
      # don't use a /O[012x] flag if you want custom optimizations
      SET(RELEASE_CFLAGS "/Ob2 /Oi /Ot /Oy /GT /GF /GS- ${RELEASE_CFLAGS}")
      # without inlining it's unusable, use custom optimizations again
      SET(DEBUG_CFLAGS "/Ob1 /GF- ${DEBUG_CFLAGS}")
      SET(INCREMENTAL_SUPPORTED TRUE)
	ELSEIF(MSVC80)
      SET(PLATFORM_CFLAGS "/Wp64 ${PLATFORM_CFLAGS}")
      # don't use a /O[012x] flag if you want custom optimizations
      SET(RELEASE_CFLAGS "/Ox /GF /GS- ${RELEASE_CFLAGS}")
      # without inlining it's unusable, use custom optimizations again
      SET(DEBUG_CFLAGS "/Od /Ob1 ${DEBUG_CFLAGS}")
      SET(INCREMENTAL_SUPPORTED TRUE)
    ELSE(MSVC10)
      MESSAGE(FATAL_ERROR "Can't determine compiler version ${MSVC_VERSION}")
    ENDIF(MSVC10)

    IF(WITH_LOGGING)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} /DENABLE_LOGS")
    ENDIF(WITH_LOGGING)

    SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} /D_CRT_SECURE_NO_WARNINGS /D_CRT_NONSTDC_NO_WARNINGS /DWIN32 /D_WINDOWS /Zm1000 /wd4250")
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

    IF(INCREMENTAL_SUPPORTED)
      SET(DEBUG_LINKFLAGS "${DEBUG_LINKFLAGS} /INCREMENTAL")
      SET(RELEASE_LINKFLAGS "${RELEASE_LINKFLAGS} /INCREMENTAL:NO")
    ENDIF(INCREMENTAL_SUPPORTED)

    SET(DEBUG_CFLAGS "/Zi /MDd /RTC1 /RTCc /D_DEBUG /DDEBUG ${DEBUG_CFLAGS}")
    SET(RELEASE_CFLAGS "/MD /DNDEBUG ${RELEASE_CFLAGS}")
    SET(DEBUG_LINKFLAGS "/DEBUG /OPT:NOREF /OPT:NOICF /NODEFAULTLIB:msvcrt ${DEBUG_LINKFLAGS}")
    SET(RELEASE_LINKFLAGS "/RELEASE /OPT:REF /OPT:ICF ${RELEASE_LINKFLAGS}")

    IF(WITH_WARNINGS)
      SET(DEBUG_CFLAGS "/W4 ${DEBUG_CFLAGS}")
    ELSE(WITH_WARNINGS)
      SET(DEBUG_CFLAGS "/W3 ${DEBUG_CFLAGS}")
    ENDIF(WITH_WARNINGS)
  ELSE(MSVC)
    IF(HOST_CPU STREQUAL "x86_64" AND TARGET_CPU STREQUAL "x86")
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -m32 -march=i686")
    ENDIF(HOST_CPU STREQUAL "x86_64" AND TARGET_CPU STREQUAL "x86")

    IF(HOST_CPU STREQUAL "x86" AND TARGET_CPU STREQUAL "x86_64")
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -m64")
    ENDIF(HOST_CPU STREQUAL "x86" AND TARGET_CPU STREQUAL "x86_64")

    SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -g -D_REENTRANT")

    IF(WITH_LOGGING)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -DENABLE_LOGS")
    ENDIF(WITH_LOGGING)

    IF(WITH_VISIBILITY_HIDDEN)
      SET(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -fvisibility=hidden")
    ENDIF(WITH_VISIBILITY_HIDDEN)

    IF(WITH_COVERAGE)
      SET(PLATFORM_CFLAGS "-fprofile-arcs -ftest-coverage ${PLATFORM_CFLAGS}")
    ENDIF(WITH_COVERAGE)

    IF(WITH_WARNINGS)
      SET(PLATFORM_CFLAGS "-Wall -ansi ${PLATFORM_CFLAGS}")
    ENDIF(WITH_WARNINGS)

    IF(APPLE)
      SET(PLATFORM_CFLAGS "-gdwarf-2 ${PLATFORM_CFLAGS}")
    ENDIF(APPLE)

    # Fix "relocation R_X86_64_32 against.." error on x64 platforms
    IF(TARGET_X64 AND WITH_STATIC AND NOT WITH_STATIC_PLUGINS)
      SET(PLATFORM_CFLAGS "-fPIC ${PLATFORM_CFLAGS}")
    ENDIF(TARGET_X64 AND WITH_STATIC AND NOT WITH_STATIC_PLUGINS)

    SET(PLATFORM_CXXFLAGS ${PLATFORM_CFLAGS})

    # Exceptions are only set for C++
    IF(NOT WITH_EXCEPTIONS)
      SET(PLATFORM_CXXFLAGS "${PLATFORM_CXXFLAGS} -fno-exceptions -DBOOST_NO_EXCEPTIONS")
    ENDIF(NOT WITH_EXCEPTIONS)

    # RTTI is only set for C++
    IF(NOT WITH_RTTI)
      SET(PLATFORM_CXXFLAGS "${PLATFORM_CXXFLAGS} -fno-rtti")
    ENDIF(NOT WITH_RTTI)

    IF(NOT APPLE)
      SET(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} -Wl,--no-undefined -Wl,--as-needed")
    ENDIF(NOT APPLE)

    SET(DEBUG_CFLAGS "-D_DEBUG -DDEBUG ${DEBUG_CFLAGS}")
    SET(RELEASE_CFLAGS "-DNDEBUG -O3 ${RELEASE_CFLAGS}")
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

  ## Debug
  SET(CMAKE_C_FLAGS_DEBUG ${DEBUG_CFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_CXX_FLAGS_DEBUG ${DEBUG_CFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_EXE_LINKER_FLAGS_DEBUG "${PLATFORM_LINKFLAGS} ${DEBUG_LINKFLAGS}" CACHE STRING "" FORCE)
  SET(CMAKE_MODULE_LINKER_FLAGS_DEBUG "${PLATFORM_LINKFLAGS} ${DEBUG_LINKFLAGS}" CACHE STRING "" FORCE)
  SET(CMAKE_SHARED_LINKER_FLAGS_DEBUG "${PLATFORM_LINKFLAGS} ${DEBUG_LINKFLAGS}" CACHE STRING "" FORCE)

  ## Release
  SET(CMAKE_C_FLAGS_RELEASE ${RELEASE_CFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_CXX_FLAGS_RELEASE ${RELEASE_CFLAGS} CACHE STRING "" FORCE)
  SET(CMAKE_EXE_LINKER_FLAGS_RELEASE "${PLATFORM_LINKFLAGS} ${RELEASE_LINKFLAGS}" CACHE STRING "" FORCE)
  SET(CMAKE_MODULE_LINKER_FLAGS_RELEASE "${PLATFORM_LINKFLAGS} ${RELEASE_LINKFLAGS}" CACHE STRING "" FORCE)
  SET(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${PLATFORM_LINKFLAGS} ${RELEASE_LINKFLAGS}" CACHE STRING "" FORCE)

  SET(BUILD_FLAGS_SETUP ON)
ENDMACRO(SETUP_BUILD_FLAGS)

MACRO(SETUP_PREFIX_PATHS name)
  IF(NOT BUILD_FLAGS_SETUP)
    SETUP_BUILD_FLAGS()
  ENDIF(NOT BUILD_FLAGS_SETUP)

  IF(UNIX)
    ## Allow override of install_prefix/etc path.
    IF(NOT ETC_PREFIX)
      SET(ETC_PREFIX "etc/${name}" CACHE PATH "Installation path for configurations")
    ENDIF(NOT ETC_PREFIX)

    ## Allow override of install_prefix/share path.
    IF(NOT SHARE_PREFIX)
      SET(SHARE_PREFIX "share/${name}" CACHE PATH "Installation path for data.")
    ENDIF(NOT SHARE_PREFIX)

    ## Allow override of install_prefix/sbin path.
    IF(NOT SBIN_PREFIX)
      SET(SBIN_PREFIX "sbin" CACHE PATH "Installation path for admin tools and services.")
    ENDIF(NOT SBIN_PREFIX)

    ## Allow override of install_prefix/bin path.
    IF(NOT BIN_PREFIX)
      SET(BIN_PREFIX "bin" CACHE PATH "Installation path for tools and applications.")
    ENDIF(NOT BIN_PREFIX)

    ## Allow override of install_prefix/include path.
    IF(NOT INCLUDE_PREFIX)
      SET(INCLUDE_PREFIX "include" CACHE PATH "Installation path for headers.")
    ENDIF(NOT INCLUDE_PREFIX)

    ## Allow override of install_prefix/lib path.
    IF(NOT LIB_PREFIX)
      IF(CMAKE_LIBRARY_ARCHITECTURE)
        SET(LIB_PREFIX "lib/${CMAKE_LIBRARY_ARCHITECTURE}" CACHE PATH "Installation path for libraries.")
      ELSE(CMAKE_LIBRARY_ARCHITECTURE)
        SET(LIB_PREFIX "lib" CACHE PATH "Installation path for libraries.")
      ENDIF(CMAKE_LIBRARY_ARCHITECTURE)
    ENDIF(NOT LIB_PREFIX)

    ## Allow override of install_prefix/lib path.
    IF(NOT PLUGIN_PREFIX)
      IF(CMAKE_LIBRARY_ARCHITECTURE)
        SET(PLUGIN_PREFIX "lib/${CMAKE_LIBRARY_ARCHITECTURE}/${name}" CACHE PATH "Installation path for plugins.")
      ELSE(CMAKE_LIBRARY_ARCHITECTURE)
        SET(PLUGIN_PREFIX "lib/${name}" CACHE PATH "Installation path for plugins.")
      ENDIF(CMAKE_LIBRARY_ARCHITECTURE)
    ENDIF(NOT PLUGIN_PREFIX)

    # Aliases for automake compatibility
    SET(prefix ${CMAKE_INSTALL_PREFIX})
    SET(exec_prefix ${BIN_PREFIX})
    SET(libdir ${LIB_PREFIX})
    SET(includedir ${INCLUDE_PREFIX})
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

    INCLUDE(${CMAKE_ROOT}/Modules/Platform/Windows-cl.cmake)
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
              FILE(TO_CMAKE_PATH $ENV{VS100COMNTOOLS} VC_ROOT_DIR)
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
    IF(CMAKE_FIND_LIBRARY_SUFFIXES AND NOT APPLE)
      IF(WITH_STATIC_EXTERNAL)
        SET(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
      ELSE(WITH_STATIC_EXTERNAL)
        SET(CMAKE_FIND_LIBRARY_SUFFIXES ".so")
      ENDIF(WITH_STATIC_EXTERNAL)
    ENDIF(CMAKE_FIND_LIBRARY_SUFFIXES AND NOT APPLE)
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

  IF(NOT WIN32)
    INCLUDE(FindPkgConfig)
  ENDIF(NOT WIN32)

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

  IF(${ARGC} EQUAL 5)
    SET(SUFFIXES ${ARGN})
  ELSE(${ARGC} EQUAL 5)
    SET(SUFFIXES ${LOWNAME} ${LOWNAME_FIXED} ${NAME})
  ENDIF(${ARGC} EQUAL 5)

  # Replace spaces by semi-columns to fix a bug
  STRING(REPLACE " " ";" RELEASE_FIXED ${RELEASE})
  STRING(REPLACE " " ";" DEBUG_FIXED ${DEBUG})

  IF(NOT WIN32)
    SET(MODULES ${LOWNAME} ${RELEASE_FIXED})
    LIST(REMOVE_DUPLICATES MODULES)
    PKG_CHECK_MODULES(PKG_${NAME_FIXED} ${MODULES})
  ENDIF(NOT WIN32)

  # Search for include directory
  FIND_PATH(${UPNAME_FIXED}_INCLUDE_DIR 
    ${INCLUDE}
    HINTS ${PKG_${NAME_FIXED}_INCLUDE_DIRS}
    PATHS
    $ENV{${UPNAME}_DIR}/include
    ${${UPNAME}_DIR}/include
    $ENV{${UPNAME_FIXED}_DIR}/include
    ${${UPNAME_FIXED}_DIR}/include
    $ENV{${UPNAME}_DIR}
    ${${UPNAME}_DIR}
    $ENV{${UPNAME_FIXED}_DIR}
    ${${UPNAME_FIXED}_DIR}
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

  IF(TARGET_X64)
    SET(LIBRARY_PATHS ${LIBRARY_PATHS} /usr/freeware/lib64)
  ENDIF(TARGET_X64)

  SET(LIBRARY_PATHS ${LIBRARY_PATHS} 
    $ENV{${UPNAME}_DIR}/lib${LIB_SUFFIX}
    ${${UPNAME}_DIR}/lib${LIB_SUFFIX}
    $ENV{${UPNAME_FIXED}_DIR}/lib${LIB_SUFFIX}
    ${${UPNAME_FIXED}_DIR}/lib${LIB_SUFFIX}
    /usr/local/lib
    /usr/lib
    /usr/local/X11R6/lib
    /usr/X11R6/lib
    /sw/lib
    /opt/local/lib
    /opt/csw/lib
    /opt/lib)

  # Search for release library
  FIND_LIBRARY(${UPNAME_FIXED}_LIBRARY_RELEASE
    NAMES
    ${RELEASE_FIXED}
    HINTS ${PKG_${NAME_FIXED}_LIBRARY_DIRS}
    PATHS
    ${LIBRARY_PATHS}
  )

  # Search for debug library
  FIND_LIBRARY(${UPNAME_FIXED}_LIBRARY_DEBUG
    NAMES
    ${DEBUG_FIXED}
    HINTS ${PKG_${NAME_FIXED}_LIBRARY_DIRS}
    PATHS
    ${LIBRARY_PATHS}
  )
  
  IF(${UPNAME_FIXED}_INCLUDE_DIR)
    IF(${UPNAME_FIXED}_LIBRARY_RELEASE)
      # Library has been found if only one library and include are found
      SET(${UPNAME_FIXED}_FOUND TRUE)
      SET(${UPNAME_FIXED}_LIBRARIES ${${UPNAME_FIXED}_LIBRARY_RELEASE})
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
