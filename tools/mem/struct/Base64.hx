package mem.struct;

import mem.Ptr;
import mem.Malloc.NUL;
import mem.struct.Comm.*;

@:dce abstract Base64String(Ptr) to Ptr {
	public var length(get, never): Int;

	private inline function get_length() return Memory.getI32(realEntry());

	private inline function new(addr: Ptr) this = cast addr;

	public inline function realEntry(): Ptr { return this - BY_LEN; }

	public inline function free(): Void { Ram.free( realEntry() ); this = NUL; }

	public inline function toString(): String return Ph.toAscii(this, length);

	public inline function toBlock(): Base64Block return Base64.decode(this, length);
}

@:dce abstract Base64Block(Ptr) to Ptr { // TODO: @:foword does not work???

	public var length(get, never): Int;

	private inline function get_length() return Memory.getI32(realEntry());

	private inline function new(addr:Ptr) this = cast addr;

	public inline function realEntry(): Ptr { return this - BY_LEN; }

	public inline function free(): Void { Ram.free( realEntry() ); this = NUL; }

	public inline function toString(): String return Ph.toAscii(this, length);

	public inline function toBase64String(): Base64String return Base64.encode(this, length);
}

class Base64 {

	static var encoding_table: Ptr = NUL;
	static var decoding_table: Ptr;

	static public function init():Void {
		if (encoding_table != NUL) return;
		encoding_table = Ram.malloc(64, false);
		decoding_table = Ram.malloc(128, false);
	/*
		var i = 0;
		for (c in "A".code..."Z".code + 1)
			encoding_table[i++] = c;
		for (c in "a".code..."z".code + 1)
			encoding_table[i++] = c;
		for (c in "0".code..."9".code + 1)
			encoding_table[i++] = c;
		encoding_table[i++] = "+".code;
		encoding_table[i] = "/".code;
		i = 0;
		while (i < 64) {
			decoding_table[encoding_table[i]] = i;
		++i;
		}
	*/// to many local variables above

		var p:Ptr = cast encoding_table;
		var q:Ptr = cast decoding_table;

		var i = 0, c = "A".code;
		while (c <= "Z".code) {
			Memory.setByte(p + i, c); ++i;
		++c;
		}

		c = "a".code;
		while (c <= "z".code) {
			Memory.setByte(p + i, c); ++i;
		++c;
		}
		c = "0".code;
		while (c <= "9".code) {
			Memory.setByte(p + i, c); ++i;
		++c;
		}
		Memory.setByte(p + i, "+".code); ++i;
		Memory.setByte(p + i, "/".code);

		i = 0;
		while (i < 64) {
			Memory.setByte(Memory.getByte(p + i) + q, i);
		++i;
		}

/*		for (m in 0...16) {
			var a = [];
			for (n in 0...8)
				a.push(q[m * 8 + n]);
			trace(a);
		}*/
		//trace(Ph.toAscii(cast p, 64));
	}

	static public function encode(data: Ptr, len: Int): Base64String {
		var i = 0, j = 0, triple = 0;

		var olen = Std.int((len + 2) / 3) << 2;  // == Math.ceil((n * 4)/3);

		var addr:Ptr = Ram.malloc(olen + BY_LEN + 1); // length + DATA + \0
		var base:Ptr = cast addr + BY_LEN;

		var et:Ptr = encoding_table;

		Memory.setI32(addr, olen);
		Memory.setByte(base + olen, 0);

		var rest = len % 3;
		len -= rest;

		while (i < len) {
			triple = (data[i] << 16) + (data[i + 1] << 8) + (data[i + 2]);
			Memory.setI32(base + j,
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
			Memory.setI32(base + j,
				(et[(triple >> 3 * 6) & 63]      ) +
				(et[(triple >> 2 * 6) & 63] <<  8) +
				("=".code << 16) +
				("=".code << 24)
			);
		} else if (rest == 2) {
			triple = (data[i] << 16) + (data[i + 1] << 8);
			Memory.setI32(base + j,
				(et[(triple >> 3 * 6) & 63]      ) +
				(et[(triple >> 2 * 6) & 63] <<  8) +
				(et[(triple >> 1 * 6) & 63] << 16) +
				("=".code << 24)
			);
		}
		return @:privateAccess new Base64String(base);
	}

	static public function decode(data: Ptr, len: Int): Base64Block {
		var i = 0, j = 0, pad = 0, quart = 0, triple = 0;

		if (len & (4 - 1) > 0) return cast NUL;

		var olen:Int = (len >> 2) * 3;

		if (data[len - 2] == "=".code)
			pad = 2;
		else if(data[len - 1] == "=".code)
			pad = 1;
		len  -= pad;
		olen -= pad;

		var addr:Ptr = Ram.malloc(olen + BY_LEN + 1, false);
		var base:Ptr = addr + BY_LEN;
		Memory.setI32(addr, olen); // set length
		Memory.setByte(base + olen, 0);

		var dt:Ptr = decoding_table;
		while (i < len) {
			quart = Memory.getI32(data + i);
			triple = (dt[quart & 0x7F] << 18) + (dt[quart >> 8 & 0x7F] << 12) + (dt[quart >> 16 & 0x7F] << 6) + (dt[quart >> 24 & 0x7F]);
			Memory.setByte(base + j + 0, triple >> 16 & 0xFF);
			Memory.setByte(base + j + 1, triple >>  8 & 0xFF);
			Memory.setByte(base + j + 2, triple >>  0 & 0xFF);
		i += 4;
		j += 3;
		}

		if (pad > 0) {
			quart = Memory.getI32(data + i);
			triple = (dt[quart & 0x7F] << 18) + (dt[quart >> 8 & 0x7F] << 12) + (dt[quart >> 16 & 0x7F] << 6);
			if (pad == 2) {        // one byte
				Memory.setByte(base + j, triple & 0xFF);
			} else if (pad == 1) { // two bytes
				Memory.setI16 (base + j, triple & 0xFFFF);
			}
		}
		return @:privateAccess new Base64Block(base);
	}
}