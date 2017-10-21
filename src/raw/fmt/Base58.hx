package raw.fmt;

import raw.Ptr;

@:build(raw.Struct.make())
@:allow(raw.fmt.Base58)
@:dce
abstract Base58String(Ptr) to Ptr {
	@idx(4, -4) private var _len:Int;

	public var length(get, never):Int;

	inline function get_length() return _len;

	public inline function toString() return Raw.readUtf8(this, length);

	public inline function toBlock(): FBlock return Base58.decode(this, length);

	private inline function new(len: Int) {
		mallocAbind(len + (CAPACITY + 1), true);
		_len = len;
	}

	@:arrayAccess inline function get(i: Int):Int return Memory.getByte(this + i);
	@:arrayAccess inline function set(i: Int, v:Int):Void Memory.setByte(this + i, v);
}

/**
example:

```haxe
var b1 = Raw.mallocFromHex("003c176e659bea0f29a3e9bf7880c112b1b31b4dc826268187");
var b58 = Base58.encode(b1, b1.length);

trace(b58.toString(), b58.toString() == "16UjcYNBG9GTK4uq2f7yYEbuifqCzoLMGS");
```
*/
class Base58 {

	static var alphabet: Ptr = Ptr.NUL;  // 58
	static var alphapos: Ptr;            // 128

	public static function init() {
		if (alphabet != Ptr.NUL) return;
		var b = Raw.malloc(58 + 128, true);
		var p = b + 58;
		var s = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
		for (i in 0...58) {
			var c = StringTools.fastCodeAt(s, i);
			b[i] = c;
			p[c] = i;
		}
		alphabet = b;
		alphapos = p;
	}

	public static function encode(bin: Ptr, len: Int):Base58String {
		if (alphabet == Ptr.NUL) init();
		// Skip & count leading zeroes.
		var i = 0;
		while (i < len && bin[i] == 0) ++i;

		var zeroes = i;
		var buffSize = Std.int((len - zeroes) * 138 / 100) + 1; // log(256) / log(58), rounded up.
		var s58Length = zeroes + buffSize;
		var s58 = new Base58String(s58Length);

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
		if (zeroes > 0) Raw.memset(s58, "1".code, zeroes);

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
		if (alphabet == Ptr.NUL) init();
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
		raw.Ph.reverse((fb:Ptr) + zeroes, fbLength - zeroes);
		return fb;
	}
}