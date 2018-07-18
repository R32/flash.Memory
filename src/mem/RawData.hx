package mem;

#if hl
typedef RawData = hl.Bytes;
#elseif flash
typedef RawData = flash.utils.ByteArray;
#else
typedef RawData = haxe.io.Bytes;
#end