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
$cluster = Get-Attr -obj $params -name cluster
$state = Get-Attr -obj $params -name state -default "present"

if ("present","absent" -notcontains $state) {
  Fail-Json $result "The state: $state doesn't exist; State can only be: present, absent"
}

Function Role-GetExisting($vmname) {
  $existing_vm = Get-ClusterGroup -Name "$vmname"
  return $existing_vm
}

Function Remove-Role {
  $existing_vm = Role-GetExisting($name)
  if(! $existing_vm) {
    $result.changed = $false
    return
  }

  $resource_name = $existing_vm.name
  # The VM Role doesn't exist yet so we can add it
  $cmd = "Remove-ClusterGroup -Name '$name' -Force -RemoveResources"
  if($cluster) {
    $cmd += " -Cluster '$cluster'"
  }

  $results = Invoke-Expression $cmd
  if($?) {
    $result.changed = $true
  }
  else {
    Fail-Json("Failed to remove cluster virtual machine role", $results)
  }
}

Function Add-Role {
  #Check If the VM already exists
  $existing_vm = Role-GetExisting($name)
  if($existing_vm) {
    $result.changed = $false
    # has too much information
    # $result.vm = $existing_vm
    return
  }

  # The VM Role doesn't exist yet so we can add it
  $cmd = "Add-ClusterVirtualMachineRole -VirtualMachine '$name' -Name '$name'"
  if($cluster) {
    $cmd += " -Cluster '$cluster'"
  }

  $results = Invoke-Expression $cmd
  if($?) {
    $result.changed = $true
    $result.vm = $results
  }
  else {
    Fail-Json("Failed to add cluster virtual machine role", $results)
  }
}


Try {
  switch ($state) {
    "present" {Add-Role}
    "absent" {Remove-Role}
  }

  Exit-Json $result;
} Catch {
  Fail-Json $result $_.Exception.Message
}
