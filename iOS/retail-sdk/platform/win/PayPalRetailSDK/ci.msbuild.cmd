@echo off 
 
setlocal
IF %1.==. GOTO NoVersion
set appVersion=%1
echo version = %1
echo App version = %appVersion%
GOTO NUGET
:NoVersion
set /p appVersion=Choose your version (ex. 1.0.0.14546) 

:ToDo- Build the SDK projects after updating the app version in the projects

:NUGET
echo Nuget...
IF NOT %1.==. GOTO NoPause1
pause
:NoPause1
cd .\nuget
:DEBUGNUGET
nuget pack PayPalRetailSDK.nuspec -version %appVersion%

echo Package created. Next step is publish PayPalRetailSDK.%appVersion%.nupkg to the server (http://paypalretailsdknuget.azurewebsites.net/)...
IF NOT %1.==. GOTO NoPause2
pause
:NoPause2
nuget push PayPalRetailSDK.%appVersion%.nupkg -s http://paypalretailsdknuget.azurewebsites.net/ pphsdk@2211

:AFTERNUGET
IF NOT %1.==. GOTO NoPause3
pause
:NoPause3
endlocal