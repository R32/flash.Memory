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

	static public inline function rand(max:Int, start:Int = 0):Int return Std.int(Math.random() * (max - start)) + start;

	public static function shuffle<T>(a : Array<T>,count:Int = 1, start:Int = 0) : Void{
		var len = a.length;
		var r:Int, t:T;
		for (j in 0...count) {
			for (i in start...len) {
				r = rand(len, start);	// 0 ~ (len -1 )
				t = a[r];
				a[r] = a[i];
				a[i] = t;
			}
		}
	}

	// xor for for macro build
	public static function xxx(dst:haxe.io.Bytes, key:haxe.io.Bytes):Void{
		var len = dst.length;
		var kl = key.length;
		var pos = 0;
		while(len >0){
			dst.set(pos, dst.get(pos) ^ key.get(pos % kl));
			len --;
			pos ++;
		}
	}
}