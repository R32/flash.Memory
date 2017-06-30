package raw;


class Ut {
	// p must be pow of 2, (0, 8 => 8), (15, 8 => 16), (8, 8 => 8), (16, 8 => 16), (1010, 8 => 1016)
	static public function align(n, p) {
		//var i = p - (n % p);
		//return i == p && n > 0 ? n : n + i;
		var x = p - (n & (p - 1));
		return x == p && n > 0 ? n : n + x;
	}

	// (2) => 2, (3) => 4, (33) => 64;
	static public function nextPow(x) {
		var ret = 2;
		while (ret < x) ret <<= 1;
		return ret;
	}

	// start <= (value) < max
	static public inline function rand(max: Int, start = 0)
		return Std.int(Math.random() * (max - start)) + start;

	#if !(js || neko || macro)  @:generic #end
	public static function shuffle<T>(a: Array<T>, count = 1, start = 0) {
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

	static public inline function divisible(x, by) return (x & (by - 1)) == 0;

	static public inline function isPowOf2(x) return divisible(x, x);

	static public inline function imax(a: Int, b: Int) return a < b ? b : a;

	static public inline function imin(a: Int, b: Int) return a > b ? b : a;
}