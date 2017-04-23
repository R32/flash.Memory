package mem.obs;

import mem.Ptr;
import mem.struct.AString;

class Hex{

	static var hexchar(default, null): AString = cast Ptr.NUL;

	public static function init() {
		_init();
	}

	inline static function _init() {
		if (hexchar == Ptr.NUL)
			hexchar = AString.fromString("0123456789ABCDEF");
	}

	public static function export(ptr:Ptr, len:Int):AString {
		_init();
		var sa = AString.alloc(len + len);
		var u16:AU16 = cast sa;
		var hex:AU8 = cast hexchar;
		var c:Int;
		for (i in 0...len) {
			c = ptr[i];
			u16[i] = hex[c & 15] << 8 | hex[(c >> 4) & 15];
		}
		return sa;
	}

	public static function trace(ptr: Ptr, len: Int, lower = true, prefix = ""): Void {
		_init();
		var sa = export(ptr, len);
		if (lower)
			trace(prefix + sa.toString().toLowerCase());
		else
			trace(prefix + sa.toString());
		sa.free();
	}
}
