package mem.struct;

import mem.Ptr;
import mem.struct.AString;

@:build(mem.Struct.make())
abstract Base58String(Ptr) to Ptr {
	@idx(4, -4) private var _len:Int;

	public var length(get, never):Int;

	inline function get_length() return _len;

	public inline function toString() return Ph.toAscii(this, length);

	public inline function toBlock(): FBlock return Base58.decode(this, length);

	private inline function new(len: Int) {
		mallocAbind(len + CAPACITY + 1, true);
		_len = len;
	}

	@:arrayAccess inline function get(i: Int):Int return Memory.getByte((this:Int) + i);
	@:arrayAccess inline function set(i: Int, v:Int):Void Memory.setByte((this:Int) + i, v);
}

/**
example:

```haxe
Base58.init();

var strhex = "003c176e659bea0f29a3e9bf7880c112b1b31b4dc826268187";
var sa  = AString.fromHexString(strhex);
var s58 = Base58.encode(sa, sa.length);

trace(s58.toString(), s58.toString() == "16UjcYNBG9GTK4uq2f7yYEbuifqCzoLMGS");

var b58 = s58.toBlock();
trace(b58.toBytes().toHex(), b58.toBytes().toHex() == strhex);
```
*/
class Base58 {

	static var alphabet: AString = cast Ptr.NUL;  // padmul(58, 8) = 64
	static var alphapos: AU8;                 // 128

	public static function init() {
		if (alphabet != Ptr.NUL) return;
		var b = AString.fromString("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz");
		var p = Fraw.malloc(128, true);
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
		var s58Length = zeroes + buffSize;
		var s58 = @:privateAccess new Base58String(s58Length);

		var carry: Int, j:Int;

		var high = zeroes;
		while (i < len) {
			carry = bin[i];
			j = zeroes;
			while (j < high || carry != 0) {
				carry += 256 * s58[j];
				s58[j] = carry % 58;
				carry = Std.int(carry / 58);
			++ j;
			}
			high = j;
		++ i;
		}

		// Skip tailing zeroes & change the length value
		j = s58Length - 1;
		while (j >= 0 && s58[j] == 0) --j;
		s58Length = j + 1;
		@:privateAccess s58._len = s58Length;

		// padding '1'
		if (zeroes > 0) Fraw.memset(s58, "1".code, zeroes);

		// reverse & enc; let i = left, j = right, carry = tmp;
		var enc:Ptr = cast alphabet;
		i = zeroes;
		while (i < j) {
			carry = s58[i];
			s58[i] = enc[s58[j]];
			s58[j] = enc[carry];
		++ i;
		-- j;
		}
		if (i == j) s58[i] = enc[s58[i]];
		return s58;
	}

	public static function decode(str: Ptr, len: Int):FBlock {
		// Skip and count leading '1's.
		var i = 0;
		while (i < len && str[i] == "1".code) ++i;

		var zeroes = i;
		var buffSize = Std.int((len - zeroes) * 733 / 1000) + 1; // log(58) / log(256), rounded up.
		var fbLength = zeroes + buffSize;
		var fb = new FBlock(fbLength, true, 8);
		var ci:Int, carry:Int, j:Int;
		var dec = alphapos;

		var high = zeroes;
		while (i < len) {
			ci = str[i] & 0x7F;
			carry = dec[ci];
			j = zeroes;
			while (j < high || carry != 0) {
				carry += 58 * fb[j];
				fb[j] = carry & 255;  // buff[j] = carry % 256;
				carry >>= 8;          // carry /= 256
			++ j;
			}
			high = j;
		++ i;
		}

		// Skip tailing zeroes & change the length value
		j = fbLength - 1;
		while (j >= 0 && fb[j] == 0) --j;
		fbLength = j + 1;
		@:privateAccess fb._len = fbLength;

		// reverse
		mem.Ph.reverse((fb:Ptr) + zeroes, fbLength - zeroes);
		return fb;
	}
}