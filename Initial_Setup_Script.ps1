###This script does a number of things under the initial local account we create
###First, it sets the script execution policy so that it can do the rest of it's work
###Second, it configures the Windows Firewall to allow ping to and from the machine, IPv4 and IPv6
###Third, it removes as much of the Dell/Intel crapware as possible. (There's a few things that have to 
###be done manually, but it's like two things after this script is done
###Fourth, it sets the power management settings to never sleep
###Finally, it renames the computer, adds it to the domain with the new name and reboots the computer.


##set script execution policy

Set-ExecutionPolicy RemoteSigned

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
Get-AppxPackage *getstarted*|Remove-AppxPackage

#remove preinstalled OneNote
Get-AppxPackage *onenote*|Remove-AppxPackage

#remove XBox app
Get-AppxPackage *xboxapp*|Remove-AppxPackage

#remove all Dell apps excet for support assist and product registration
#those have to be done manually

$app = Get-WmiObject -Class Win32_Product -Filter "Name like 'Dell Command | Update'"
$app.Uninstall()
$app = Get-WmiObject -Class Win32_Product -Filter "Name like 'Dell Digital Delivery'"
$app.Uninstall()
$app = Get-WmiObject -Class Win32_Product -Filter "Name like 'Dell Foundation Services'"
$app.Uninstall()
$app = Get-WmiObject -Class Win32_Product -Filter "Name like 'Dell Update'"
$app.Uninstall()
$app = Get-WmiObject -Class Win32_Product -Filter "Name = 'DSC/AA Factory Installer'"
$app.Uninstall()

#remove intel management engine and security assist

$app = Get-WmiObject -Class Win32_Product -Filter "Name = 'Intel(R) Management Engine Components'"
$app.Uninstall()
$app = Get-WmiObject -Class Win32_Product -Filter "Name = 'Intel® Security Assist'"
$app.Uninstall()

##set desktop power management
powercfg -S SCHEME_MIN

##Set time zone
#Set-TimeZone "Eastern Standard Time"

##rename computer, add to domain and restart
#load enough .Net to get a nice dialog box, pipe the acknowledgement output to null
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

#get the new computer name from the user
$newComputerName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Desired Computer Name","Get Computer Name") 

#add the computer to the domain with the new name and restart
#it should automatically ask for credentials
Add-Computer -DomainName "domain.com" -NewName $newComputerName -Restart
