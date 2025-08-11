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

# zipfile path from the argument:
export ZIPFILE="$1"
export OUTFD="$2"

# import the dawn functions from the file, pretty clever decision tho ngl im proud of myself.
command -v source && source /dev/tmp/functions.sh || . /dev/tmp/functions.sh

# print banner
consolePrint "╔─────────────────────────────────────────────────────╗"
consolePrint "│████████╗███████╗██╗   ██╗██╗  ██╗██╗██╗  ██╗ █████╗ │"
consolePrint "│╚══██╔══╝██╔════╝██║   ██║██║ ██╔╝██║██║ ██╔╝██╔══██╗│"
consolePrint "│   ██║   ███████╗██║   ██║█████╔╝ ██║█████╔╝ ███████║│"
consolePrint "│   ██║   ╚════██║██║   ██║██╔═██╗ ██║██╔═██╗ ██╔══██║│"
consolePrint "│   ██║   ███████║╚██████╔╝██║  ██╗██║██║  ██╗██║  ██║│"
consolePrint "│   ╚═╝   ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝│"
consolePrint "╚─────────────────────────────────────────────────────╝"
consolePrint --language welcome.to.tsukika
if /dev/tmp/keycheck; then 
    touch /dev/tmp/new
else
    touch /dev/tmp/old
    consolePrint --language testing.vol.keys
    consolePrint --language press.volplus
    chooseportold "UP"
    consolePrint --language press.volminus
    chooseportold "DOWN"
fi