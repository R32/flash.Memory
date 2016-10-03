package mem;

import mem.Ptr;

/*
 Copyright (c) 2008-2009 Bjoern Hoehrmann <bjoern@hoehrmann.de>
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
*/

@:dce @:enum private abstract UTF8Valid(Int) to Int {
	var UTF8_ACCEPT = 0;
	var UTF8_REJECT = 1;
}
#if cpp
@:nativeGen @:headerCode("#define Utf8hx Utf8hx_obj") @:native("mem.obs.Utf8hx") // for names conflict
#end
class Utf8 {
	#if cpp
	static var utf8d_table(default, null):AU8;
	#else
	static var utf8d_table(default, null):AU8 = cast Malloc.NUL;
	#end

	public static function init() {
		if (utf8d_table != Malloc.NUL) return;

		var data = Mt.utf8DataTo32(); // I32, 100 * 4

		utf8d_table = cast Ram.malloc(400, false);

		var u32:AI32 = cast utf8d_table;

		for (i in 0...100) u32[i] = data[i];
	}

	public static function validate(dst:Ptr, byteLength: Int): Bool {
		var i = 0, state = 0, utf8d = utf8d_table;
		var byte:Int, type:Int;
		while (i < byteLength) {
			byte = dst[i];
			type = utf8d[byte];

			state = utf8d[256 + (state << 4) + type];

			if (state == UTF8_REJECT) return false;
		++ i;
		}
		return state == UTF8_ACCEPT;
	}


	public static function length(dst:Ptr, byteLength: Int):Int {
		var i = 0, len = 0, state = 0, utf8d = utf8d_table;
		var byte:Int, type:Int;
		while (i < byteLength) {
			byte = dst[i];
			type = utf8d[byte];

			state = utf8d[256 + (state << 4) + type];

			if (state == UTF8_REJECT)
				return -1; //throw "Invalid utf8 string";
			else if (state == UTF8_ACCEPT)
				len += 1;
		++ i;
		}
		return len;
	}

	public static function iter(dst:Ptr, byteLength: Int, chars : Int -> Void ):Bool {
		var i = 0, state = 0, codep = 0, utf8d = utf8d_table;
		var byte:Int, type:Int;
		while (i < byteLength) {
			byte = dst[i];
			type = utf8d[byte];

			codep = state != UTF8_ACCEPT ?
				(byte & 0x3f) | (codep << 6) :
				(0xff >> type) & (byte);

			state = utf8d[256 + (state << 4) + type];

			if (state == UTF8_REJECT)
				return false;
			else if (state == UTF8_ACCEPT)
				chars(codep);
		++ i;
		}
		return true;
	}

	public static function charCodeAt(dst:Ptr, byteLength: Int, index:Int):Int {
		var i = 0, len = 0, state = 0, codep = 0, utf8d = utf8d_table;
		var byte:Int, type:Int;
		while (i < byteLength) {
			byte = dst[i];
			type = utf8d[byte];

			if (len == index) {
				codep = state != UTF8_ACCEPT ?
					(byte & 0x3f) | (codep << 6) :
					(0xff >> type) & (byte);
			}

			state = utf8d[256 + (state << 4) + type];

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
