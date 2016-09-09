package mem.obs;



class Md5Macros {
	macro public static function S(x, n) {
		return macro (($x << $n) | ($x >>> (32 - $n)));
	}

	macro public static function P(a, b, c, d, k, s, t, X, F) {
		return macro @:mergeBlock{ $a += $F($b, $c, $d) + ($X[$k]) + $t; $a = S($a, $s) + $b; }
	}

	macro public static function F1(x, y, z) return macro ($z ^ ($x & ($y ^ $z)));

	macro public static function F2(x, y, z) return macro ($y ^ ($z & ($x ^ $y)));

	macro public static function F3(x, y, z) return macro ($x ^ $y ^ $z);

	macro public static function F4(x, y, z) return macro ($y ^ ($x | ~$z));
}