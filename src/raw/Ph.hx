package raw;

import raw.Ptr;

class Ph {

	static public function reverse(ptr:Ptr, len:Int):Void {
		var left = ptr;
		var right = left + len - 1;
		var c:Int;
		while (left < right) {
			c = Memory.getByte(left);
			Memory.setByte(left, Memory.getByte(right));
			Memory.setByte(right, c);
		++left;
		--right;
		}
	}

	// s = "abcdef"; leftRotateMove(s, s.length, 2) => "cdefab"
	static public function leftRotateMove(ptr:Ptr, len:Int, w:Int):Void {
		w %= len;
		reverse(ptr, len);
		reverse(ptr, len - w);
		reverse(ptr + len - w, w);
	}

	static public function crc32(ptr:Ptr, len:Int):Int {
		var init = 0xFFFFFFFF;
		var crc = init;
		for (i in 0...len) {
			var tmp = (crc ^ ptr[i]) & 0xFF;
			for (j in 0...8) {
				if (tmp & 1 == 1)
					tmp = (tmp >>> 1) ^ 0xEDB88320;
				else
					tmp >>>= 1;
			}
			crc = (crc >>> 8) ^ tmp;
		}
		return crc ^ init;
	}

	static public function adler32(ptr:Ptr, len:Int):Int {
		var a = 1, b = 0, i = 0;
		while (i < len) {
			a = (a + ptr[i]) % 65521;
			b = (b + a) % 65521;
		++i;
		}
		return (b << 16) | a;
	}

	// fast sort
	public static function sortU8(left: Int, right: Int, a: AU8): Void {
		Macros.qsort(sortU8);
	}

	public static function sortI32(left: Int, right: Int, a: AI32): Void {
		Macros.qsort(sortI32);
	}
}