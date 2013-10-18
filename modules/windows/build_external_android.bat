@echo off

set PATH=%NDK_ROOT%\prebuilt\windows-x86_64\bin;%NDK_ROOT%\prebuilt\windows\bin;%NDK_ROOT%\toolchains\llvm-3.3\prebuilt\windows-x86_64\bin;%PATH%
set EXTERNAL_ROOT=d:\External
set TARGET_CPU=armv7

call:compile boost
call:compile openssl
call:compile xvid
call:compile speex
call:compile speex++
call:compile crypto

call:compile neolib
call:compile gclib
call:compile wbclient
call:compile mcu

echo All done.
goto:eof

:error
set NAME=%~1
echo An error occured while compiling %NAME%...
pause
goto:eof

:compile
set NAME=%~1
echo Compiling %NAME%
cd %EXTERNAL_ROOT%\%NAME%
rmdir /s /q build_android 2> nul
mkdir build_android 2> nul
cd build_android
del CMakeCache.txt 2> nul
cmake -G "Unix Makefiles" .. -DCMAKE_TOOLCHAIN_FILE=%CMAKE_MODULE_PATH%/AndroidToolChain.cmake -DCMAKE_INSTALL_PREFIX=%EXTERNAL_ANDROID_PATH% -DTARGET_CPU=%TARGET_CPU% -DCMAKE_BUILD_TYPE=Release -DNDK_TOOLCHAIN_VERSION=clang
if ERRORLEVEL 1 call:error %NAME%
make -j4
make install
goto:eof
