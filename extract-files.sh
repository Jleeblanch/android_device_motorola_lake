#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
#           (C) 2017 The LineageOS Project
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

set -e
export DEVICE=lake
export VENDOR=motorola

# Load extractutils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

TWRP_ROOT="$MY_DIR"/../../..

HELPER="$TWRP_ROOT"/vendor/omni/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

while [ "$1" != "" ]; do
    case $1 in
        -n | --no-cleanup )     CLEAN_VENDOR=false
                                ;;
        -s | --section )        shift
                                SECTION=$1
                                clean_vendor=false
                                ;;
        * )                     SRC=$1
                                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
  SRC=adb
fi

# Initialize the helper
setup_vendor "$DEVICE" "$VENDOR" "$TWRP_ROOT" false "$CLEAN_VENDOR"

extract "$MY_DIR"/proprietary-files-twrp.txt "$SRC" "$SECTION"

BLOB_ROOT="$TWRP_ROOT"/vendor/"${VENDOR}"/"${DEVICE}"/proprietary

RELINK_QSEE="$BLOB_ROOT"/sbin/qseecomd
sed -i "s|/system/bin/linker64|///////sbin/linker64|g" "$RELINK_QSEE"

RELINK_BOOT="$BLOB_ROOT"/sbin/android.hardware.boot@1.0-service
sed -i "s|/system/bin/linker64|///////sbin/linker64|g" "$RELINK_BOOT"

RELINK_GK="$BLOB_ROOT"/sbin/android.hardware.gatekeeper@1.0-service-qti
sed -i "s|/system/bin/linker64|///////sbin/linker64|g" "$RELINK_GK"

RELINK_KM="$BLOB_ROOT"/sbin/android.hardware.keymaster@4.0-service-qti
sed -i "s|/system/bin/linker64|///////sbin/linker64|g" "$RELINK_KM"

# Copy from vendor to device tree
DEVICE_ROOT="${PWD}"/recovery/root
cp -aR "$BLOB_ROOT"/* "$DEVICE_ROOT"

# Lastly, remove vendor folder
rm -rf "$TWRP_ROOT"/vendor/"${VENDOR}"
