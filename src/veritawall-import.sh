#!/bin/sh
#-
# Copyright (c) 2021 Nitish Patel <nitish.patel@veritawall.com>
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

. /usr/libexec/bsdinstall/veritawall.subr || exit 1

veritawall_load_disks

[ -z "${VERITAWALL_SDISKS}${VERITAWALL_SPOOLS}" ] && veritawall_fatal "Import Configuration" "No suitable disks found in the system"

exec 3>&1
DISK=`echo ${VERITAWALL_SDISKS} ${VERITAWALL_SPOOLS} | xargs dialog --backtitle "Veritawall Installer" \
	--title "Import Configuration" --cancel-label "Cancel" \
	--menu "Please select a disk to continue." \
	0 0 0 2>&1 1>&3` || exit 1
exec 3>&-

[ -z "${DISK}" ] && veritawall_fatal "Import Configuration" "No valid disk was selected"

if ${VERITAWALL_IMPORTER} ${DISK} 2>&1; then
	veritawall_info "Import Configuration" "Configuration import completed"
else
	veritawall_fatal "Import Configuration" "Configuration import failed"
fi
