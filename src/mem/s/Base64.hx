package mem.s;

import mem.Ptr;

@:build(mem.Struct.build())
@:allow(mem.s.Base64)
@:dce
abstract Base64String(Ptr) to Ptr {
	@idx(4, -4) private var _len:Int;

	public var length(get, never): Int;

	private inline function get_length() return _len;

	public inline function toString(): String return Utf8.getString(this, length);

	public inline function toBlock(): Block return Base64.decode(this, length);

	private inline function new(len: Int) {
		this = alloc(len + (CAPACITY + 1), false);
		_len = len;
		this[len] = 0;
	}
}


class Base64 {

	static var encoding_table: Ptr = Ptr.NUL;
	static var decoding_table: Ptr;

	static public function init():Void {
		if (encoding_table != Ptr.NUL) return;
		var p: Ptr = Mem.malloc(64 + 128, true);
		var q: Ptr = p + 64;

		var i = 0, c = "A".code;
		while (c <= "Z".code) {
			p[i] = c;
		++ i;
		++ c;
		}

		c = "a".code;
		while (c <= "z".code) {
			p[i] = c;
		++ i;
		++ c;
		}

		c = "0".code;
		while (c <= "9".code) {
			p[i] = c;
		++ i;
		++ c;
		}

		p[i] = "+".code;
		++ i;
		p[i] = "/".code;

		i = 0;
		while (i < 64) {
			setByte(q + p[i], i);
		++ i;
		}
		encoding_table = p;
		decoding_table = q;
	}

	static public function destory() {
		if (encoding_table != Ptr.NUL) {
			Mem.free(encoding_table);
			encoding_table = Ptr.NUL;
			decoding_table = Ptr.NUL;
		}
	}

	static public function encode(data: Ptr, len: Int): Base64String {
		if (encoding_table == Ptr.NUL) init();
		var i = 0, j = 0, triple = 0;

		var olen = Std.int((len + 2) / 3) << 2;  // == Math.ceil((n * 4)/3);

		var s64 = new Base64String(olen);
		var base: Ptr = s64;

		var et:Ptr = encoding_table;
		var rest = len % 3;
		len -= rest;
		while (i < len) {
			triple = (data[i] << 16) + (data[i + 1] << 8) + (data[i + 2]);
			setI32(base + j,
				(et[(triple >> 3 * 6) & 63]      ) +
				(et[(triple >> 2 * 6) & 63] <<  8) +
				(et[(triple >> 1 * 6) & 63] << 16) +
				(et[(triple >> 0 * 6) & 63] << 24)
			);
		i += 3;
		j += 4;
		}

		if (rest == 1) {
			triple = data[i] << 16;
			setI32(base + j,
				(et[(triple >> 3 * 6) & 63]      ) +
				(et[(triple >> 2 * 6) & 63] <<  8) +
				("=".code << 16) +
				("=".code << 24)
			);
		} else if (rest == 2) {
			triple = (data[i] << 16) + (data[i + 1] << 8);
			setI32(base + j,
				(et[(triple >> 3 * 6) & 63]      ) +
				(et[(triple >> 2 * 6) & 63] <<  8) +
				(et[(triple >> 1 * 6) & 63] << 16) +
				("=".code << 24)
			);
		}
		return s64;
	}

	static public function decode(data: Ptr, len: Int): Block {
		if (encoding_table == Ptr.NUL) init();
		var i = 0, j = 0, pad = 0, quart = 0, triple = 0;

		if (len & (4 - 1) > 0) return cast Ptr.NUL;

		var olen:Int = (len >> 2) * 3;

		if (data[len - 2] == "=".code)
			pad = 2;
		else if(data[len - 1] == "=".code)
			pad = 1;
		len  -= pad;
		olen -= pad;

		var fb = new Block(olen, false);
		var base:Ptr = fb;

		var dt:Ptr = decoding_table;
		while (i < len) {
			quart = getI32(data + i);
			triple = (dt[quart & 0x7F] << 18) + (dt[quart >> 8 & 0x7F] << 12) + (dt[quart >> 16 & 0x7F] << 6) + (dt[quart >> 24 & 0x7F]);
			setByte(base + j + 0, triple >> 16 & 0xFF);
			setByte(base + j + 1, triple >>  8 & 0xFF);
			setByte(base + j + 2, triple >>  0 & 0xFF);
		i += 4;
		j += 3;
		}

		if (pad > 0) {
			quart = getI32(data + i);
			triple = (dt[quart & 0x7F] << 18) + (dt[quart >> 8 & 0x7F] << 12) + (dt[quart >> 16 & 0x7F] << 6);
			if (pad == 2) {        // one byte
				setByte(base + j, triple & 0xFF);
			} else if (pad == 1) { // two bytes
				setI16 (base + j, triple & 0xFFFF);
			}
		}
		return fb;
	}

	static inline function getByte(ptr: Ptr):Int return ptr.getByte();
	static inline function  getI32(ptr: Ptr):Int return ptr.getI32();
	static inline function setByte(ptr: Ptr, value: Int):Void ptr.setByte(value);
	static inline function  setI32(ptr: Ptr, value: Int):Void ptr.setI32(value);
	static inline function  setI16(ptr: Ptr, value: Int):Void ptr.setI16(value);
}
