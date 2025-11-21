# nut2snmp

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A lightweight bridge script that exposes Network UPS Tools (NUT) data through SNMP using the standard UPS-MIB (RFC 1628).

## Overview

This script acts as a pass_persist handler for Net-SNMP, translating NUT UPS status information to SNMP OIDs. It enables SNMP-based monitoring tools to query UPS data from systems running NUT.

## Features

- Implements core UPS-MIB OIDs (.1.3.6.1.2.1.33)
- Zero dependencies beyond standard shell utilities
- Supports both SNMPv2c and SNMPv3 queries
- Compatible with any NUT-supported UPS device

## Prerequisites

- Network UPS Tools (NUT) configured and running
- Net-SNMP daemon installed
- Shell environment with basic utilities (sh, awk)

## Installation

1. Copy the script to your preferred location:
```bash
cp nut2snmp.sh /opt/home/
chmod +x /opt/home/nut2snmp.sh
```

2. Configure Net-SNMP to use the script by adding this line to `/etc/snmp/snmpd.conf`:
```
pass_persist .1.3.6.1.2.1.33 /opt/home/nut2snmp.sh ups@127.0.0.1
```

3. Restart the SNMP daemon:
```bash
systemctl restart snmpd
```

## Usage

The script accepts one optional argument specifying the UPS to monitor:

```bash
/opt/home/nut2snmp.sh [ups_name@host]
```

Default: `ups@127.0.0.1`

## Supported OIDs

| OID | Description | NUT Variable |
|-----|-------------|--------------|
| .1.3.6.1.2.1.33.1.1.1.0 | Manufacturer | device.mfr, ups.mfr |
| .1.3.6.1.2.1.33.1.1.2.0 | Model | device.model, ups.model |
| .1.3.6.1.2.1.33.1.1.3.0 | Firmware Version | ups.firmware |
| .1.3.6.1.2.1.33.1.2.1.0 | Battery Status | ups.status |
| .1.3.6.1.2.1.33.1.2.3.0 | Minutes Remaining | battery.runtime |
| .1.3.6.1.2.1.33.1.2.4.0 | Battery Charge (%) | battery.charge |
| .1.3.6.1.2.1.33.1.2.5.0 | Battery Voltage | battery.voltage |
| .1.3.6.1.2.1.33.1.3.3.1.3.1 | Input Voltage | input.voltage |
| .1.3.6.1.2.1.33.1.4.1.0 | Output Source | ups.status |
| .1.3.6.1.2.1.33.1.4.4.1.2.1 | Output Voltage | output.voltage |
| .1.3.6.1.2.1.33.1.4.4.1.5.1 | Output Load (%) | ups.load |

## Testing

### Test the script directly
```bash
echo -e "PING\nget\n.1.3.6.1.2.1.33.1.1.2.0" | /opt/home/nut2snmp.sh
```

### Query individual OIDs
```bash
snmpget -v2c -c <community> localhost .1.3.6.1.2.1.33.1.1.2.0  # UPS Model
snmpget -v2c -c <community> localhost .1.3.6.1.2.1.33.1.2.4.0  # Battery Charge
```

### Walk all UPS data
```bash
snmpwalk -v2c -c <community> localhost .1.3.6.1.2.1.33
```

## Compatibility

Tested on:

- Server: Entware aarch64-k3.10 (Asuswrt-Merlin 3004.388.8_4_rog of ROG Rapture GT-AX11000 Pro)
  - Network UPS Tools upsd 2.8.1
  - NET-SNMP 5.9.4.pre2
- Client: Synology DSM 7.2.2-72806 Update 4

## License

Copyright 2025 Tianyu (Sky) Lu

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Author

Tianyu (Sky) Lu
