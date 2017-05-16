# Author: Gardar Thorsteinsson <gardart@gmail.com>
# Changelog:
# 20170516 - Initial code

Write-Host " Importing AD Module..... "
import-module ActiveDirectory

# Settings
$DestinationOU = "OU=DisabledAccounts,OU=Domain Servers,DC=Example,DC=Com" # Destination of the OU that should keep old and disabled computer accounts
$DaysInactive = 350 # Number of days since the computer account logged in
$ExcludedObjects = "EXCHANGESERVER-|sqlinstance-" # Computer account names that should be excluded
$ExcludedOU =  "*OU=DisabledAccounts*" # OU name that should be excluded

# Logging
$logfile = ".\StaleComputerObjectsCleaner_$(get-date -format `"yyyyMMdd_hhmmsstt`").log"
log "Started" green

# Start Collecting stale computer objects
# If computer object has not logged in for $DaysInactive number of days 
# then move it to another OU in AD (defined in $DestinationOU)
$time = (Get-Date).Adddays(-($DaysInactive))
$Computers = Get-ADComputer -Filter {LastLogonTimeStamp -lt $time -and (Name -like "WINSERVER-*" -or OperatingSystem -Like "Windows Server*")} -Properties Name,OperatingSystem,LastLogonTimeStamp,lastlogondate

$Computers = $Computers | where-object {$_ -notmatch $ExcludedObjects}
$Computers = $Computers | where-object {$_.DistinguishedName -notlike $ExcludedOU} 
$Computers | ft Name,OperatingSystem,LastLogonTimeStamp,lastlogondate | Out-File $logfile

log "$($Computers.count) stale computer objects will be moved" green

foreach ($Computer in $Computers){
  if (Test-Connection -ComputerName $Computer.Name -Count 1 -ErrorAction SilentlyContinue){
    #Write-Host "ERROR : $Computer.Name is up and will not be moved" -ForegroundColor Red
    log "ERROR : $Computer.Name is alive and will NOT be moved to disabled OU" Red 
  }
  else{
    #Write-Host "$Computer.Name will be moved to disabled" -ForegroundColor Yellow 
    log "SUCCESS : $Computer.Name will be moved to disabled OU" Yellow 
    Get-ADComputer $Computer.Name | Move-ADObject -TargetPath $DestinationOU -WhatIf
  }
}

#
# Functions
# Logging
function log($string, $color)
{
   if ($Color -eq $null) {$color = "white"}
   write-host $string -foregroundcolor $color
   $string | out-file -Filepath $logfile -append
}
