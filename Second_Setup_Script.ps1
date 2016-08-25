###This script is the second setup script and should be run from a local admin account
###It does two things
###First, after setting the script execution policy, it adds the NWRDesktop AD group 
###to the local administrator group. It should automatically ask for AD credentials as part of this if needed
###Second, it adds the primary user for the computer to the remote desktop users group
###third, it enables remote desktop

##set script execution policy
##note that this really has to be done as a standalone command, but I put it here because typing sucks.

Set-ExecutionPolicy RemoteSigned 


##add Desktop admins to local administrator group

#get local computer name
$computername = (Get-WmiObject Win32_Computersystem).name

#get path to loacl admin group
$localgroup =[ADSI]"WinNT://$computername/Administrators,group"

#get path to NWRDesktop group
$adgroup =[ADSI]"WinNT://domain.com/DesktopAdmins,group"

#add NWRDekstop to admin
$localGroup.PSBase.Invoke("Add",$adgroup.PSBase.Path)

##Add Primary user to local remote users group

#load frameworks for VB to work
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

#get domain user name
$username = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a domain user name", "Get Domain User Name")

#pull current local computer name
$computername = (Get-WmiObject Win32_Computersystem).name

#set $localgroup to local remote desktop users group
$localgroup =[ADSI]"WinNT://$computername/Remote Desktop Users,group”

#set path to ad user
$aduser = [ADSI]"WinNT://domain.com/$username,user”

#add ad user using full path
$localGroup.PSBase.Invoke("Add”,$aduser.PSBase.Path)

##enable remote desktop services
$RDPSettings = Get-WmiObject -Class Win32_TerminalServiceSetting -Namespace root\CIMV2\TerminalServices
$result = $RDPSettings.SetAllowTSConnections(1,1)
