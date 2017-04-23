package mem;

import mem.Ptr;
import mem.obs._macros.Utf8Macos.*;

@:dce @:enum private abstract UTF8Valid(Int) to Int {
	var UTF8_ACCEPT = 0;
	var UTF8_REJECT = 12;
}

// Copyright (c) 2008-2010 Bjoern Hoehrmann <bjoern@hoehrmann.de>
// See http://bjoern.hoehrmann.de/utf-8/decoder/dfa/ for details.
class Utf8 {

	static var utf8d_table(default, null):AU8 = cast Ptr.NUL;

	public static function init() {
		if (utf8d_table != Ptr.NUL) return;

		var data = utf8DataTo32(); // I32;

		var len = data.length;

		utf8d_table = cast Fraw.malloc(len * 4, false);

		var u32:AI32 = cast utf8d_table;

		for (i in 0...len) u32[i] = data[i];
	}

	public static function validate(src:Ptr, byteLength: Int): Bool {
		var i = 0, state = 0, utf8d = utf8d_table;
		var byte:Int, type:Int;
		while (i < byteLength) {
			byte = src[i];
			type = utf8d[byte];

			state = utf8d[256 + state + type];

			if (state == UTF8_REJECT) return false;
		++ i;
		}
		return state == UTF8_ACCEPT;
	}


	public static function length(src:Ptr, byteLength: Int):Int {
		var i = 0, len = 0, state = 0, utf8d = utf8d_table;
		var byte:Int, type:Int;
		while (i < byteLength) {
			byte = src[i];
			type = utf8d[byte];

			state = utf8d[256 + state + type];

			if (state == UTF8_REJECT)
				return -1; //throw "Invalid utf8 string";
			else if (state == UTF8_ACCEPT)
				len += 1;
		++ i;
		}
		return len;
	}

	public static function iter(src:Ptr, byteLength: Int, chars : Int -> Void ):Bool {
		var i = 0, state = 0, codep = 0, utf8d = utf8d_table;
		var byte:Int, type:Int;
		while (i < byteLength) {
			byte = src[i];
			type = utf8d[byte];

			codep = state != UTF8_ACCEPT ?
				(byte & 0x3f) | (codep << 6) :
				(0xff >> type) & (byte);

			state = utf8d[256 + state + type];

			if (state == UTF8_REJECT)
				return false;
			else if (state == UTF8_ACCEPT)
				chars(codep);
		++ i;
		}
		return true;
	}

	public static function charCodeAt(src:Ptr, byteLength: Int, index:Int):Int {
		var i = 0, len = 0, state = 0, codep = 0, utf8d = utf8d_table;
		var byte:Int, type:Int;
		while (i < byteLength) {
			byte = src[i];
			type = utf8d[byte];

			if (len == index) {
				codep = state != UTF8_ACCEPT ?
					(byte & 0x3f) | (codep << 6) :
					(0xff >> type) & (byte);
			}

			state = utf8d[256 + state + type];

			if (state == UTF8_REJECT) {
				break; //throw "Invalid utf8 string";
			} else if (state == UTF8_ACCEPT) {
				if (len == index) return codep;
				len += 1;
			}
		++ i;
		}
		return -1;     // out of range
	}
}
