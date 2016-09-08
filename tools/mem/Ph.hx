package mem;

import mem.Ptr;

/**
PtrHelper
*/
class Ph{
	// [a,b,c,d] = [d,c,b,a] in bytes
	static public function reverse(ptr:Ptr, len:Int):Void {
		var right = ptr + len - 1;
		var cc:Int;
		while(ptr < right){
			cc = Memory.getByte(ptr);
			Memory.setByte(ptr++, Memory.getByte(right));
			Memory.setByte(right--, cc);
		}
	}

	static public function crc32(ptr:Ptr, len:Int):Int {
		var init = 0xFFFFFFFF;
		var crc = init;
		for (i in 0...len) {
			var tmp = (crc ^ Memory.getByte(ptr + i)) & 0xFF;
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
}