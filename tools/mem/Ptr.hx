package mem;

typedef Ptr = Int;

#if flash
typedef Memory = flash.Memory;
typedef ByteArray = flash.utils.ByteArray;
typedef IDataInput = flash.utils.IDataInput;
typedef IDataOutput = flash.utils.IDataOutput;
#else
//typedef Memory = Dynamic;
#end