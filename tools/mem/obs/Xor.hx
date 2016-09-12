package mem.obs;

import mem.Ptr;
import mem.struct.AString;

class Xor{

	public var astr(default, null):AString;

	inline public function new(a:AString) astr = a;

	inline public function free():Void astr.free();

	inline public function make(src:Ptr, size:Int, dst:Ptr = -1 ):Void run(this, src, size, dst);

	static function run(x:Xor, src:Ptr, size:Int, dst:Ptr):Void{
		if (dst == -1)
			dst = src;
		else if (dst > src && dst < src + size)
			throw "It will be overwritten";

		var len = x.astr.length;
		var tpr:Int = x.astr.c_ptr;
		var offset = 0;
	#if (flash || (cpp && !keep_bytes))
		var b4 = size - (size % 4);
		while (b4 > offset){
			Memory.setI32(dst + offset, Memory.getI32(src + offset) ^ Memory.getI32(tpr + (offset % len) ));
			offset += 4;
		}
	#end
		while (size > offset){
			Memory.setByte(dst + offset, Memory.getByte(src + offset) ^ Memory.getByte(tpr + (offset % len) ));
			offset += 1;
		}
	}

	public inline static function fromHexString(hex:String):Xor{
		return new Xor(AString.fromHexString(hex));
	}

	public inline static function fromString(str:String):Xor{
		return new Xor(AString.fromString(str));
	}
}