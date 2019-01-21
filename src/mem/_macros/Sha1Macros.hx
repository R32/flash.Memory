package mem._macros;

@:dce class Sha1Macros{

	public static inline var SHA1_HASH_SIZE = 160 >> 3;

	macro public static function rol(value, bits) {
		return macro ($value << $bits) | ($value >>> (32 - $bits));
	}

	macro public static function blk0(i)
		return macro @:mergeBlock {
			La = L[$i];
			L[$i] = (rol(La, 24) & 0xFF00FF00) | (rol(La,  8) & 0x00FF00FF);
		};

	macro public static function blk(i)
		return macro @:mergeBlock{
			La = L[($i +13) & 15];
			Lb = L[($i + 8) & 15];
			Lc = L[($i + 2) & 15];
			Ld = L[ $i &15];
			L[$i & 15] = rol(La ^ Lb ^ Lc ^ Ld, 1);
		};

	macro public static function R0(v, w, x, y, z, i)
		return macro @:mergeBlock {blk0($i); $z += (($w & ($x ^ $y)) ^ $y)         + L[$i     ] + 0x5A827999 + rol($v, 5); $w = rol($w, 30); };

	macro public static function R1(v, w, x, y, z, i)
		return macro @:mergeBlock { blk($i); $z += (($w & ($x ^ $y)) ^ $y)         + L[$i & 15] + 0x5A827999 + rol($v, 5); $w = rol($w, 30); };

	macro public static function R2(v, w, x, y, z, i)
		return macro @:mergeBlock { blk($i); $z += ($w ^ $x ^ $y)                  + L[$i & 15] + 0x6ED9EBA1 + rol($v, 5); $w = rol($w, 30); };

	macro public static function R3(v, w, x, y, z, i)
		return macro @:mergeBlock { blk($i); $z += ((($w | $x ) & $y) | ($w & $x)) + L[$i & 15] + 0x8F1BBCDC + rol($v, 5); $w = rol($w, 30); };

	macro public static function R4(v, w, x, y, z, i)
		return macro @:mergeBlock { blk($i); $z += ($w ^ $x ^ $y)                  + L[$i & 15] + 0xCA62C1D6 + rol($v, 5); $w = rol($w, 30); };

}