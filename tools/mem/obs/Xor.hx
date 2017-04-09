package mem.obs;

import mem.Ptr;
import mem.struct.AString;

class Xor{

	public var sa(default, null):AString;

	inline public function new(a:AString) sa = a;

	inline public function free():Void sa.free();

	public function run(src:Ptr, size:Int, dst:Ptr): Void{
		if (dst == -1)
			dst = src;
		else if (dst > src && dst < src + size)
			throw "It will be overwritten";
		var len = this.sa.length;
		var tpr:Int = this.sa.addr;
		var offset = 0;
	#if (flash || cpp)
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
		return new Xor(AStrImpl.fromHexString(hex));
	}

	public inline static function fromString(str:String):Xor{
		return new Xor(AStrImpl.fromString(str));
	}
}