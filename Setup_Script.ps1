###So if you have something like InTune/SCCM, you probably won't need this, but if you want to do a "light touch"
###setup on a windows machine, and not deal with building an imaging server and endless DISM work to keep the image up to date, 
###this works well with what a new machine ships with

###First, this targets Dell boxes. You can easily adapt it to other vendors, but I use Dell, so yeah
###Second, this is built with an on-prem AD in mind. I would imagine Azure works well too, but your mileage may vary
###it assumes you have some form of proper file server


###for this to run right, you'll want to attach the machine to AD FIRST, then run this script.

###What the script does

###First, it sets the script execution policy so that it can do the rest of it's work, and sets up local admins

###Second, it configures the Windows Firewall to allow ping to and from the machine, IPv4 and IPv6. This is required
###by some desktop management setups, including mine.

###Third, it removes as much of the Dell/Intel/Xbox software as possible. (There's a few things that aren't
###REALLY uninstalled, like the XBox stuff, but it gets it out of the start menu and settings -> apps, so I'll take it.)

###Fourth, it sets the power management settings to never sleep. This is for a desktop. Laptops will need something different.

###Fifth, it adds our AD desktop admin group to the local admin group.

###Sixth, it sets up the primary user on the desktop to be able to remote into it.

###Seventh, it sets up the desktop background image and some registry keys pertinent to screen saver activation

###Eighth, it sets up the printers as needed, including driver installs. (EVERYONE DOES NOT NEED EVERY PRINTER) The printer section
####is at the bottom, uncomment other printers as needed.

###Finally, it does a series of initial application installs.



##set script execution policy
##note you'll probably have to run this separately first.

Set-ExecutionPolicy RemoteSigned

##uncomment to enable F8 menu so if things go wrong, we can start the computer in safe mode. THis is not going to be a default, the way
##windows does this is too annoying

# bcdedit --% /set {bootmgr} displaybootmenu yes

##set up local admin accounts for desktop support staff

#get the initial password in a secure text box. If you run this in the powershell ISE, you may have to move that window aside to see the 
#Read-Host dialog box
$DefPassword = Read-Host -AsSecureString

#create the local accounts
#note: comment out any you may have already manually created
New-LocalUser -Name "admin1name" -Password $DefPassword -AccountNeverExpires -Description "Local Admin Account" -FullName "Super Admin One"
New-LocalUser -Name "admin2name" -Password $DefPassword -AccountNeverExpires -Description "Local Admin Account" -FullName "Super Admin Two"

#set the accounts to have to change password on next login. Can't do this with straight powershell, which is silly
net user admin1name /logonpasswordchg:yes
net user admin2name /logonpasswordchg:yes

#add to administrators group
Add-LocalGroupMember -Group "Administrators" -Member "admin1name"
Add-LocalGroupMember -Group "Administrators" -Member "admin2name"


##Set firewall rules to allow ping

#enable Inbound
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Profile Public -Direction Inbound -Enabled True
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Profile Domain -Direction Inbound -Enabled True
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)" -Profile Public -Direction Inbound -Enabled True
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-In)" -Profile Domain -Direction Inbound -Enabled True

#enable outbound
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-Out)" -Profile Public -Direction Outbound -Enabled True
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-Out)" -Profile Domain -Direction Outbound -Enabled True
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-Out)" -Profile Public -Direction Outbound -Enabled True
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv6-Out)" -Profile Domain -Direction Outbound -Enabled True

##uninstall built-in MS apps

#remove Get Office
Get-AppxPackage *officehub*|Remove-AppxPackage

#remove Get Skype
Get-AppxPackage *skypeapp*|Remove-AppxPackage

#remove Get Started
Get-AppxPackage *Getstarted*|Remove-AppxPackage

#remove preinstalled OneNote
Get-AppxPackage *onenote*|Remove-AppxPackage

#remove XBox app
Get-AppxPackage *XboxApp*|Remove-AppxPackage

#remove the rest of the XBox crap
Get-AppxPackage *Xbox* | Remove-AppxPackage

#remove linkedin app
Get-AppxPackage *linkedin*|Remove-AppxPackage

#remove Groove Music
Get-AppxPackage *zunemusic* | Remove-AppxPackage

#remove LinkedIn
Get-AppxPackage *LinkedIn* | Remove-AppxPackage

#remove preinstalled office
Get-AppxPackage *Office* | Remove-AppxPackage

#remove Skype
Get-AppxPackage *SkypeApp* | Remove-AppxPackage

#remove Dell support assist
Get-AppxPackage *DellSupportAssist* | Remove-AppxPackage

#remove Dell Digital Delivery
Get-AppxPackage *DellDigitalDelivery* | Remove-AppxPackage

#uninstall default OneDrive
taskkill /f /im OneDrive.exe
c:\Windows\SysWOW64\OneDriveSetup.exe /uninstall

#remove all Dell apps except for support assist and product registration
#those have to be done manually

#$app = Get-WmiObject -Class Win32_Product -Filter "Name like 'Dell Command | Update'"
#$app.Uninstall()
$app = Get-WmiObject -Class Win32_Product -Filter "Name like 'Dell Digital Delivery'"
$app.Uninstall()
$app = Get-WmiObject -Class Win32_Product -Filter "Name like 'Dell Foundation Services'"
$app.Uninstall()
$app = Get-WmiObject -Class Win32_Product -Filter "Name like 'Dell Update'"
$app.Uninstall()
$app = Get-WmiObject -Class Win32_Product -Filter "Name = 'DSC/AA Factory Installer'"
$app.Uninstall()
#remove Dell ControlVault
$app = Get-WmiObject -Class Win32_Product -Filter "Name like 'Dell ControlVault Host Components Installer 64 bit'"
$app.Uninstall()

#remove intel management engine and security assist

$app = Get-WmiObject -Class Win32_Product -Filter "Name = 'Intel(R) Management Engine Components'"
$app.Uninstall()
$app = Get-WmiObject -Class Win32_Product -Filter "Name = 'Intel® Security Assist'"
$app.Uninstall()

##set desktop power management 
powercfg -S SCHEME_MIN

##Set time zone
Set-TimeZone "Eastern Standard Time"

###Note that we don't use this anymore, by doing this manually as the first step in the setup, we only need one script instead of two, and life
###gets a lot easier. However, leaving this here in case we need it somewhere else as a reference
##rename computer, add to domain and restart
#load enough .Net to get a nice dialog box, pipe the acknowledgement output to null
#[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

#get the new computer name from the user
#$newComputerName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Desired Computer Name","Get Computer Name") 

#add the computer to the domain with the new name and restart
#it should automatically ask for credentials
#Add-Computer -DomainName "nwrdc.com" -NewName $newComputerName -Restart

#Rename-Computer -NewName $name
#Restart-Computer -Force -Timeout 5

##add our desktop admin group to local administrator group
##this is kind of the kludgy way to do it, but it works. May clean it up one day. May not.

#get local computer name
$computername = (Get-WmiObject Win32_Computersystem).name

#get path to local admin group
$localgroup =[ADSI]"WinNT://$computername/Administrators,group"

#get path to desktop admin group group
$adgroup =[ADSI]"WinNT://domain.com/desktopadmin,group"

#add desktop admin group to admin
$localGroup.PSBase.Invoke("Add",$adgroup.PSBase.Path)

##Add Primary user to local remote users group

#load frameworks for VB to work
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

#get domain user name
$username = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a domain user name for the person this machine is assigned to", "Get Domain User Name")

#pull current local computer name
$computername = (Get-WmiObject Win32_Computersystem).name

#set $localgroup to local remote desktop users group
$localgroup =[ADSI]"WinNT://$computername/Remote Desktop Users,group"

#set path to ad user
$aduser = [ADSI]"WinNT://domain.com/$username,user"

#add ad user using full path
$localGroup.PSBase.Invoke("Add"",$aduser.PSBase.Path)

##enable remote desktop services
$RDPSettings = Get-WmiObject -Class Win32_TerminalServiceSetting -Namespace root\CIMV2\TerminalServices
$result = $RDPSettings.SetAllowTSConnections(1,1)

##copy the desktop image
copy -Path "\\domain.com\directory\Software\img0.jpg" -Destination "C:\Windows\Web\Wallpaper\Theme1\img0.jpg"

##registry entries to set up screen saver and desktop background defaults

#Set the initial registry location
Set-Location -Path "Registry::\HKEY_USERS\.DEFAULT\Control Panel\Desktop"

#as this path exists, we only have to add keys. the "." is powershell for "here"
New-ItemProperty -Path . -Name "Wallpaper" -PropertyType String -Value "C:\Windows\Web\Wallpaper\Theme1\img0.jpg"
New-ItemProperty -Path . -Name "WallpaperOriginX" -PropertyType DWord -Value "00000000"
New-ItemProperty -Path . -Name "WallpaperStyle" -PropertyType String -Value "10"
New-ItemProperty -Path . -Name "ScreenSaverActive" -PropertyType String -Value "1"
New-ItemProperty -Path . -Name "ScreenSaverIsSecure" -PropertyType String -Value "1"
New-ItemProperty -Path . -Name "ScreenSaverTimeOut" -PropertyType String -Value "600"
New-ItemProperty -Path . -Name "SCRNSAVE.EXE" -PropertyType String -Value "C:\Windows\system32\Mystify.scr"

#change the current working path
Set-Location -Path "Registry::\HKEY_USERS\.DEFAULT\Software\Policies\Microsoft"

#since the path we need doesn't yet exist, we have to build it. Unfortunately, that's one step at a time
New-Item -Path . -Name "Windows"
New-Item -Path .\Windows -Name "Control Panel"
New-Item -Path ".\Windows\Control Panel" -Name "Desktop"

#change the current path to the registry entry we just built
Set-Location -Path ".\Windows\Control Panel\Desktop"

#set the keys
New-ItemProperty -Path . -Name "ScreenSaverActive" -PropertyType String -Value "1"
New-ItemProperty -Path . -Name "ScreenSaverIsSecure" -PropertyType String -Value "1"
New-ItemProperty -Path . -Name "ScreenSaverTimeOut" -PropertyType String -Value "600"
New-ItemProperty -Path . -Name "SCRNSAVE.EXE" -PropertyType String -Value "C:\Windows\system32\Mystify.scr"

##Printer setup
##we have one printer that everyone needs, the others are optional

##Install the KMB drivers
##add kmb driver to driver store on machine
$kmdriverargs = {pnputil.exe -i -a \\domain.com\directory\Software\Drivers\Printers\KMB\Windows\BHC554ePSWinx64_5120EN\*.inf}
Invoke-Command -ScriptBlock $kmdriverargs

#add printer driver to printer driver list
Add-PrinterDriver -Name "KONICA MINOLTA C554SeriesPS"

#Actually add the HP universal PCL driver to the available driver list even though it shows there...sigh
Add-PrinterDriver -Name "HP Universal Printing PCL 6"

#Everyone gets this one
Add-Printer -name "Konica-Minolta BizHub" -DriverName "KONICA MINOLTA C554SeriesPS" -PortName "http://printerIPaddress/ipp"

#only some people need this one
#Add-Printer -name "HP Color Laser" -DriverName "HP Universal Printing PCL 6" -PortName "http://printerIPaddress"

#only some other people need this one
#Add-Printer -name "HP black and white laser" -DriverName "HP Universal Printing PCL 6" -PortName "http://printerIPaddress"

#only these people need this one
#Add-Printer -name "HP LaserJet 400" -DriverName "HP Universal Printing PCL 6" -PortName "http://printerIPaddress"

#only those need this one
#Add-Printer -name "HP LaserJet 400" -DriverName "HP Universal Printing PCL 6" -PortName "http://printerIPaddress"


####APPLICATION INSTALLERS

####Bigfix client

####Install BES Client Block
####WILL NOT WORK IF NOT JOINED TO THE DOMAIN

##create the paths used to copy BES client local, install, then delete installer
##SO many problems avoided this way

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$BESFilePath = Join-Path $DesktopPath WindowsAgent\setup.exe
$DeletePath = Join-Path $DesktopPath WindowsAgent\

##copy the BES client installer folder from the operations share
copy -Recurse -Path "\\domain.com\directory\Software\BESAgent\WindowsAgent" -Destination $DesktopPath

##silent install of BES client
Start-Process -FilePath $BESFilePath -ArgumentList "/s /v/qn" -Wait -NoNewWindow

##delete folder when done
Remove-Item -Path $DeletePath -recurse -force

##Infopath installer. This is only for managers, so commented out by default.
#$infopathvargs = {\\domain.com\directory\Software\infopath\setup.exe /config \\domain.com\directory\Software\infopath\infopathr.ww\config.xml}
#Invoke-Command -ScriptBlock $infopathvargs

##Chrome Installer
$chromevargs = {msiexec /i \\domain.com\directory\Software\GoogleChromeStandaloneEnterprise64.msi /qn /norestart}
Invoke-Command -ScriptBlock $chromevargs

##Firefox Installer
$firefoxvargs = {\\domain.com\directory\Software\FirefoxSetup.exe /s}
Invoke-Command -ScriptBlock $firefoxvargs

##Office 2016 installer. This downloads the current version from the office CDN
$officevargs = {\\domain.com\directory\Software\Office2016\Windows\setup.exe /configure \\domain.com\directory\Software\Office2016\Windows\Configuration.xml}
Invoke-Command -ScriptBlock $officevargs
