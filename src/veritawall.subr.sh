#!/bin/sh
#-
# Copyright (c) 2019-2021 Nitish Patel <nitish.patel@veritawall.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

SIZE_BOOT=$((512 * 1024))
SIZE_EFI=$((260 * 1024 * 1024))
SIZE_MIN=$((4 * 1024 * 1024 * 1024))
SIZE_SWAP=$((8 * 1024 * 1024 * 1024))
SIZE_SWAPMIN=$((30 * 1024 * 1024 * 1024))

VERITAWALL_IMPORTER="/usr/local/sbin/veritawall-importer"

veritawall_load_disks()
{
	VERITAWALL_SDISKS=
	VERITAWALL_DISKS=

	for DEVICE in $(find /dev -d 1 \! -type d); do
		DEVICE=${DEVICE##/dev/}

		if [ -z "$(echo ${DEVICE} | grep -ix "[a-z][a-z]*[0-9][0-9]*")" ]; then
			continue
		fi

		if [ -n "$(echo ${DEVICE} | grep -i "^tty")" ]; then
			continue
		fi

		if diskinfo ${DEVICE} > /tmp/diskinfo.tmp 2> /dev/null; then
			SIZE=$(cat /tmp/diskinfo.tmp | awk '{ print $3 }')
			eval export ${DEVICE}_size='${SIZE}'

			NAME=$(dmesg | grep "^${DEVICE}:" | head -n 1 | cut -d ' ' -f2- | tr -d '<' | cut -d '>' -f1 | tr -cd "[:alnum:][:space:]")
			eval export ${DEVICE}_name='${NAME:-Unknown disk}'

			VERITAWALL_DISKS="${VERITAWALL_DISKS} ${DEVICE}"
		fi
	done

	for DISK in ${VERITAWALL_DISKS}; do
		eval SIZE="\$${DISK}_size"
		eval NAME="\$${DISK}_name"
		VERITAWALL_SDISKS="${VERITAWALL_SDISKS}\"${DISK}\" \"<${NAME}> ($((SIZE / 1024 /1024 / 1024))GB)\"
"
	done

	export VERITAWALL_SDISKS # disk menu
	export VERITAWALL_DISKS # raw disks

	VERITAWALL_SPOOLS=
	VERITAWALL_POOLS=

	ZFSPOOLS=$(${VERITAWALL_IMPORTER} -z | tr ' ' ',')

	for ZFSPOOL in ${ZFSPOOLS}; do
		ZFSNAME=$(echo ${ZFSPOOL} | awk -F, '{ print $1 }')
		ZFSGUID=$(echo ${ZFSPOOL} | awk -F, '{ print $2 }')
		ZFSSIZE=$(echo ${ZFSPOOL} | awk -F, '{ print $3 }')
		VERITAWALL_POOLS="${VERITAWALL_POOLS} ${ZFSNAME}"
		VERITAWALL_SPOOLS="${VERITAWALL_SPOOLS}\"${ZFSNAME}\" \"<${ZFSGUID}> (${ZFSSIZE})\"
"
	done

	export VERITAWALL_SPOOLS # zfs pool menu
	export VERITAWALL_POOLS # raw zfs pools
}

veritawall_info()
{
	dialog --backtitle "Veritawall Installer" --title "${1}" \
	    --msgbox "${2}" 0 0
}

veritawall_fatal()
{
	dialog --backtitle "Veritawall Installer" --title "${1}" \
	    --ok-label "Cancel" --msgbox "${2}" 0 0
	exit 1
}
