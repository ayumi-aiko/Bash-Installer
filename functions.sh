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

function registerKeys() {
    local UP DOWN SEL
    while true; do
        # Calling keycheck first time detects previous input. Calling it second time will do what we want
        /dev/tmp/keycheck
        /dev/tmp/keycheck
        local SEL=$?
        if [ "$1" == "UP" ]; then
            UP=$SEL
            echo "$UP" > /tmp/volActionUp
            break
        elif [ "$1" == "DOWN" ]; then
            DOWN=$SEL
            echo "$DOWN" > /tmp/volActionDown
            break
        elif [ $SEL -eq $UP ]; then
            return 1
        elif [ $SEL -eq $DOWN ]; then
            return 0
        fi
    done
}

function whichVolumeKey() {
    local SEL
    /dev/tmp/keycheck
    SEL="$?"
    if [ "$(cat "/tmp/volActionUp")" == "${SEL}" ]; then
        return 0
    elif [ "$(cat "/tmp/volActionDown")" == "${SEL}" ]; then
        return 1
    else
        debugPrint "Error | whichVolumeKey(): Unknown key register, here's the return value: ${SEL}"
        return 1
    fi
}

function ask() {
    local languagevariable="$1"
    grep -q "$languagevariable" /dev/tmp/common.eternal && consolePrint "$(grep_prop "$languagevariable" /dev/tmp/common.eternal) (+ / -)" || consolePrint "$languagevariable (+ / -)"
    whichVolumeKey
}

function setupBB() {
    unzip -o "${ZIPFILE}" "bin/arm/busybox" -d "/dev/tmp"
    mv "/dev/tmp/bin/arm/busybox" "/dev/tmp/busybox"
    chmod -R 0755 "/dev/tmp/"
    rm -rf "/dev/tmp/bin"
    [ ! -f "/dev/tmp/busybox" ] && abortInstance --language bb.setup.failed
}

function busybox() {
    /dev/tmp/busybox "$@"
}
# functions: