#!powershell
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON

#Requires -Module Ansible.ModuleUtils.Legacy

$params = Parse-Args $args;
$result = @{};
Set-Attr $result "changed" $false;

$name = Get-Attr -obj $params -name name -failifempty $true -emptyattributefailmessage "missing required argument: name"
$vmName = Get-Attr -obj $params -name vm_name -failifempty $true -emptyattributefailmessage "missing required argument: vm_name"
$hostserver = Get-Attr -obj $params -name hostserver
$state = Get-Attr -obj $params -name state -default "present"

if ("present","absent" -notcontains $state) {
  Fail-Json $result "The state: $state doesn't exist; State can only be: present, or absent"
}

Function Checkpoint-GetSummary($checkpoint) {
  $summary = @{}
  $summary.CheckpointType = $checkpoint.CheckpointType              
  $summary.ParentCheckpointId = $checkpoint.ParentCheckpointId          
  $summary.ParentCheckpointName = $checkpoint.ParentCheckpointName        
  # $summary.BatteryPassthroughEnabled = $checkpoint.BatteryPassthroughEnabled   
  # $summary.CimSession = $checkpoint.CimSession                  
  # $summary.ComPort1 = $checkpoint.ComPort1                    
  # $summary.ComPort2 = $checkpoint.ComPort2                    
  $summary.ComputerName = $checkpoint.ComputerName                
  $summary.CreationTime = $checkpoint.CreationTime                
  # $summary.DVDDrives = $checkpoint.DVDDrives                   
  $summary.DynamicMemoryEnabled = $checkpoint.DynamicMemoryEnabled        
  # $summary.FibreChannelHostBusAdapters = $checkpoint.FibreChannelHostBusAdapters 
  # $summary.FloppyDrive = $checkpoint.FloppyDrive                 
  $summary.Generation = $checkpoint.Generation                  
  # $summary.GuestControlledCacheTypes = $checkpoint.GuestControlledCacheTypes   
  # $summary.HardDrives = $checkpoint.HardDrives                  
  # $summary.HighMemoryMappedIoSpace = $checkpoint.HighMemoryMappedIoSpace     
  $summary.Id = $checkpoint.Id                          
  $summary.IsAutomaticCheckpoint = $checkpoint.IsAutomaticCheckpoint       
  $summary.IsClustered = $checkpoint.IsClustered                 
  $summary.IsDeleted = $checkpoint.IsDeleted                   
  $summary.LockOnDisconnect = $checkpoint.LockOnDisconnect            
  # $summary.LowMemoryMappedIoSpace = $checkpoint.LowMemoryMappedIoSpace      
  $summary.MemoryMaximum = $checkpoint.MemoryMaximum               
  $summary.MemoryMinimum = $checkpoint.MemoryMinimum               
  $summary.MemoryStartup = $checkpoint.MemoryStartup               
  $summary.Name = $checkpoint.Name                        
  # $summary.NetworkAdapters = $checkpoint.NetworkAdapters             
  $summary.Notes = $checkpoint.Notes                       
  # $summary.ParentSnapshotId = $checkpoint.ParentSnapshotId            
  # $summary.ParentSnapshotName = $checkpoint.ParentSnapshotName          
  $summary.Path = $checkpoint.Path                        
  $summary.ProcessorCount = $checkpoint.ProcessorCount              
  # $summary.RemoteFxAdapter = $checkpoint.RemoteFxAdapter             
  # $summary.SizeOfSystemFiles = $checkpoint.SizeOfSystemFiles           
  # $summary.SnapshotType = $checkpoint.SnapshotType                
  $summary.State = $checkpoint.State                       
  $summary.Version = $checkpoint.Version                     
  $summary.VMId = $checkpoint.VMId                        
  # $summary.VMIntegrationService = $checkpoint.VMIntegrationService        
  $summary.VMName = $checkpoint.VMName                      
  
  return $summary
}

Function Checkpoint-GetExisting {
  $cmd = "Get-VMSnapshot -name $name -VMName $vmName -ErrorAction SilentlyContinue"
  if ($hostserver) {
    $cmd += " -ComputerName $hostserver"
  }
  $existing = Invoke-Expression $cmd
  return $existing
}

Function Checkpoint-Create {
  $existing = Checkpoint-GetExisting

  if($existing) {
    $result.changed = $false
    $result.checkpoint = Checkpoint-GetSummary $existing
    return
  }

  $cmd = "Checkpoint-VM -Name $vmName -SnapshotName $name -Passthru"
  if ($hostserver) {
    $cmd += " -ComputerName $hostserver"
  }

  $results = Invoke-Expression $cmd

  if($?) {
    $result.changed = $true
    $result.checkpoint = Checkpoint-GetSummary $results
  } 
  else {
    Fail-Json("Failed to create checkpoint", $results)
  }
}

Function Checkpoint-Delete {
  $existing = Checkpoint-GetExisting

  if (! $existing) {
    $result.changed = $false
    return
  }

  $cmd = "Remove-VMSnapshot -Name $name -VMName $vmName"
  if ($hostserver) {
    $cmd += " -ComputerName $hostserver"
  }
  $results = Invoke-Expression $cmd

  if($?) {
    $result.changed = $true
    $result.checkpoint = Checkpoint-GetSummary $existing
  }
  else {
    Fail-Json("Failed to remove checkpoint", $results)
  }
}

Try {
  switch ($state) {
    "present" {Checkpoint-Create}
    "absent" {Checkpoint-Delete}
  }

  Exit-Json $result;
} Catch {
  Fail-Json $result $_.Exception.Message
}
