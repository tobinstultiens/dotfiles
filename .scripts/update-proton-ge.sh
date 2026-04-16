#!/bin/bash
set -euo pipefail

# make temp working directory
rm -r /tmp/proton-ge-custom || true
mkdir /tmp/proton-ge-custom
cd /tmp/proton-ge-custom

# download  tarball
curl -sLOJ "$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep browser_download_url | cut -d\" -f4 | grep .tar.gz)"

echo "Downloading latest proton-GE"
# download checksum
curl -sLOJ "$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep browser_download_url | cut -d\" -f4 | grep .sha512sum)"

echo "Checking tarball checksum"
# check tarball with checksum
sha512sum -c ./*.sha512sum
# if result is ok, continue

# make steam directory if it does not exist
mkdir -p ~/.steam/root/compatibilitytools.d

fpath=`find /tmp/proton-ge-custom -type f -name "GE-Proton*.tar.gz" -exec basename {} \;`
for fnd in $fpath
do
    protonMajorVersion=`echo $fpath | cut -d - -f 1-2`
done

fpath=`find ~/.steam/root/compatibilitytools.d/ -type d -name "$protonMajorVersion*"`
for fnd in $fpath
do
    rm -rf $fnd
done


# extract proton tarball to steam directory
tar -xf GE-Proton*.tar.gz -C ~/.steam/root/compatibilitytools.d/
echo "All done :)"
