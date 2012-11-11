@echo off

set PATH=%PATH%;%NDK_ROOT%\prebuilt\windows\bin
set EXTERNAL_ROOT=d:\Neolinks
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

:compile
echo Compiling %~1
cd %EXTERNAL_ROOT%\%~1
mkdir build_android 2> nul
cd build_android
del CMakeCache.txt 2> nul
cmake -G "Unix Makefiles" .. -DCMAKE_TOOLCHAIN_FILE=%CMAKE_MODULE_PATH%/AndroidToolChain.cmake -DCMAKE_INSTALL_PREFIX=%EXTERNAL_ANDROID_PATH% -DTARGET_CPU=%TARGET_CPU%
make -j4
make install
goto:eof
