# Author: Gardar Thorsteinsson <gardart@gmail.com>
# Changelog:
# 20170516 - Initial code

Write-Host " Importing AD Module..... "
import-module ActiveDirectory

# Logging
$logfile = "ServerCleanup_Move_Stale_Objects_$(get-date -format `"yyyyMMdd_hhmmsstt`").log"
log "Started" green

# Settings
$DestinationOU = "OU=DisabledAccounts,OU=Domain Servers,DC=EXAMPLE,DC=COM" # Destination of the OU that should keep old and disabled computer accounts
$DaysInactive = 350 # Number of days since the computer account logged in

# Start Collecting stale computer objects
# If computer object has not logged in for $DaysInactive number of days 
# then move it to another OU in AD (defined in $DestinationOU)
$time = (Get-Date).Adddays(-($DaysInactive))

# Read from file and move stale server objects to another OU
$ComputerAccountNames = Get-content "c:\temp\computernames.txt"
foreach ($ComputerAccountName in $ComputerAccountNames){
# Test if the computer account responds to a ping
  if (Test-Connection -ComputerName $ComputerAccountName -Count 1 -ErrorAction SilentlyContinue){
    Write-Host "$ComputerAccountName is up and will not be moved" -ForegroundColor Green
    log "$ComputerAccountName is up and will not be moved" Green
  }
  else{
    Write-Host "$ComputerAccountName will be moved to disabled" -ForegroundColor Red
    log "$ComputerAccountName will be moved to disabled OU" Red
    Get-ADComputer $ComputerAccountName | Move-ADObject -TargetPath $DestinationOU -Whatif
  }
}

# Functions

function log($string, $color)
{
   if ($Color -eq $null) {$color = "white"}
   write-host $string -foregroundcolor $color
   $string | out-file -Filepath $logfile -append
}
