#!/bin/bash
# @@@LICENSE
#
#      Copyright (c) 2012 Hewlett-Packard Development Company, L.P.
#
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
#
# LICENSE@@@

set -x

export WORKDIR=`pwd`
export BASE="${WORKDIR}/luna-desktop-binaries"
ROOTFS="${BASE}/rootfs"
LUNA_STAGING="${BASE}/staging"

STAGING_DIR="${LUNA_STAGING}"
BIN_DIR="${STAGING_DIR}/bin"
LIB_DIR="${STAGING_DIR}/lib"
USRLIB_DIR="${STAGING_DIR}/usr/lib"
BIN_DIR_QT5="${STAGING_DIR}/qt5/bin"
LIB_DIR_QT5="${STAGING_DIR}/qt5/lib"
ETC_DIR="${STAGING_DIR}/etc"
REDIRECT=""

function terminateBrowserServer {
    killall -q BrowserServer
}

if [ "$1" = "--help" ] ; then
    echo "Usage: ./run-luna-sysmgr.sh [OPTION]"
    echo "Runs the luna-sysmgr component."
    echo " "
    echo "Optional arguments:"
    echo "    --help  display this help and exit"
    echo "    -q      redirect console output to /tmp/webos/LunaSysMgr.log"
    echo " "
    exit
elif [ "$1" = "--version" ] ; then
    echo "Desktop run script for Open webOS #7"
    exit
elif [ "$1" = "-q" ] ; then
    REDIRECT="-q"
elif [ -n "$1" ] ; then
    echo "Parameter $1 not recognized"
    exit
elif [ ! -d ${STAGING_DIR} ]  || [ ! -x ${ROOTFS}/usr/lib/luna/LunaSysMgr ]; then
    echo "First build luna-sysmgr"
    exit
fi

DEB_BUILD_MULTIARCH=$(dpkg-architecture -qDEB_BUILD_MULTIARCH)
export LD_PRELOAD=/lib/${DEB_BUILD_MULTIARCH}/libSegFault.so
export LD_LIBRARY_PATH=${LIB_DIR_QT5}:${LIB_DIR}:${USRLIB_DIR}:${LD_LIBRARY_PATH}
export PATH=${BIN_DIR_QT5}:${BIN_DIR}:${PATH}
# Make Qt aware of this path (the qbsplugin is here)
export QT_PLUGIN_PATH=${LUNA_STAGING}/plugins

# To catch the CTRL-C
trap terminateBrowserServer SIGINT

if [ -d /etc/palm ] && [ -h /etc/palm ] ; then

    mkdir -p /tmp/webos
    echo "Starting BrowserServer ..."
    # Start the browser server
    ${BIN_DIR}/BrowserServer > /tmp/webos/BrowserServer.log &

    echo "Starting LunaSysMgr ..."
    export QT_QPA_PLATFORM=xcb
    cd ${ROOTFS}
    if [ -n "${REDIRECT}" ] ; then
        ./usr/lib/luna/LunaSysMgr > /tmp/webos/LunaSysMgr.log &
    else
        ./usr/lib/luna/LunaSysMgr &
    fi
    sleep 2
    if [ -n "${REDIRECT}" ] ; then
        ./usr/lib/luna/WebAppMgr > /tmp/webos/WebappMgr.log

    else
        ./usr/lib/luna/WebAppMgr
fi
else
    echo "First run the install script:  sudo ./install-luna-sysmgr.sh"
fi

terminateBrowserServer
