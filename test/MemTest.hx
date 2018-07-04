package;

import mem.Ptr;
import mem.Utf8;

class MemTest {
	static inline function platform() {
		return
		#if flash
		"flash";
		#elseif hl
		"hashlink";
		#elseif js
		"js";
		#elseif hxcpp
		"hxcpp"
		#else
		"others";
		#end
	}

	static function test_utf8() {
		var s = "你好, 中文和abc𨰻"; // 12
		var b = haxe.io.Bytes.ofString(s);
		var len = b.length;
		var p1: Ptr = Ptr.ofInt(0);
		var p2: Ptr = p1 + len;
		Mem.writeBytes(p1, len, b);
		var wlen = mem.Utf8.length(p1, len);
		eq(wlen == 12);
		eq(mem.Utf8.toUcs2(p2, p1, len) == wlen);
		eq(mem.Utf8.ofUcs2(Ptr.NUL, p2, wlen << 1) == len);
		var p3: Ptr = p2 + (wlen << 1);
		eq(mem.Utf8.ofUcs2(p3, p2, wlen << 1) == len);
		eq(Mem.memcmp(p1, p3, len) == 0);
	}

	static function test_mem() {
		// read/writeBytes
		var b = haxe.io.Bytes.ofString("hello world! (e=mc^2)");
		var len = b.length;
		var p1: Ptr = Ptr.ofInt(0);
		Mem.writeBytes(p1, len, b);

		var out = Mem.readBytes(p1, len);
		eq(b.compare(out) == 0);

		// memcpy, memset, memcmp
		var p2: Ptr = p1 + 128;
		Mem.memcpy(p2, p1, len);
		var out = Mem.readBytes(p2, len);
		eq(b.compare(out) == 0 && Mem.memcmp(p1, p2, len) == 0);
		// memcpy(p2 - 1, p2)
		var p3: Ptr = p2 - 1;
		Mem.memcpy(p3, p2, len);
		eq(Mem.memcmp(p1, p3, len) == 0);
		// memcpy(p3 + 1, p3)
		Mem.memcpy(p2, p3, len);
		eq(Mem.memcmp(p1, p2, len) == 0);
		// memcpy(p2, p2)
		Mem.memcpy(p2, p2, len);
		eq(Mem.memcmp(p1, p2, len) == 0);
		// memset
		var p3 = p2 + len;
		Mem.memset(p2, "a".code, len); Mem.memset(p3, "z".code, len);
		eq(Mem.memcmp(p2, p3, len) < 0 && Mem.memcmp(p3, p2, len) > 0);
	}

	static function test_too_many_local_var() {
		var p: Ptr = Ptr.ofInt(0);
		var i = 0;
		p[i++] = rand();
		p[i++] = rand();
		p[i++] = rand();

		var u8 = p.toAU8();
		u8[i++] = rand();
		u8[i++] = rand();
		u8[i++] = rand();

		var u16 = p.toAU16();
		u16[i++] = rand();
		u16[i++] = rand();
		u16[i++] = rand();


		var i32 = p.toAI32();
		i32[i++] = rand();
		i32[i++] = rand();
		i32[i++] = rand();

		var f32 = p.toAF4();
		f32[i++] = Math.random();
		f32[i++] = Math.random();
		f32[i++] = Math.random();

		var f64 = p.toAF8();
		f64[i++] = Math.random();
		f64[i++] = Math.random();
		f64[i++] = Math.random();
	}

	static function main() {
		Mem.init();
		test_mem();
		test_utf8();
		test_too_many_local_var();
		trace(platform() + " done!");
	}

	static function rand() {
		return Std.int(Math.random() * 100);
	}


	static function eq(b, ?pos: haxe.PosInfos) {
		if (!b) throw "ERROR: " + pos.lineNumber;
	}
}
