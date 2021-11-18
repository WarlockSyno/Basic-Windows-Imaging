@echo off
REM These commands copy the selected image file to
REM predefined hard disk partitions on a BIOS-based computer.

REM Usage:   base.bat WimFileName 
REM Example: base.bat E:\Images\ThinImage.wim
REM =======================================================================================
REM
REM =======================================================================================

REM Enviromental Variables


REM =======================================================================================
REM 
REM =======================================================================================
REM
REM
REM
REM Set high-performance power scheme to speed deployment
call powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
REM Set the variable "Filesize" to the size of the wim, then trunkate the last 6 digits to create a close approx to MB, then add 500MB for the recovery image
REM This value is used in the partition part in UEFI and BIOS to partition the R drive.
SET filesize=%~z1
SET /A wimsize=%filesize:~0,-6%+500

:START
CLS
ECHO.
ECHO.
ECHO.
ECHO.
pause
set /p answer=Do you want to image this computer with the %1 image (Y/N)?
if /i "%answer:~,1%" EQU "Y" GOTO YES
if /i "%answer:~,1%" NEQ "Y" GOTO NO
REM IF ERRORLEVEL ==0 GOTO YES
REM IF ERRORLEVEL ==2 GOTO NO
GOTO END

:YES
cls
echo.
echo Detecting WIM size
echo %wimsize% MB
echo.
echo Detecting if UEFI or BIOS
wpeutil UpdateBootInfo reg query HKLM\System\CurrentControlSet\Control /v PEFirmwareType
PING LOCALHOST -n 3 >NUL
REG QUERY HKLM\System\CurrentControlSet\Control /v PEFirmwareType | Find "2" 
IF %ERRORLEVEL% == 0 goto UEFI
IF %ERRORLEVEL% == 1 goto BIOS
echo.
echo Could not detect BIOS type.
pause

:UEFI
echo Detected UEFI
PING LOCALHOST -n 3 >NUL
REM DISKPART /s UEFI.txt
(
ECHO select disk 0
ECHO clean
ECHO convert gpt
ECHO create partition efi size=100 
ECHO format quick fs=fat32 label="System"
ECHO assign letter="S"
ECHO create partition msr size=16
ECHO create partition primary 
ECHO shrink minimum=%WIMSIZE%
ECHO format quick fs=ntfs label="Windows"
ECHO assign letter="W"
ECHO create partition primary
ECHO format quick fs=ntfs label="Recovery"
ECHO assign letter="R"
ECHO set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
ECHO gpt attributes=0x8000000000000001
ECHO list volume
ECHO exit
)>%TEMP%\UEFI.TXT
DISKPART /s %TEMP%\UEFI.TXT
GOTO WIM

:BIOS
cls
echo Detected BIOS
PING LOCALHOST -n 3 >NUL
REM DISKPART /s bios.txt
REM (
REM ECHO select disk 0
REM ECHO clean
REM ECHO create partition primary size=350
REM ECHO format quick fs=ntfs label="System"
REM ECHO assign letter="S"
REM ECHO active
REM ECHO create partition primary  
REM ECHO shrink minimum=%wimsize%
REM ECHO format quick fs=ntfs label="Windows"
REM ECHO assign letter="W"
REM ECHO create partition primary
REM ECHO format quick fs=ntfs label="Recovery"
REM ECHO assign letter="R"
REM ECHO set id=27
REM ECHO list volume
REM ECHO exit
REM )>%TEMP%\BIOS.TXT
REM DISKPART /s %TEMP%\BIOS.txt
COLOR 0E
ECHO *****************
ECHO *****************
ECHO DETECTED BIOS MODE
ECHO PLEASE CHANGE BOOT SETTINGS TO UEFI
ECHO *****************
ECHO *****************
PAUSE
EXIT
GOTO WIM

:WIM
echo.
echo.
REM echo Copying %1 to RECOVERY partition
REM robocopy N:\ R:\ %1
REM copy %1 R:\install.wim /z
REM echo Applying WIM from the RECOVERY partition to WINDOWS partition
echo APPLYING IMAGE
dism /Apply-Image /ImageFile:N:\%1 /Index:1 /ApplyDir:W:\
md R:\Recovery\WindowsRE
REM Copy recovery image to the R: drive
echo Copy WinRE to Recovery Partition
copy W:\windows\system32\recovery\winre.wim R:\Recovery\WindowsRE\winre.wim
REM Register the location of the recovery tools
echo.
echo Set R:\ drive as recovery partition
W:\Windows\System32\Reagentc /Setreimage /Path R:\Recovery\WindowsRE /Target W:\Windows
echo.
echo.
REM Verify the configuration status of the recovery image
W:\Windows\System32\Reagentc /Info /Target W:\Windows
echo.
echo.
REG QUERY HKLM\System\CurrentControlSet\Control /v PEFirmwareType | Find "2" 
IF %ERRORLEVEL% == 0 GOTO BOOTUEFI
IF %ERRORLEVEL% == 1 GOTO BOOTBIOS
GOTO END

:BOOTUEFI
bcdboot W:\Windows /s S: /f UEFI
GOTO FINISH

:BOOTBIOS
bcdboot W:\Windows /s S: /f BIOS
GOTO FINISH

:FINISH
REM W:\Windows\System32\reagentc /setosimage /path R: /target W:\Windows /index 1
GOTO END

:NO
echo.
echo Canceled.
pause
GOTO END

:END
ECHO.
ECHO.
ECHO.
ECHO Imaging complete. Rebooting in 15 seconds.
PING LOCALHOST -n 15 >NUL
EXIT