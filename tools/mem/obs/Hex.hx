package mem.obs;

import mem.Ptr;
import mem.Malloc;
import mem.struct.AString;

class Hex{

	public static var hexchar(default, null):AString;

	public static function init(){
		hexchar = AString.fromString("0123456789ABCDEF");
	}

	static function free() hexchar.free();

	public static function export(ptr:Ptr, len:Int):AString{
		if (hexchar == null)
			throw "have not initialization the hexchar";
		var ret = new AString(len + len);
		var dst = ret.c_ptr;
		var base = hexchar.c_ptr;
		var c:Int;
		for(i in 0...len){
			c = Memory.getByte(ptr + i);
			Memory.setI16(dst + i + i, (Memory.getByte(((c&15) + base)) << 8) |
				Memory.getByte(((c >>> 4) & 15) + base));
		}
		return ret;
	}
}