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
	static public inline function divisible(x, by) return (x & (by - 1)) == 0;

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

	// 0x0F => "00001111"
	static public function toBits(n: Int): String {
		var ret = haxe.io.Bytes.alloc(32);
		ret.fill(0, 32, "0".code);
		var i = 0;
		do {
			++ i;
			if ((n & 1) == 1) ret.set(32 - i, "1".code);
			n >>>= 1;
		} while (n > 0 && i < 32);
		var p8 = i & (8 - 1);
		if (p8 > 0) i += 8 - p8;
		return ret.getString(32 - i, i);
	}

	// start <= (value) < max
	static public inline function rand(max:Int, start:Int = 0):Int
		return Std.int(Math.random() * (max - start)) + start;

	#if !js @:generic #end
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

	public static function hex2bytes(s: String): haxe.io.Bytes {
		var len = s.length >> 1;
		var ret = haxe.io.Bytes.alloc(len);
		var j = 0;

		for (i in 0...len) {
			j = i + i;
			ret.set(i, Std.parseInt("0x" + s.charAt(j) + s.charAt(j + 1)));
		}
		return ret;
	}

	// used to prevent overwrite
	public static inline function inZone(a: Int, b: Int, len: Int): Bool {
		return (a < b && a + len > b) || (b < a && b + len > a); // || (a == b);
	}

	public static inline function signExtend16(value: Int): Int {
	#if flash
		return mem.impl.FlashMemory.signExtend16(value);
	#else
		return value & 0x8000 == 0x8000 ? value | 0xffff0000: value;
	#end
	}

	public static inline function signExtend8(value: Int): Int {
	#if flash
		return mem.impl.FlashMemory.signExtend8(value);
	#else
		return value & 0x80 == 0x80 ? value | 0xffffff00: value;
	#end
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