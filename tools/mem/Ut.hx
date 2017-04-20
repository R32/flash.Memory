package mem;

@:allow(mem) class Ut{
	/**
	0x4321 => 4,  (n <= 0xFF) - 2
	*/
	static public function hexWidth(n:Int):Int {
		var i = 0;
		while (n >= 1) {
			n = n >> 4;
			i += 1;
		}
		if ((i & 1) == 1) i += 1;
		if (i < 2) i = 2;
		return i;
	}
	// (0, 8 => 8), (15, 8 => 16), (8, 8 => 8), (16, 8 => 16), (1010, 8 => 1016)
	static public function padmul(n, p) {
		var i = p - (n % p);
		return i == p && n > 0 ? n : n + i;
	}

	// (7 => 16-7), (17 => 32-17), (16 => 16), (0 => 16), for AES padding
	static public function pad16(size) {
		return 16 - (size & (16 - 1));
	}

	// Note: "by" must be pow of 2
	static inline function divisible(x, by) return (x & (by - 1)) == 0;

	static public inline function isPowOf2(x) return divisible(x, x);

	// (2) => 2, (3) => 4, (33) => 64;
	static public function nextPow(x) {
		var ret = 2;
		while (ret < x) ret <<= 1;
		return ret;
	}

	static public function toFixed(f: Float, n: Int): String {
	#if (js || flash)
		return untyped (f).toFixed(n);
	#else
		var p10 = Math.pow(10, n);
		return "" + Std.int(f * p10) / p10;
	#end
	}

	// start <= (value) < max
	static public inline function rand(max:Int, start:Int = 0):Int
		return Std.int(Math.random() * (max - start)) + start;

	#if (!macro && (sys || flash)) @:generic #end
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

	public static inline function isspace(c: Int): Bool {
		return c == " ".code || c == "\t".code || c == "\n".code || c == "\r".code
			|| c == 0x0b || c == 0x0c;  // 0x0b = \v, 0x0c = \f
	}

	// xor for for macro build
	public static function xxx(dst:haxe.io.Bytes, key:haxe.io.Bytes):Void{
		var len = dst.length;
		var kl = key.length;
		var pos = 0;
		while(len > 0){
			dst.set(pos, dst.get(pos) ^ key.get(pos % kl));
			len --;
			pos ++;
		}
	}
}