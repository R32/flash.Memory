package mem.obs._macros;


class Sha256Macros {

	public static inline var SHA256_HASH_SIZE:Int = 256 >> 3;
	public static inline var BLOCK_SIZE:Int = 64;

	//// macros ////

	macro public static function ror(value, bits) return macro (($value >>> $bits) | ($value << (32 - $bits)));

	macro public static function MIN(x, y) return macro ($x < $y ? $x : $y);

	macro public static function STORE32H(x, y) return macro @:mergeBlock {
		$y[0] = (($x >>> 24) & 255); $y[1] = (($x >> 16) & 255);
		$y[2] = (($x  >>  8) & 255); $y[3] = ( $x        & 255);
	};

	macro public static function LOAD32H(x, y) return macro @:mergeBlock {
		$x = (($y[0] & 255) << 24) |
			 (($y[1] & 255) << 16) |
			 (($y[2] & 255) << 8)  |
			 (($y[3] & 255));
	};

	macro public static function STORE64H(x, y) return macro @:mergeBlock {
		Memory.setI32($y, 0);
		$y[4] = (($x >>> 24) & 255); $y[5] = (($x >> 16) & 255);
		$y[6] = (($x  >>  8) & 255); $y[7] =  ($x        & 255);
		//(y)[0] = (uint8_t)(((x)>>56)&255); (y)[1] = (uint8_t)(((x)>>48)&255);
		//(y)[2] = (uint8_t)(((x)>>40)&255); (y)[3] = (uint8_t)(((x)>>32)&255);
		//(y)[4] = (uint8_t)(((x)>>24)&255); (y)[5] = (uint8_t)(((x)>>16)&255);
		//(y)[6] = (uint8_t)(((x)>>8)&255); (y)[7] = (uint8_t)((x)&255);
	};


	macro public static function Ch(x, y, z) return macro ($z ^ ($x & ($y ^ $z)));

	macro public static function Maj(x, y, z) return macro ((($x | $y) & $z) | ($x & $y));

	macro public static function SS(x, n) return macro ror($x,$n);
	macro public static function RR(x, n) return macro (($x & 0xFFFFFFFF) >>> $n);

	macro public static function Sigma0(x) return macro (SS($x,  2) ^ SS($x, 13) ^ SS($x, 22));
	macro public static function Sigma1(x) return macro (SS($x,  6) ^ SS($x, 11) ^ SS($x, 25));
	macro public static function Gamma0(x) return macro (SS($x,  7) ^ SS($x, 18) ^ RR($x,  3));
	macro public static function Gamma1(x) return macro (SS($x, 17) ^ SS($x, 19) ^ RR($x, 10));

	macro public static function Sha256Round(a, b, c, d, e, f, g, h, i) return macro @:mergeBlock {
		t0 = $h + Sigma1($e) + Ch($e, $f, $g) + K[$i] + W[$i];
		t1 = Sigma0($a) + Maj($a, $b, $c);
		$d += t0;
		$h  = t0 + t1;
	};
}