#!/usr/bin/python
# -*- coding: utf-8 -*-

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

# this is a windows documentation stub. actual code lives in the .ps1
# file of the same name

DOCUMENTATION = '''
---
module: win_failoverclusters_vm_facts
version_added: "2.7"
short_description: |
    Returns information from Failover Cluster Manager about
    specific VMs
description:
    - >
      Returns information from Failover Cluster Manager about
      specific VMs. This could be used to find out which Hyper-V
      Hosts VMs are present on in order to perform subsequent
      operations.
options:
  name:
    description:
      - Names of vms we want to get information about
    required: true
  cluster:
    description:
      - The cluster that the VM will be added to.
      - By default, adds to local cluster.
    required: false
'''

EXAMPLES = '''
  # Get information about the VM named Test
  win_failoverclusters_vm_facts:
    name: Test
    cluster: hypervcluster.example.com

  # Get information about the VMs named Test1 and Test2
  win_failoverclusters_vm_facts:
    name:
      - Test1
      - Test2
    cluster: hypervcluster.example.com
'''

ANSIBLE_METADATA = {
    'status': ['preview'],
    'supported_by': 'community',
    'metadata_version': '1.1'
}
