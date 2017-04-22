#!/bin/sh
#
rm -rf release
mkdir -p release
cp -R -u tools haxelib.json release
chmod -R 777 release
cd release
zip -r release.zip ./ -x 'tools/Stats.hx' 'tools/mem/obs/Lz4.hx' 'tools/mem/obs/_macros/Lz4Macros.hx' ''
cd ..

## zip -x 最后得有空格，否则最后一个匹配会被忽略
