@echo off
setlocal EnableDelayedExpansion

rem Make console output readable (no mojibake on Cyrillic from CMake/clang).
chcp 65001 >nul

rem cMain - cross-compile helper for ARMv7 (Windows-on-ARM) using llvm-mingw + MinGW-w64.
rem Usage:
rem   build-arm32.bat
rem   build-arm32.bat "D:\toolchains\llvm-mingw"

set "PROJECT_ROOT=%~dp0"
rem Remove trailing backslash to avoid broken paths in CMake.
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

set "BUILD_DIR=%PROJECT_ROOT%\build-arm32"
set "TOOLCHAIN_FILE=%PROJECT_ROOT%\cmake\toolchains\armv7-windows-mingw.cmake"
rem Where to persist llvm-mingw root across runs.
set "LLVM_ROOT_FILE=%PROJECT_ROOT%\llvm-path.txt"

rem Determine llvm-mingw root (load from file or prompt).
if not "%~1"=="" (
    set "LLVM_MINGW_ROOT=%~1"
)

if not defined LLVM_MINGW_ROOT (
    if exist "%LLVM_ROOT_FILE%" (
        set /p "LLVM_MINGW_ROOT="<"%LLVM_ROOT_FILE%"
    )
)

if not defined LLVM_MINGW_ROOT (
    set /p "LLVM_MINGW_ROOT=Enter LLVM-MINGW root (e.g. C:\llvm-mingw): "
)

rem Trim quotes if user entered them
set "LLVM_MINGW_ROOT=%LLVM_MINGW_ROOT:"=%"

if not defined LLVM_MINGW_ROOT (
    echo [ERROR] LLVM_MINGW_ROOT is empty.
    exit /b 1
)

rem Save the valid path into file
echo %LLVM_MINGW_ROOT%>"%LLVM_ROOT_FILE%"

rem Validate toolchain contents (don't crash: re-prompt if wrong).
:ENSURE_TOOLCHAIN
set "CLANG_EXE=%LLVM_MINGW_ROOT%\bin\armv7-w64-mingw32-clang.exe"
set "WINDRES_EXE=%LLVM_MINGW_ROOT%\bin\armv7-w64-mingw32-windres.exe"

if exist "%CLANG_EXE%" if exist "%WINDRES_EXE%" (
    goto TOOLCHAIN_OK
)

echo [ERROR] Invalid LLVM-MINGW root: missing required tools.
echo         Need:
echo           "%CLANG_EXE%"
echo           "%WINDRES_EXE%"
echo.

set "LLVM_MINGW_ROOT="
set /p "LLVM_MINGW_ROOT=Enter correct LLVM-MINGW root (e.g. C:\llvm-mingw): "
set "LLVM_MINGW_ROOT=%LLVM_MINGW_ROOT:"=%"

if not defined LLVM_MINGW_ROOT (
    echo [ERROR] Empty LLVM_MINGW_ROOT.
    exit /b 1
)

echo %LLVM_MINGW_ROOT%>"%LLVM_ROOT_FILE%"
goto ENSURE_TOOLCHAIN

:TOOLCHAIN_OK

where ninja >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Ninja is not found in PATH. Install Ninja or switch CMake generator.
    exit /b 1
)

echo LLVM-MINGW root: "%LLVM_MINGW_ROOT%"
echo Build directory: "%BUILD_DIR%"
echo.

rem Configure (out-of-source build)
cmake -G "Ninja" ^
  -S "%PROJECT_ROOT%" ^
  -B "%BUILD_DIR%" ^
  -DCMAKE_TOOLCHAIN_FILE="%TOOLCHAIN_FILE%" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DLLVM_MINGW_ROOT="%LLVM_MINGW_ROOT%"

if errorlevel 1 (
    echo [ERROR] CMake configure failed.
    exit /b 1
)

rem Workaround for old wxWidgets/libtiff header generation issues (kept for safety).
set "WX_TIFF_DIR=%PROJECT_ROOT%\wxWidgets-3.2.0\src\tiff\libtiff"
if not exist "%WX_TIFF_DIR%\tif_config.h" (
    if exist "%WX_TIFF_DIR%\tif_config.vc.h" (
        copy /Y "%WX_TIFF_DIR%\tif_config.vc.h" "%WX_TIFF_DIR%\tif_config.h" >nul
    )
)
if not exist "%WX_TIFF_DIR%\tiffconf.h" (
    if exist "%WX_TIFF_DIR%\tiffconf.vc.h" (
        copy /Y "%WX_TIFF_DIR%\tiffconf.vc.h" "%WX_TIFF_DIR%\tiffconf.h" >nul
    )
)

echo === Build ===
rem Default to single-threaded to avoid OOM/pagefile errors inside clang during wxWidgets build.
rem Usage: build-arm32.bat <llvm-mingw-root> <jobs>
set "JOBS=1"
if not "%~2"=="" set "JOBS=%~2"
cmake --build "%BUILD_DIR%" --parallel "%JOBS%"

if errorlevel 1 (
    echo [ERROR] Build failed.
    exit /b 1
)

rem Locate built executable.
set "BUILT_EXE="
if exist "%BUILD_DIR%\fateInjector.exe" set "BUILT_EXE=%BUILD_DIR%\fateInjector.exe"
if not "%BUILT_EXE%"=="" (
    rem already set
) else if exist "%BUILD_DIR%\Debug\fateInjector.exe" set "BUILT_EXE=%BUILD_DIR%\Debug\fateInjector.exe"
if not "%BUILT_EXE%"=="" (
    rem already set
) else if exist "%BUILD_DIR%\Release\fateInjector.exe" set "BUILT_EXE=%BUILD_DIR%\Release\fateInjector.exe"

if "%BUILT_EXE%"=="" (
    for /r "%BUILD_DIR%" %%F in (fateInjector.exe) do set "BUILT_EXE=%%~fF"
)

if "%BUILT_EXE%"=="" (
    echo [ERROR] Could not find built fateInjector.exe under "%BUILD_DIR%".
    exit /b 1
)

set "DEST_EXE=%PROJECT_ROOT%\fateInjector_ARM32.exe"
copy /Y "%BUILT_EXE%" "%DEST_EXE%" >nul

echo.
echo [OK] Built: "%DEST_EXE%"

endlocal
