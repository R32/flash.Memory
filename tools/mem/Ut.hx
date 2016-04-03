package mem;

import mem.Ptr;

class Ut{
	/**
	0x4321 => 4,  (n <= 0xFF) - 2
	*/
	static public function hexWidth(n:Int):Int{
		var i = 0;
		while (n >= 1) {
			n = n >> 4;
			i += 1;
		}
		if ((i & 1) == 1) i += 1;
		if (i < 2) i = 2;
		return i;
	}

	static public function pad8(n, p){
		var i = p - (n % p);
		return i == p && n > 0 ? n : n + i;
	}

	// [a,b,c,d] = [d,c,b,a] in bytes
	static public function reverse(ptr:Ptr, len:Int):Void{
		var right = ptr + len - 1;
		var cc:Int;
		while(ptr < right){
			cc = Memory.getByte(ptr);
			Memory.setByte(ptr++, Memory.getByte(right));
			Memory.setByte(right--, cc);
		}
	}
}