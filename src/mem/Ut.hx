package mem;

/**
* Utils
*/
class Ut {
	// _BitScanForward
	static public function TRAILING_ONES(x) {
		if (x == 0xFFFFFFFF) return 32;
		var n = 0;
		if ((x & 0xFFFF) == 0xFFFF) {
			n += 16;
			x >>= 16;
		}
		if ((x & 0xFF) == 0xFF) {
			n += 8;
			x >>= 8;
		}
		if ((x & 0xF) == 0xF) {
			n += 4;
			x >>= 4;
		}
		if ((x & 3) == 3) {
			n += 2;
			x >>= 2;
		}
		if ((x & 1) == 1) {
			n += 1;
		}
		return n;
	}
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
