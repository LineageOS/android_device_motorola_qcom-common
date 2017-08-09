#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

# XXXX These are defined by the upstream wrapper.
#      DO NOT RUN THIS SCRIPT DIRECTLY
# DEVICE=**** FILL IN DEVICE NAME ****
# VENDOR=*** FILL IN VENDOR ****

if [ -z "${DEVICE}" ]; then
    echo "DEVICE undefined, exiting"
    exit 1
fi

if [ -z "${VENDOR}" ]; then
    echo "VENDOR undefined, exiting"
    exit 1
fi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

CM_ROOT="$MY_DIR"/../../..

HELPER="$CM_ROOT"/vendor/cm/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

# default to not sanitizing the vendor folder before extraction
clean_vendor=false

while [ "$1" != "" ]; do
    case $1 in
        -p | --path )           shift
                                SRC=$1
                                ;;
        -s | --section )        shift
                                SECTION=$1
                                clean_vendor=false
                                ;;
        -c | --clean-vendor )   clean_vendor=true
                                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
    SRC=adb
fi

# Check if there is a common device tree for this device
if [ ! -z $COMMON_DEVICE ]; then
    # Initialize the helper for common device
    setup_vendor "$COMMON_DEVICE" "$VENDOR" "$CM_ROOT" true $clean_vendor
    # Extract the files common to all devices using this common device tree
    extract ../../$VENDOR/$COMMON_DEVICE/common-proprietary-files.txt "$SRC" "$SECTION"
fi

# Check if there is a family device tree for this device
if [ ! -z $FAMILY_DEVICE ]; then
    # Initialize the helper for family
    setup_vendor "$FAMILY_DEVICE" "$VENDOR" "$CM_ROOT" true $clean_vendor
    # Extract the files common to all devices using this common device tree
    extract ../../$VENDOR/$FAMILY_DEVICE/common-proprietary-files.txt "$SRC" "$SECTION"
fi

# Check if there are files common to all devices but device specific
if [ ! -z $COMMON_DEVICE -a -f ../../$VENDOR/$COMMON_DEVICE/proprietary-files.txt ]
then
    # Initialize the helper for device
    setup_vendor "$DEVICE" "$VENDOR" "$CM_ROOT" false $clean_vendor
    extract ../../$VENDOR/$COMMON_DEVICE/proprietary-files.txt "$SRC" "$SECTION"
    clean_vendor=false
fi

# Check if there are files common to all devices but family specific
if [ ! -z $FAMILY_DEVICE -a -f ../../$VENDOR/$FAMILY_DEVICE/proprietary-files.txt ]
then
    # (Re)initialize the helper for device
    setup_vendor "$DEVICE" "$VENDOR" "$CM_ROOT" false $clean_vendor
    extract ../../$VENDOR/$FAMILY_DEVICE/proprietary-files.txt "$SRC" "$SECTION"
    clean_vendor=false
fi

# (Re)initialize the helper for device
setup_vendor "$DEVICE" "$VENDOR" "$CM_ROOT" false $clean_vendor
# Extract the device specific files
extract ../../$VENDOR/$DEVICE/device-proprietary-files.txt "$SRC" "$SECTION"

"$MY_DIR"/setup-makefiles.sh
