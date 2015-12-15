:: simple debug script
setlocal
:: set DBG_ELF=mecrisp-stellaris-stm32f746.elf
set DBG_ELF=%*

:: don't omit .exe
set GDB=arm-none-eabi-gdb.exe

SET P=C:\Users\jeanjo\Downloads\prog\stlink\stlink-20130324-win\bin
if exist %P%\st-util.exe set STLINK_PATH=%P%


SET P=E:\gcc\4.6_2012q4\bin
if exist %P%\%GDB% set GNU_ARM_BIN=%P%
SET P=C:\gccarm\4.7_2014q2\bin
if exist %P%\%GDB% set GNU_ARM_BIN=%P%
SET P=C:\app\gcc\4.9_2014q4\bin
if exist %P%\%GDB% set GNU_ARM_BIN=%P%
SET P=C:\gccarm\4.9-2015q3\bin
if exist %P%\%GDB% set GNU_ARM_BIN=%P%


set PATH=%GNU_ARM_BIN%;%PATH%

:: start ocd in separate window
echo adjust board for stm32f746
start /MIN /D %STLINK_PATH% st-util.exe
:: launch and wait for gdb complete
:: arm-none-eabi-gdb %DBG_ELF% -x .gdbinit
arm-none-eabi-gdb %DBG_ELF%

:: shutdown ocd
(
@echo target remote localhost:4242
@echo monitor shutdown 
@echo quit
) | arm-none-eabi-gdb
endlocal

:: pause
