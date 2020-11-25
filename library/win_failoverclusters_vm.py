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
module: win_failoverclusters_vm
version_added: "2.7"
short_description: |
    Adds a VM to Failover Clusters manager, which allows VM migration
    to alternate hosts
description:
    - Adds a VM to Failover Clusters manager
options:
  name:
    description:
      - Name of VM
    required: true
  state:
    description:
      - State of VM
    required: false
    choices:
      - present
      - absent
    default: present
  cluster:
    description:
      - The cluster that the VM will be added to.
      - By default, adds to local cluster.
    required: false
'''

EXAMPLES = '''
  # Create VM
  win_failoverclusters_vm:
    name: Test
    cluster: hypervcluster.example.com
'''

ANSIBLE_METADATA = {
    'status': ['preview'],
    'supported_by': 'community',
    'metadata_version': '1.1'
}
