package mem;

#if cpp
typedef RawData = cpp.Star<mem.cpp.BytesData>;
#elseif flash
typedef RawData = flash.utils.ByteArray;
#elseif hl
typedef RawData = hl.Bytes;
#else
typedef RawData = haxe.io.Bytes;
#end
