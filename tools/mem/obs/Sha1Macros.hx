package mem.obs;

@:dce class Sha1Macros{

	public static inline var SHA1_HASH_SIZE = 160 >> 3;

	macro public static function rol(value, bits) {
		return macro ($value << $bits) | ($value >>> (32 - $bits));
	}
	// N.B: "L == block-l", it's a local variable defined in func process, and "L[X] = N"(setter) can not be return value, so...
	macro public static function blk0(i)
		return macro @:mergeBlock{(L[$i] = (rol(L[$i], 24) & 0xFF00FF00 ) | (rol(L[$i], 8) & 0x00FF00FF)); L[$i];};

	macro public static function blk(i)
		return macro @:mergeBlock{(L[$i & 15] = rol(L[($i+13) & 15] ^ L[($i + 8) & 15] ^ L[($i + 2) & 15] ^ L[$i & 15], 1)); L[$i & 15];};

	macro public static function R0(v, w, x, y, z, i)
		return macro @:mergeBlock { $z += (($w & ($x ^ $y)) ^ $y)        + blk0($i) + 0x5A827999 + rol($v, 5); $w = rol($w, 30); };

	macro public static function R1(v, w, x, y, z, i)
		return macro @:mergeBlock { $z += (($w & ($x ^ $y)) ^ $y)         + blk($i) + 0x5A827999 + rol($v, 5); $w = rol($w, 30); };

	macro public static function R2(v, w, x, y, z, i)
		return macro @:mergeBlock { $z += ($w ^ $x ^ $y)                  + blk($i) + 0x6ED9EBA1 + rol($v, 5); $w = rol($w, 30); };

	macro public static function R3(v, w, x, y, z, i)
		return macro @:mergeBlock { $z += ((($w | $x ) & $y) | ($w & $x)) + blk($i) + 0x8F1BBCDC + rol($v, 5); $w = rol($w, 30); };

	macro public static function R4(v, w, x, y, z, i)
		return macro @:mergeBlock { $z += ($w ^ $x ^ $y)                  + blk($i) + 0xCA62C1D6 + rol($v, 5); $w = rol($w, 30); };

}