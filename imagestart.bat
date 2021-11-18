@ECHO OFF
REM This file must be in the System32 folder in your WinPE ex: WinPEImage.iso\sources\boot.wim\Windows\System32
REM This script uses PowerShell to pass a secure password string - Your WinPE Image must have PowerShell added

REM SCRIPT VARIABLES
SET IMAGESERVER=ServerHostingTheImages.local
SET SERVERSHARE=sharename\folderwithimages
SET DOMAINNAME=myDomain.local

REM Ping the server that hosts the images as a network check
:NETWORK_TEST
cls
echo Waiting for network connection...
ping localhost >nul
ping -n 1 %IMAGESERVER% | find "TTL=" >nul
if %errorlevel% == 0 (
	GOTO NETWORK_SUCCESS
) else (
	GOTO NETWORK_TEST
)
pause
:NETWORK_SUCCESS
cls
set /p adminlogin="Enter domain admin username: "
set "psCommand=powershell -Command "$pword = read-host 'Enter Password' -AsSecureString ; ^
	$BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pword); ^
	[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)""
for /f "usebackq delims=" %%p in (`%psCommand%`) do set password=%%p
echo.
echo Mounting imaging directory
echo.
net use N: \\%IMAGESERVER%\%SERVERSHARE% /user:%DOMAINNAME%\%adminlogin% %password%
if %errorlevel% == 0 (
	GOTO MOUNT_DRIVE_SUC
) else (
	echo.
	echo Failed to mount drive, please try again.
	GOTO :NETWORK_SUCCESS
)
:MOUNT_DRIVE_SUC
exit
