package mem;

/**
* Utils
*/
class Ut {
	// p must be pow of 2, (0, 8) => 8, (15, 8) => 16, (8, 8) => 8, (1010, 8) => 1016
	static public function align(n, p) {
		var x = p - (n & (p - 1));
		return x == p && n > 0 ? n : n + x;
	}

	// (2) => 2, (3) => 4, (33) => 64;
	static public function nextPow(x) {
		var ret = 2;
		while (ret < x) ret <<= 1;
		return ret;
	}

	static public inline function isPowOf2(x) return ((x & x - 1) == 0) && (x > 1);
	static public inline function imax(a: Int, b: Int) return a < b ? b : a;
	static public inline function imin(a: Int, b: Int) return a > b ? b : a;
}