@ECHO OFF
REM Add the following script to your WinPE image under Sources\boot.wim\Windows\System32\startnet.cmd
:VBSDynamicBuild
SET TempVBSFile=%temp%\~tmpSendKeysTemp.vbs
IF EXIST "%TempVBSFile%" DEL /F /Q "%TempVBSFile%"
ECHO Set WshShell = WScript.CreateObject("WScript.Shell") >>"%TempVBSFile%"
ECHO Wscript.Sleep 900                                    >>"%TempVBSFile%"
ECHO WshShell.SendKeys "{F11}"                            >>"%TempVBSFile%
ECHO Wscript.Sleep 900                                    >>"%TempVBSFile%"
CSCRIPT //nologo "%TempVBSFile%"
wpeinit
cmd /k imagestart.bat
cd /D N: