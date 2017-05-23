# Author: Gardar Thorsteinsson <gardart@gmail.com>
# Changelog:
# 20170516 - Initial code

Write-Host " Importing AD Module..... "
import-module ActiveDirectory

# Logging
$logfile = "ServerCleanup_Disable_Stale_Objects_$(get-date -format `"yyyyMMdd_hhmmsstt`").log"
log "Started" green

# Settings
$DestinationOU = "OU=DisabledAccounts,OU=Servers,DC=Example,DC=Com" # Destination of the OU that should keep old and disabled computer accounts
$DaysInactive = 365 # Number of days since the computer account logged in
$ExcludedObjects = "sql-|inst-" # Computer account names that should be excluded

# Start Collecting stale computer objects from OU defined by $DestinationOU
# If computer object has not logged in for $DaysInactive number of days 
# then disable that computer account
$time = (Get-Date).Adddays(-($DaysInactive))
$Computers = Get-ADComputer -Filter {LastLogonTimeStamp -lt $time -and enabled -eq $True} -SearchBase $DestinationOU -Properties Name,OperatingSystem,LastLogonTimeStamp,lastlogondate

$Computers = $Computers | where-object {$_ -notmatch $ExcludedObjects}

$Computers | ft Name,OperatingSystem,DistinguishedName,LastLogonTimeStamp,lastlogondate | Out-File $logfile

log "$($Computers.count) stale computer objects will be disabled" green

foreach ($Computer in $Computers){
  if (Test-Connection -ComputerName $Computer.Name -Count 1 -ErrorAction SilentlyContinue){
    log "ERROR : $Computer.Name is alive and will NOT be disabled" Red 
  }
  else{    
    log "SUCCESS : $Computer.Name will be disabled" Yellow 
    Get-ADComputer $Computer.Name | Set-ADComputer -Enabled $false -WhatIf
  }
}


# Functions

function log($string, $color)
{
   if ($Color -eq $null) {$color = "white"}
   write-host $string -foregroundcolor $color
   $string | out-file -Filepath $logfile -append
}
