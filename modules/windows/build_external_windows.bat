@echo off

set CLEAN=0

if "%TARGET_CPU%"=="" set TARGET_CPU=x86

for %%I in (%*) do if %%I==clean set CLEAN=1

set DEBUG_DIR=build_%TARGET_CPU%_debug
set RELEASE_DIR=build_%TARGET_CPU%_release
set PATH=%PATH%;"C:\Program Files (x86)\CMake 2.8\bin"
set EXTERNAL_ROOT=d:\Neolinks

rem 3rd-pary libraries
call:compile boost
call:compile openssl
call:compile xvid
call:compile speex
call:compile crypto
call:compile tinyxml
call:compile dshowsdk
call:compile guilib
call:compile x264

rem Neolinks libraries
call:compile speex++
call:compile bttp
call:compile nvp
call:compile neolib
call:compile gclib
call:compile wbclient
call:compile rfblib

rem Neolinks filters
call:compile intergraphfilters
call:compile codec_wrapper
call:compile mixerfilter
call:compile pushsource
call:compile sound_effects

rem Neolinks applications
call:compile mcu
call:compile btolink
call:compile gcserver
call:compile rfbclient
call:compile rfbreflector
call:compile rfbserver
call:compile wbserver

rem Neolinks Qt applications
call:compile btolink_control
call:compile btolink_qt_expert
call:compile ezlinkpro
call:compile visiomobile

echo All done.
goto:eof

:error
set NAME=%~1
echo An error occured while compiling %NAME%...
pause
goto:eof

:compile_debug
set NAME=%~1
cd %EXTERNAL_ROOT%\%NAME%
if %CLEAN%==1 rmdir /s /q %DEBUG_DIR% 2> nul
mkdir %DEBUG_DIR% 2> nul
cd %DEBUG_DIR%
cmake -G "NMake Makefiles" .. -DCMAKE_INSTALL_PREFIX=%EXTERNAL_MSVC10_PATH% -DCMAKE_BUILD_TYPE=Debug
if ERRORLEVEL 1 call:error %NAME%
nmake install
if ERRORLEVEL 2 call:error %NAME%
goto:eof

:compile_release
set NAME=%~1
cd %EXTERNAL_ROOT%\%NAME%
if %CLEAN%==1 del /s /q %RELEASE_DIR% > nul
mkdir %RELEASE_DIR% 2> nul
cd %RELEASE_DIR%
cmake -G "NMake Makefiles" .. -DCMAKE_INSTALL_PREFIX=%EXTERNAL_MSVC10_PATH% -DCMAKE_BUILD_TYPE=Release
if ERRORLEVEL 1 call:error %NAME%
nmake install
if ERRORLEVEL 2 call:error %NAME%
goto:eof

:compile
echo Compiling %~1
call:compile_release %~1
call:compile_debug %~1
goto:eof
