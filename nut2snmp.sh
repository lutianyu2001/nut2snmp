#!/bin/sh

# nut2snmp: A lightweight NUT to UPS-MIB Bridge
# Tianyu (Sky) Lu (tianyu@lu.fm)
# 2025-11-21
# 
# =============================================================================
# Copyright 2025 Tianyu (Sky) Lu
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =============================================================================

# Set UPS target from first argument (default: ups@127.0.0.1)
UPS="${1:-ups@127.0.0.1}"
UPSC="$(which upsc 2>/dev/null || echo upsc)"

# Core OIDs
OIDS="
.1.3.6.1.2.1.33.1.1.1.0
.1.3.6.1.2.1.33.1.1.2.0
.1.3.6.1.2.1.33.1.1.3.0
.1.3.6.1.2.1.33.1.2.1.0
.1.3.6.1.2.1.33.1.2.3.0
.1.3.6.1.2.1.33.1.2.4.0
.1.3.6.1.2.1.33.1.2.5.0
.1.3.6.1.2.1.33.1.2.6.0
.1.3.6.1.2.1.33.1.3.3.1.3.1
.1.3.6.1.2.1.33.1.4.1.0
.1.3.6.1.2.1.33.1.4.4.1.2.1
.1.3.6.1.2.1.33.1.4.4.1.5.1
"

fetch() { UPSC_OUT="$($UPSC "$UPS" 2>/dev/null)"; }

get_nut() {
    keys="$1"
    IFS=','
    for k in $keys; do
        v=$(printf "%s\n" "$UPSC_OUT" | awk -F': ' -v key="$k" '$1==key{print substr($0,index($0,$2))}')
        [ -n "$v" ] && { printf "%s" "$v"; return 0; }
    done
    return 1
}

to_int() { printf "%d" "${1%.*}" 2>/dev/null || echo 0; }
sec_to_min() { printf "%d" "$((${1%.*}/60))" 2>/dev/null || echo 0; }
to_deci() { printf "%s" "$1" | awk '{printf "%d", $1 * 10}' 2>/dev/null || echo 0; }

emit_oid() {
    oid="$1"
    case "$oid" in
        .1.3.6.1.2.1.33.1.1.1.0)  # Manufacturer
            printf "%s\nstring\n%s\n" "$oid" "$(get_nut "device.mfr,ups.mfr" || echo "Unknown")";;
        .1.3.6.1.2.1.33.1.1.2.0)  # Model
            printf "%s\nstring\n%s\n" "$oid" "$(get_nut "device.model,ups.model" || echo "Unknown")";;
        .1.3.6.1.2.1.33.1.1.3.0)  # Firmware
            printf "%s\nstring\n%s\n" "$oid" "$(get_nut "ups.firmware" || echo "Unknown")";;
        .1.3.6.1.2.1.33.1.2.1.0)  # Battery Status (1=unknown, 2=normal, 3=low)
            s=$(get_nut "ups.status" || echo "OL")
            val=2; echo "$s" | grep -q "LB" && val=3
            printf "%s\ninteger\n%s\n" "$oid" "$val";;
        .1.3.6.1.2.1.33.1.2.3.0)  # Estimated Minutes Remaining, NUT Unit: seconds
            v=$(get_nut "battery.runtime"); [ -n "$v" ] && v=$(sec_to_min "$v") || v=0
            printf "%s\ninteger\n%s\n" "$oid" "$v";;
        .1.3.6.1.2.1.33.1.2.4.0)  # Battery charge %
            v=$(get_nut "battery.charge"); [ -n "$v" ] && v=$(to_int "$v") || v=100
            printf "%s\ninteger\n%s\n" "$oid" "$v";;
        .1.3.6.1.2.1.33.1.2.5.0)  # Battery Voltage (0.1 Volt DC), NUT Unit: V
            v=$(get_nut "battery.voltage"); [ -n "$v" ] && v=$(to_deci "$v") || v=0
            printf "%s\ninteger\n%s\n" "$oid" "$v";;
        .1.3.6.1.2.1.33.1.2.6.0)  # Battery Current (0.1 Amp DC), NUT Unit: A
            v=$(get_nut "battery.current"); [ -n "$v" ] && v=$(to_deci "$v") || v=0
            printf "%s\ninteger\n%s\n" "$oid" "$v";;
        .1.3.6.1.2.1.33.1.3.3.1.3.1)  # Input Voltage (RMS Volts), NUT Unit: V
            v=$(get_nut "input.voltage"); [ -n "$v" ] && v=$(to_int "$v") || v=0
            printf "%s\ninteger\n%s\n" "$oid" "$v";;
        .1.3.6.1.2.1.33.1.4.1.0)  # Output Source (3=normal, 5=battery)
            s=$(get_nut "ups.status" || echo "OL")
            val=3; echo "$s" | grep -q "OB" && val=5
            printf "%s\ninteger\n%s\n" "$oid" "$val";;
        .1.3.6.1.2.1.33.1.4.4.1.2.1)  # Output Voltage (RMS Volts), NUT Unit: V
            v=$(get_nut "output.voltage"); [ -n "$v" ] && v=$(to_int "$v") || v=0
            printf "%s\ninteger\n%s\n" "$oid" "$v";;
        .1.3.6.1.2.1.33.1.4.4.1.5.1)  # Load %
            v=$(get_nut "ups.load"); [ -n "$v" ] && v=$(to_int "$v") || v=0
            printf "%s\ninteger\n%s\n" "$oid" "$v";;
        *) return 1;;
    esac
}

next_oid() {
    req="$1"
    for o in $OIDS; do
        if [ "${o#.}" \> "${req#.}" ]; then echo "$o"; return 0; fi
    done
    return 1
}

# Main loop
fetch
while read -r line; do
    [ -z "$line" ] && exit 0
    case "$line" in
        PING) echo "PONG";;
        get) read -r oid; fetch; emit_oid "$oid" || echo "NONE";;
        getnext) read -r oid; fetch
                 n=$(next_oid "$oid")
                 [ -n "$n" ] && emit_oid "$n" || echo "NONE";;
        set) read -r _; read -r _; echo "not-writable";;
    esac
done
