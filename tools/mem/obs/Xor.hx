package mem.obs;

import mem.Ptr;
import mem.struct.AString;

class Xor{

	public var astr(default, null):AString;

	inline public function new(str:String) astr = AString.fromString(str);

	inline public function free():Void astr.free();

	inline public function make(dst:Ptr, size:Int, out:Ptr = 0 ):Void run(this, dst, size, out);

	static function run(x:Xor, dst:Ptr, size:Int, out:Ptr):Void{
		if (out == 0) out = dst;
		var len = x.astr.length;
		var tpr:Int = x.astr.c_ptr;
		var offset = 0;
	#if flash
		var b4 = size - (size % 4);
		while (b4 > offset){
			Memory.setI32(out + offset, Memory.getI32(dst + offset) ^ Memory.getI32(tpr + (offset % len) ));
			offset += 4;
		}
	#end
		while (size > offset){
			Memory.setByte(out + offset, Memory.getByte(dst + offset) ^ Memory.getByte(tpr + (offset % len) ));
			offset += 1;
		}
	}
}