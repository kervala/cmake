@echo off

set EXTERNAL_ROOT=d:\Neolinks

call:compile boost
call:compile openssl
call:compile xvid
call:compile speex
call:compile speex++
call:compile crypto
call:compile tinyxml

call:compile neolib
call:compile gclib
call:compile wbclient
call:compile mcu

echo All done.
goto:eof

:compile_debug
cd %EXTERNAL_ROOT%\%~1
mkdir build_msvc10_debug 2> nul
cd build_msvc10_debug
cmake -G "NMake Makefiles" .. -DCMAKE_INSTALL_PREFIX=%EXTERNAL_MSVC10_PATH% -DCMAKE_BUILD_TYPE=Debug
nmake install
goto:eof

:compile_release
cd %EXTERNAL_ROOT%\%~1
mkdir build_msvc10_release 2> nul
cd build_msvc10_release
cmake -G "NMake Makefiles" .. -DCMAKE_INSTALL_PREFIX=%EXTERNAL_MSVC10_PATH% -DCMAKE_BUILD_TYPE=Release
nmake install
goto:eof

:compile
echo Compiling %~1
call:compile_release %~1
call:compile_debug %~1
goto:eof
