package mem.struct;

import mem.Ptr;
import mem.Malloc.NUL;
import mem.struct.AString;

@:build(mem.Struct.StructBuild.make())
abstract Base58String(Ptr) to Ptr {
	@idx(4, -4) private var _len:Int;

	public var length(get, never):Int;

	inline function get_length() return _len;

	public inline function toString() return Ph.toAscii(this, length);

	public inline function toBlock(): FBlock return Base58.decode(this, length);

	private inline function new(len: Int) {
		mallocAbind(len + CAPACITY + 1, false);
		_len = len;
		this[len] = 0;
	}
}


class Base58 {

	static var alphabet: AString = cast NUL;  // padmul(58, 8) = 64
	static var alphapos: AU8;                 // 128

	public static function init() {
		if (alphabet != NUL) return;
		var b = AStrImpl.fromString("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz");
		var p = Ram.malloc(128, true);
		for (i in 0...58)
			p[Memory.getByte(b + i)] = i;
		alphabet = b;
		alphapos = p;

		//for (i in 0...8) {
		//	var a = [];
		//	for (j in 0...16)
		//		a.push(p[(i << 4) + j]);
		//	trace(a);
		//}
		// 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		// 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		// 0, 0, 0, 0, 0, 0, 0, 0,  0, 0, 0, 0, 0, 0, 0, 0,
		// 0, 0, 1, 2, 3, 4, 5, 6,  7, 8, 0, 0, 0, 0, 0, 0,
		// 0, 9,10,11,12,13,14,15, 16, 0,17,18,19,20,21, 0,
		//22,23,24,25,26,27,28,29, 30,31,32, 0, 0, 0, 0, 0,
		// 0,33,34,35,36,37,38,39, 40,41,42,43, 0,44,45,46,
		//47,48,49,50,51,52,53,54, 55,56,57, 0, 0, 0, 0, 0,
	}

	public static function encode(bin: Ptr, len: Int):Base58String {
		// Skip & count leading zeroes.
		var i = 0;
		while (i < len && bin[i] == 0) ++i;

		var zeroes = i;
		var buffSize = Std.int((len - zeroes) * 138 / 100) + 1; // log(256) / log(58), rounded up.
		var buff = new haxe.ds.Vector<Int>(buffSize);
		var carry: Int, j:Int;

		var high = buffSize - 1;
		while (i < len) {
			carry = bin[i];
			j = buffSize - 1;
			while (j > high || carry != 0) {
				carry += 256 * buff[j];
				buff[j] = carry % 58;
				carry = Std.int(carry / 58);
			-- j ;
			}
			high = j;
		++ i;
		}

		// Skip leading zeroes
		j = 0;
		while (j < buffSize && buff[j] == 0) ++j;

		// Copy result into output.
		var s58 = @:privateAccess new Base58String(zeroes + buffSize - j);
		var etable:Ptr = cast alphabet;

		if (zeroes > 0) Ram.memset(s58, "1".code, zeroes);

		i = zeroes;
		while (j < buffSize) {
			Memory.setByte(s58 + i, etable[ buff[j] ]);
		++ i;
		++ j;
		}
		buff = null;
		return s58;
	}

	public static function decode(str: Ptr, len: Int):FBlock {
		// Skip and count leading '1's.
		var i = 0;
		while (i < len && str[i] == "1".code) ++i;

		var zeroes = i;
		var buffSize = Std.int((len - zeroes) * 733 / 1000) + 1; // log(58) / log(256), rounded up.
		var buff = new haxe.ds.Vector<Int>(buffSize);
		var ci:Int, carry:Int, j:Int;
		var dtable = alphapos;

		while (i < len) {
			ci = str[i] & 0x7F;
			carry = dtable[ci];
			j = buffSize - 1;
			while (j >= 0) {
				carry += 58 * buff[j];
				buff[j] = carry & 255;  // buff[j] = carry % 256;
				carry >>= 8;            // carry /= 256
			-- j;
			}
		++ i;
		}

		// Skip leading zeroes
		j = 0;
		while (j < buffSize && buff[j] == 0) ++j;

		// Copy result into output.
		var fb = new FBlock(buffSize + zeroes - j, true, 8);
		i = zeroes;
		while(j < buffSize) {
			fb[i] = buff[j];
		++ i;
		++ j;
		}
		buff = null;
		return fb;
	}

}