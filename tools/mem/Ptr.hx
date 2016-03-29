package mem;

typedef Ptr = Int;

#if flash
typedef Memory = flash.Memory;
typedef ByteArray = flash.utils.ByteArray;
#else
//typedef Memory = Dynamic;
#end