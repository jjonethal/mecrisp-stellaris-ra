:: simple debug script
setlocal
set DBG_ELF=mecrisp-stellaris-stm32f746.elf
::set DBG_ELF=%*

:: don't omit .exe
set GDB=arm-none-eabi-gdb.exe
::set OPEN_OCD_EXE=openocd-x64-0.9.0-dev-150204220259.exe
set OPEN_OCD_EXE=openocd.exe

set OPEN_OCD_PATH=C:\app\openocd-ac6\openocd

SET P=C:\gccarm\4.9-2015q3\bin
if exist %P%\%GDB% set GNU_ARM_BIN=%P%

set OPEN_OCD_CMD=%OPEN_OCD_PATH%\bin\%OPEN_OCD_EXE%

set PATH=%GNU_ARM_BIN%;%PATH%

:: start ocd in separate window
echo adjust board for stm32f746
start /MIN /D %OPEN_OCD_PATH%\scripts %OPEN_OCD_CMD% -f %OPEN_OCD_PATH%\scripts\board\stm32f7discovery.cfg
:: launch and wait for gdb complete
:: arm-none-eabi-gdb %DBG_ELF% -x .gdbinit
arm-none-eabi-gdb %DBG_ELF%

:: shutdown ocd
(
@echo target remote localhost:3333
@echo monitor shutdown 
@echo quit
) | arm-none-eabi-gdb
endlocal

:: pause
