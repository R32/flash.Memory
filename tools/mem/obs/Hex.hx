package mem.obs;

import mem.Ptr;
import mem.Malloc.NUL;
import mem.struct.AString;

class Hex{

	public static var hexchar(default, null): AString;

	public static function init() {
		if (hexchar == NUL)
			hexchar = AStrImpl.fromString("0123456789ABCDEF");
	}

	static function free() hexchar.free();

	public static function export(ptr:Ptr, len:Int):AString {
		if (hexchar == NUL)
			throw "TODO";
		var ret = AStrImpl.alloc(len + len);
		var dst = ret.addr;
		var base = hexchar.addr;
		var c:Int;
		for(i in 0...len){
			c = Memory.getByte(ptr + i);
			Memory.setI16(dst + i + i, (Memory.getByte(((c&15) + base)) << 8) |
				Memory.getByte(((c >>> 4) & 15) + base));
		}
		return ret;
	}

	public static function trace(ptr: Ptr, len: Int, lower = true, prefix = ""): Void {
		var as = export(ptr, len);
		if (lower)
			trace(prefix + as.toString().toLowerCase());
		else
			trace(prefix + as.toString());
		as.free();
	}
}