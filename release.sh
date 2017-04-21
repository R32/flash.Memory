#!/bin/sh
#
rm -rf release
mkdir -p release
cp -R -u tools haxelib.json release
chmod -R 777 release
cd release
zip -r release.zip ./ -x 'tools/Stats.hx' '***Lz4***'
cd ..