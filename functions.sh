#!/sbin/sh
# Bash-Installer, a simple installer with multi-language support.
# Copyright (C) 2025 愛子あゆみ

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# functions:
function grep_prop() {
    [[ -z "$1" || -z "$2" || ! -f "$2" ]] && return 1
    grep -E "^$1=" "$2" | cut -d '=' -f2- | tr -d '"'
}

# usage: amiMountedOrNot /system
function amiMountedOrNot() {
    grep -q "$1" /proc/mounts
}

# just run the function xd
function unmountPartitions() {
    for partitions in system system_root vendor odm product prism optics; do
        amiMountedOrNot "${partitions}" && umount /${partitions}
    done
}

# usage: debugPrint "| Error-Info|Error|Warning|Abort|Failure | <service>: <message>"
function debugPrint() {
    # stderr/debug/log message in magisk.
    echo "$1" > /proc/self/fd/2
}

# usage: consolePrint "hello world"
# usage: consolePrint --language welcome.hello
# the recovery will ignore "" messages.
function consolePrint() {
    if [ "$1" == "--language" ]; then
        echo -e "ui_print $(grep_prop "$2" "/tmp/common.lang")\nui_print" > /proc/self/fd/$OUTFD
    else
        echo -e "ui_print $@\nui_print" > /proc/self/fd/$OUTFD
    fi
}

# same as consolePrint
function abortInstance() {
    if [ "$1" == "--language" ]; then
        echo -e "ui_print $(grep_prop "$2" "/tmp/common.lang")\nui_print" > /proc/self/fd/$OUTFD
    else
        echo -e "ui_print $@\nui_print" > /proc/self/fd/$OUTFD
    fi
    unmountPartitions
    rm -rf /dev/tmp/ /tmp/*
    exit 1
}

# usage examples:
# logInterpreter --ignore-failure "Trying to run a command.." "ls /sequoia"
# logInterpreter --handle-failure "Trying to run a command.." "ls /sequoia" "Fallback was triggered!" "ls /montana"
function logInterpreter() {
    local arg="$1"
    local message="$2"
    local command="$3"
    local FailedMessage="$4"
    local failureCommand="$5"
    case "$arg" in 
        "--ignore-failure")
            consolePrint "$message"
            eval "$command" &>/dev/tmp/test || debugPrint "Error-Info | logInterpreter(): Failed to run given command."
            cat /dev/tmp/test > /proc/self/fd/2
            ;;
        "--handle-failure")
            consolePrint "$message"
            if ! eval "$command" &>/dev/tmp/test; then
                debugPrint "Error-Info | logInterpreter(): Failed to run given command, running failure-based command..."
                cat /dev/tmp/test > /proc/self/fd/2
                eval "$failureCommand" && debugPrint "Info | logInterpreter(): Ran failure actions successfully | ${FailedMessage}" \
                || debugPrint "Error-Info | logInterpreter(): Failed to run given failure action."
            fi
        ;;
    esac
}

# Usage: findActualBlock <block name, ex: system>
function findActualBlock() {
    local blockname="$1"
    local block
    for commonDeviceBlocks in /dev/block/bootdevice/by-name /dev/block/by-name /dev/block/platform/*/by-name; do
        [ ! -f "${commonDeviceBlocks}/${blockname}" ] && continue
        [ -f "${commonDeviceBlocks}/${blockname}" ] && block=$(readlink -f "${commonDeviceBlocks}/${blockname}");
        [ -z "${block}" ] || echo "${block}"
    done
}

# Usage: installImages <image file name in the zip, ex: system.img> <block name, ex: system>
function installImages() {
    local imageName="$1"
    local blockname="$2"
    local imageType="$3"
    case "${imageType}" in
        "sparse")
            unzip -o "${ZIPFILE}" "${imageName}" -d $IMAGES
            consolePrint "Trying to install ${imageName} to ${blockname}..."
            simg2img "${IMAGES}/${blockname}.img" $(findActualBlock "${blockname}") || abort "Failed to install ${imageName} to ${blockname}!"
            consolePrint "Successfully installed ${blockname}!"
            rm -rf ${IMAGES}/
        ;;
        "raw")
            consolePrint "Trying to install ${imageName} to ${blockname}..."
            unzip -o "${ZIPFILE}" "${imageName}" -d ${blockname} || abort "Failed to install ${imageName}!"
            consolePrint "Successfully installed ${blockname}!"
        ;;
    esac
}

keytest() {
    consolePrint --language testing.vol.keys
    consolePrint --language press.volkey
    if (timeout 3 /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > /dev/tmp/events); then
        return 0
    else
        consolePrint --language try.again.volkey
        timeout 3 /dev/tmp/keycheck
        [ $? -eq 143 ] && abortInstance --language volkey.not.detected || return 1
    fi
}

chooseport() {
    while true; do
        /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > /dev/tmp/events
        (`cat /dev/tmp/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`) && break;
    done
    (`cat /dev/tmp/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`) && return 0 || return 1
}

chooseportold() {
    while true; do
        /dev/tmp/keycheck
        /dev/tmp/keycheck
        local SEL=$?
        if [ "$1" == "UP" ]; then
            UP=$SEL
            break
        elif [ "$1" == "DOWN" ]; then
            DOWN=$SEL
            break
        fi
        [ $SEL -eq $UP ] && return 0
        [ $SEL -eq $DOWN ] && return 1
    done
}

ask() {
    local languagevariable="$1"
    if grep -q "$languagevariable" /dev/tmp/common.eternal; then
        consolePrint "$(grep_prop "$languagevariable" /dev/tmp/common.eternal) (+ / -)"
    else
        consolePrint "$languagevariable (+ / -)"
    fi
    if [ -f /dev/tmp/old ]; then
        chooseportold
    elif [ -f /dev/tmp/new ]; then
        chooseport
    else
        return 1
    fi
}
# functions: