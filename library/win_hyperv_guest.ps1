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
$cpu = Get-Attr -obj $params -name cpu -default '1'
$memory = Get-Attr -obj $params -name memory -default '512MB'
$hostserver = Get-Attr -obj $params -name hostserver
$generation = Get-Attr -obj $params -name generation -default 2
$network_switch = Get-Attr -obj $params -name network_switch -default $null
$enable_secure_boot = Get-Attr -obj $params -name enable_secure_boot -default "false" | ConvertTo-Bool
$vlan_id = Get-Attr -obj $params -name vlan_id
$use_static_mac = Get-Attr -obj $params -name use_static_mac -default "false" | ConvertTo-Bool
$vmdir = Get-Attr -obj $params -name dir -default $null
$diskpath = Get-Attr -obj $params -name diskpath -default $null

$showlog = Get-Attr -obj $params -name showlog -default "false" | ConvertTo-Bool
$state = Get-Attr -obj $params -name state -default "present"

$secondary_vlan_id = Get-Attr -obj $params -name secondary_vlan_id

$IPV4_REGEX = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'

if ("poweroff", "present","absent","started","stopped" -notcontains $state) {
  Fail-Json $result "The state: $state doesn't exist; State can only be: present, absent, started or stopped"
}

Function BoolToOnOff($bool) {
  if($bool) {
    return "On"
  }

  return "Off"
}

# https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-random-mac-addresses
Function GenerateRandomMacAddress {
  return [BitConverter]::ToString([BitConverter]::GetBytes((Get-Random -Maximum 0xFFFFFFFFFFFF)), 0, 6).Replace('-', ':')
}

Function VM-Create {
  #Check If the VM already exists
  $CheckVM = Get-VM -name $name -ErrorAction SilentlyContinue

  if($CheckVM) {
    $result.vm = VM-GetSummary($CheckVM)
    return
  }

  $cmd = "New-VM -Name $name"

  if ($memory) {
    $cmd += " -MemoryStartupBytes $memory"
  }

  if ($hostserver) {
    $cmd += " -ComputerName $hostserver"
  }

  if ($generation) {
    $cmd += " -Generation $generation"
  }

  if ($network_switch) {
    $cmd += " -SwitchName '$network_switch'"
  }

  if ($vmdir) {
    $cmd += " -Path '$vmdir'"
  }

  if ($diskpath) {
    #If VHD already exists then attach it, if not create it
    if (Test-Path $diskpath) {
      $cmd += " -VHDPath '$diskpath'"
    } else {
      $cmd += " -NewVHDPath '$diskpath'"
    }
  }

  # Need to chain these
  $results = invoke-expression $cmd
  $results = invoke-expression "Set-VMProcessor $name -Count $cpu"
  # setup the first network
  if($vlan_id) {
    $results = invoke-expression "Set-VMNetworkAdapterVlan -VMName $name -Access -VlanId $vlan_id"
  }
  if($use_static_mac) {
    $mac_address = GenerateRandomMacAddress
    $results = invoke-expression "Set-VMNetworkAdapter -VMName $name -StaticMacAddress $mac_address"
  }

  # for the second adapter, we don't care about a static mac.
  if($secondary_vlan_id) {
    $adapter_name = "Secondary Network Adapter"
    $results = invoke-expression "Add-VMNetworkAdapter -VMName $name -Name '$adapter_name' -SwitchName '$network_switch'"
    $results = invoke-expression "Set-VMNetworkAdapterVlan -VMName $name -VMNetworkAdapterName '$adapter_name' -Access -VlanId $secondary_vlan_id"
  }

  $results = Invoke-Expression "Set-VMFirmware $name -EnableSecureBoot $(BoolToOnOff $enable_secure_boot)"

  $result.changed = $true
  $result.vm = VM-GetSummary($CheckVM)
}

Function VM-Delete {
  $CheckVM = Get-VM -name $name -ErrorAction SilentlyContinue

  if ($CheckVM) {
    $cmd="Remove-VM -Name $name -Force"
    $results = invoke-expression $cmd
    $result.changed = $true
  } else {
    $result.changed = $false
  }
}

Function VM-Start {
  $CheckVM = Get-VM -name $name -ErrorAction SilentlyContinue

  if ($CheckVM) {
    if($CheckVM.state -Match "Running") {
      $result.vm = VM-GetSummary($CheckVM)
      $result.changed = $false
    } else {
      $cmd="Start-VM -Name $name"
      $results = invoke-expression $cmd
      $result.changed = $true
      # Get the updated result
      $CheckVM = Get-VM -name $name -ErrorAction SilentlyContinue
      $result.vm = VM-GetSummary($CheckVM)
    }
  } else {
    Fail-Json $result "The VM: $name; Doesn't exists please create the VM first"
  }
}

Function VM-GetSummary($vm) {
  $adapters = @($vm.NetworkAdapters `
    | ForEach-Object { VM-GetNetworkAdapterSummary $_ })

  return @{
    Name = $vm.name;
    State = $vm.state;
    CPUUsagePct = $vm.CPUUsage;
    MemoryAssignedBytes = $vm.MemoryAssigned;
    UptimeSeconds = $vm.Uptime.TotalSeconds;
    Status = $vm.Status;
    Version = $vm.Version;
    NetworkAdapters = $adapters;

    IPAddressesV4 = @($vm.NetworkAdapters `
      | Select-Object -Expand IpAddresses `
      | Where-Object {$_ -Match $IPV4_REGEX});
  }
}

Function VM-GetNetworkAdapterSummary($adapter) {
  return @{
    Name = $adapter.Name;
    Switch = $adapter.SwitchName;
    MacAddress = $adapter.MacAddress;
    IpAddresses = $adapter.IPAddresses;
    IpAddressesV4 = @($adapter.IPAddresses `
      | Where-Object {$_ -Match $IPV4_REGEX});
  }
}

Function VM-Poweroff {
  $CheckVM = Get-VM -name $name -ErrorAction SilentlyContinue
  $ignore_existence = Get-Attr -obj $params -name ignore_existence -default "true" | ConvertTo-Bool

  if (! $CheckVM) {
    $result.changed = $false
    if($ignore_existence) {
      $result.warning = "The VM didn't exist"
    } else {
      Fail-Json $result "The VM: $name; Doesn't exists please create the VM first"
    }
    return
  }

  $cmd="Stop-VM -Name $name -TurnOff"
  $results = invoke-expression $cmd
  $result.changed = $true
}

Function VM-Shutdown {
$CheckVM = Get-VM -name $name -ErrorAction SilentlyContinue

  if ($CheckVM) {
    $cmd="Stop-VM -Name $name"
    $results = invoke-expression $cmd
    $result.changed = $true
  } else {
    Fail-Json $result "The VM: $name; Doesn't exists please create the VM first"
  }
}

Try {
  switch ($state) {
    "present" {VM-Create}
    "absent" {VM-Delete}
    "started" {VM-Start}
    "stopped" {VM-Shutdown}
    "poweroff" {VM-Poweroff}
  }

  Exit-Json $result;
} Catch {
  Fail-Json $result $_.Exception.Message
}
