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
Set-Attr $result $result.facts.changed = $results.changed

$name = Get-Attr -obj $params -name name -failifempty $true -emptyattributefailmessage $result.facts.missing = $results.missing
$cluster = Get-Attr -obj $params -name cluster

Function Get-ClusterGroupSummary($results) {
    $facts = @{};

    $facts.AntiAffinityClassNames = $results.AntiAffinityClassNames
    $facts.AutoFailbackType       = $results.AutoFailbackType
    $facts.ColdStartSetting       = $results.ColdStartSetting   
    $facts.DefaultOwner           = $results.DefaultOwner       
    $facts.Description            = $results.Description        
    $facts.FailbackWindowEnd      = $results.FailbackWindowEnd  
    $facts.FailbackWindowStart    = $results.FailbackWindowStart
    $facts.FailoverPeriod         = $results.FailoverPeriod     
    $facts.FailoverThreshold      = $results.FailoverThreshold  
    $facts.FaultDomain            = $results.FaultDomain        
    $facts.GroupType              = $results.GroupType          
    $facts.Id                     = $results.Id                 
    $facts.IsCoreGroup            = $results.IsCoreGroup        
    $facts.Name                   = $results.Name               
    $ownerNode                           = @{}
    $ownerNode.BuildNumber               = $results.OwnerNode.BuildNumber
    $ownerNode.CSDVersion                = $results.OwnerNode.CSDVersion
    $ownerNode.Description               = $results.OwnerNode.Description
    $ownerNode.DetectedCloudPlatform     = $results.OwnerNode.DetectedCloudPlatform
    $ownerNode.DrainStatus               = $results.OwnerNode.DrainStatus
    $ownerNode.DrainTarget               = $results.OwnerNode.DrainTarget
    $ownerNode.DynamicWeight             = $results.OwnerNode.DynamicWeight
    $ownerNode.FaultDomain               = $results.OwnerNode.FaultDomain
    $ownerNode.Id                        = $results.OwnerNode.Id
    $ownerNode.MajorVersion              = $results.OwnerNode.MajorVersion
    $ownerNode.Manufacturer              = $results.OwnerNode.Manufacturer
    $ownerNode.MinorVersion              = $results.OwnerNode.MinorVersion
    $ownerNode.Model                     = $results.OwnerNode.Model
    $ownerNode.Name                      = $results.OwnerNode.Name
    $ownerNode.NeedsPreventQuorum        = $results.OwnerNode.NeedsPreventQuorum
    $ownerNode.NodeHighestVersion        = $results.OwnerNode.NodeHighestVersion
    $ownerNode.NodeInstanceID            = $results.OwnerNode.NodeInstanceID
    $ownerNode.NodeLowestVersion         = $results.OwnerNode.NodeLowestVersion
    $ownerNode.NodeName                  = $results.OwnerNode.NodeName
    $ownerNode.NodeWeight                = $results.OwnerNode.NodeWeight
    $ownerNode.SerialNumber              = $results.OwnerNode.SerialNumber
    $ownerNode.State                     = $results.OwnerNode.State
    $ownerNode.StatusInformation         = $results.OwnerNode.StatusInformation
    $ownerNode.Type                      = $results.OwnerNode.Type
    $facts.OwnerNode              = $ownerNode
    $facts.owner_node_name        = $ownerNode.NodeName
    $facts.PersistentState        = $results.PersistentState
    $facts.PlacementOptions       = $results.PlacementOptions
    $facts.PreferredSite          = $results.PreferredSite
    $facts.Priority               = $results.Priority
    $facts.ResiliencyPeriod       = $results.ResiliencyPeriod
    $facts.State                  = $results.State
    $facts.StatusInformation      = $results.StatusInformation
    $facts.UpdateDomain           = $results.UpdateDomain

    return $facts
}

Function XGet-ClusterGroup($name) {
  $cmd = "Get-ClusterGroup $name"
  if($cluster) {
    $cmd += " -Cluster '$cluster'"
  }
  return Invoke-Expression $cmd
}

Function Get-Facts {

  $results = @($name) | ForEach-Object { XGet-ClusterGroup $_ }
  $result.changed = $false
  if($? -and $results) {
    $result.is_present = $true
    $result.vm_count =  @($results).Count
    $result.vms = @($results) | ForEach-Object { Get-ClusterGroupSummary $_ }
  }
  else {
    $result.is_present = $false
    # $result.facts = $null
  }
}


Try {
  Get-Facts

  Exit-Json $result;
} Catch {
  Fail-Json $result $_.Exception.Message
}
