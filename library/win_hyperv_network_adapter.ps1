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
$vm = Get-Attr -obj $params -name vm -failifempty $true -emptyattributefailmessage "missing required argument: vm"
$state = Get-Attr -obj $params -name state -default "present"

if ("absent" -notcontains $state) {
  Fail-Json $result "The state: $state doesn't exist; State can only be: absent"
}

Function NetworkAdapter-Remove {
  #Check If the VM already exists
  $adapter = Get-VMNetworkAdapter -Name $name -VMName $vm

  if($adapter.count -eq 0) {
    $result.changed = $false
    return
  }

  $results = Remove-VMNetworkAdapter -Name $name -VMName $vm

  if($?) {
    $result.changed = $true
    $result.networkAdapter = $adapter[0]
  }
  else {
    Fail-Json("Failed to remove network adapter", $results)
  }
}

Try {
  switch ($state) {
    "absent" {NetworkAdapter-Remove}
  }

  Exit-Json $result;
} Catch {
  Fail-Json $result $_.Exception.Message
}
