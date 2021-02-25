#Import Modules
Import-Module WebAdministration

# change these settings 
$iisSiteName = "OLAP"
$iisPort = "8000"
$olapServerName = "server\instance"

# optionally also change these settings
$isapiFiles = "c:\Program Files\Microsoft SQL Server\MSAS11.MSSQLSERVER\OLAP\bin\isapi\*"
$iisAbsolutePath = "C:\inetpub\wwwroot\" + $iisSiteName
$iisAppPoolName = $iisSiteName + "_AppPool"
$iisAppPoolUser = "" #default is ApplicationPoolIdentity
$iisAppPoolPassword = ""
$iisAuthAnonymousEnabled = $false
$iisAuthWindowsEnabled = $true
$iisAuthBasicEnabled = $true
$olapSessionTimeout = "3600" #default
$olapConnectionPoolSize = "100" #default

if(!(Test-Path $iisAbsolutePath -pathType container))
{
    #Creating Directory
    mkdir $iisAbsolutePath  | Out-Null

    #Copying Files
    Write-Host -NoNewline "Copying ISAPI files to IIS Folder ... "
    Copy -Path $isapiFiles -Destination $iisAbsolutePath -Recurse
    Write-Host " Done!" -ForegroundColor Green
}
else
{
    Write-Host "Path $iisAbsolutePath already exists! Please delete manually if you want to proceed!" -ForegroundColor Red
    Exit
}

#Check if AppPool already exists
if(!(Test-Path $("IIS:\AppPools\" + $iisAppPoolName) -pathType container))
{
    #Creating AppPool
    Write-Host -NoNewline "Creating ApplicationPool $iisAppPoolName if it does not exist yet ... "
    $appPool = New-WebAppPool -Name $iisAppPoolName
    $appPool.managedRuntimeVersion = "v2.0"
    $appPool.managedPipelineMode = "Classic"

    $appPool.processModel.identityType = 4 #0=LocalSystem, 1=LocalService, 2=NetworkService, 3=SpecificUser, 4=ApplicationPoolIdentity
    #For details see http://www.iis.net/configreference/system.applicationhost/applicationpools/add/processmodel

    if ($iisAppPoolUser -ne "" -AND $iisAppPoolPassword -ne "") {
	    Write-Host 
        Write-Host "Setting AppPool Identity to $iisAppPoolUser"
		$appPool.processmodel.identityType = 3
		$appPool.processmodel.username = $iisAppPoolUser
		$appPool.processmodel.password = $iisAppPoolPassword
	} 
    $appPool | Set-Item
    Write-Host " Done!" -ForegroundColor Green
}
else
{
    Write-Host "AppPool $iisAppPoolName already exists! Please delete manually if you want to proceed!" -ForegroundColor Red
    Exit
}

#Check if WebSite already exists
$iisSite = Get-Website $iisSiteName
if ($iisSite -eq $null)
{
    #Creating WebSite
    Write-Host -NoNewline "Creating WebSite $iisSiteName if it does not exist yet ... "
    $iisSite = New-WebSite -Name $iisSiteName -PhysicalPath $iisAbsolutePath -ApplicationPool $iisAppPoolName -Port $iisPort
    Write-Host " Done!" -ForegroundColor Green
}
else
{
    Write-Host "WebSite $iisSiteName already exists! Please delete manually if you want to proceed!" -ForegroundColor Red
    Exit
}

#Ensuring ISAPI CGI Restriction entry exists for msmdpump.dll
if ((Get-WebConfiguration "/system.webServer/security/isapiCgiRestriction/add[@path='$iisAbsolutePath\msmdpump.dll']") -eq $null)
{
    Write-Host -NoNewline "Adding ISAPI CGI Restriction for $iisAbsolutePath\msmdpump.dll ... "
    Add-WebConfiguration "/system.webServer/security/isapiCgiRestriction" -PSPath:IIS:\  -Value @{path="$iisAbsolutePath\msmdpump.dll"}
    Write-Host " Done!" -ForegroundColor Green
}
#Enabling ISAPI CGI Restriction for msmdpump.dll
Write-Host -NoNewline "Updating existing ISAPI CGI Restriction ... "
Set-WebConfiguration "/system.webServer/security/isapiCgiRestriction/add[@path='$iisAbsolutePath\msmdpump.dll']/@allowed" -PSPath:IIS:\ -Value "True" 
Set-WebConfiguration "/system.webServer/security/isapiCgiRestriction/add[@path='$iisAbsolutePath\msmdpump.dll']/@description" -PSPath:IIS:\ -Value "msmdpump.dll for SSAS"
Write-Host " Done!" -ForegroundColor Green


#Adding ISAPI Handler to WebSite
Write-Host -NoNewline "Adding ISAPI Handler ... "
Add-WebConfiguration /system.webServer/handlers -PSPath $iisSite.PSPath -Value @{name="msmdpump"; path="*.dll"; verb="*"; modules="IsapiModule"; scriptProcessor="$iisAbsolutePath\msmdpump.dll"; resourceType="File"; preCondition="bitness64"}
Write-Host " Done!" -ForegroundColor Green

#enable Windows and Basic Authentication
Write-Host -NoNewline "Setting Authentication Providers ... "
#need to Unlock sections first
Set-WebConfiguration /system.webServer/security/authentication/anonymousAuthentication  MACHINE/WEBROOT/APPHOST -Metadata overrideMode -Value Allow
Set-WebConfiguration /system.webServer/security/authentication/windowsAuthentication  MACHINE/WEBROOT/APPHOST -Metadata overrideMode -Value Allow
Set-WebConfiguration /system.webServer/security/authentication/basicAuthentication  MACHINE/WEBROOT/APPHOST -Metadata overrideMode -Value Allow

Set-WebConfiguration /system.webServer/security/authentication/anonymousAuthentication -PSPath $iisSite.PSPath -Value @{enabled=$iisAuthAnonymousEnabled}
Set-WebConfiguration /system.webServer/security/authentication/windowsAuthentication -PSPath $iisSite.PSPath -Value @{enabled=$iisAuthWindowsEnabled}
Set-WebConfiguration /system.webServer/security/authentication/basicAuthentication -PSPath $iisSite.PSPath -Value @{enabled=$iisAuthBasicEnabled}
Write-Host " Done!" -ForegroundColor Green

#Adding Default Document
Write-Host -NoNewline "Adding Default Document msmdpump.dll ... " 
Add-WebConfiguration /system.webServer/defaultDocument/files -PSPath $iisSite.PSPath -atIndex 0 -Value @{value="msmdpump.dll"}
Write-Host " Done!" -ForegroundColor Green

#Updating OLAP Server Settings
Write-Host -NoNewline "Updating OLAP Server Settings ... "
[xml]$msmdpump = Get-Content "$iisAbsolutePath\msmdpump.ini"
$msmdpump.ConfigurationSettings.ServerName = $olapServerName
$msmdpump.ConfigurationSettings.SessionTimeout = $olapSessionTimeout
$msmdpump.ConfigurationSettings.ConnectionPoolSize = $olapConnectionPoolSize
$msmdpump.Save("$iisAbsolutePath\msmdpump.ini")
Write-Host " Done!" -ForegroundColor Green