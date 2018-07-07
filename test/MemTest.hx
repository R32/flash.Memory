package;

import mem.Ut;
import mem.Ptr;
import mem.Utf8;
import mem.Alloc;
import mem.Fixed;

class MemTest {

	static function t_alloc() @:privateAccess {
		function rand() return Mem.malloc(Std.int(512 * Math.random()) + 16);

		var ap = [];
		for (i in 0...512) ap.push(rand());    // alloc 512
		shuffle(ap);
		__eq(Alloc.length == 512 && Alloc.frags == 0);

		for (i in 0...256) Mem.free(ap.pop()); // free 256
		__eq(Alloc.length - Alloc.frags == 256);

		for (i in 0...256) ap.push(rand());    // alloc 256
		shuffle(ap);

		for (i in 0...256) Mem.free(ap.pop()); // free 256
		__eq(Alloc.length - Alloc.frags == 256);
		__eq(Alloc.simpleCheck());

		for (i in 0...256) Mem.free(ap.pop()); // free 256
		__eq(Alloc.length == 0 && Alloc.frags == 0 && Alloc.isEmpty());
	}

	static function t_fixed() {
		var fx = new Fixed(16, 10);
		__eq(Alloc.length == 0); // not yet alloc chunk

		var ap = [];
		for (i in 0...480) ap.push(fx.malloc());
		var chunks = Math.ceil(480 / (32 * 10));
		__eq(Alloc.length == chunks);
		shuffle(ap);

		for (i in 0...240) fx.free(ap.pop());
		shuffle(ap);
		for (i in 0...240) ap.push(fx.malloc());
		__eq(Alloc.length == chunks);
		for (i in 0...480) fx.free(ap.pop());
		@:privateAccess {
			__eq(fx.h.caret == 0 && fx.h.frags == 0); // first chunk
			__eq(fx.q.caret == 0 && fx.q.frags == 0); // last  chunk
			fx.destory();
			__eq((fx.h == cast Ptr.NUL) && (fx.q == cast Ptr.NUL));
		}
		__eq(Alloc.length == 0 && Alloc.frags == 0 && Alloc.isEmpty());
	}

	static function t_utf8() {
		var s = "万般皆下品, 𨰻"; // 9
		var b = haxe.io.Bytes.ofString(s);
		var len = b.length;
		var p1: Ptr = Mem.malloc(len);
		var p3: Ptr = Mem.malloc(len);
		Mem.writeBytes(p1, len, b);

		var wlen = mem.Utf8.length(p1, len);
		__eq(wlen == 9);
		var p2: Ptr = Mem.malloc(wlen << 1);
		__eq(mem.Utf8.toUcs2(p2, p1, len) == wlen);
		__eq(mem.Utf8.ofUcs2(Ptr.NUL, p2, wlen << 1) == len);

		__eq(mem.Utf8.ofUcs2(p3, p2, wlen << 1) == len);
		__eq(Mem.memcmp(p1, p3, len) == 0);
		Mem.free(p1);
		Mem.free(p2);
		Mem.free(p3);
		__eq(Alloc.length == 0 && Alloc.frags == 0 && Alloc.isEmpty());
	}

	static function t_mem() {
		// read/writeBytes
		var b = haxe.io.Bytes.ofString("hello world! (e=mc^2)");
		var len = b.length;
		var p1 = Mem.malloc(len);
		Mem.writeBytes(p1, len, b);

		var out = Mem.readBytes(p1, len);
		__eq(b.compare(out) == 0);

		// memcpy, memset, memcmp
		var p23 = Mem.malloc(128);
		var p2 = p23 + 64; // center
		Mem.memcpy(p2, p1, len);
		var out = Mem.readBytes(p2, len);
		__eq(b.compare(out) == 0 && Mem.memcmp(p1, p2, len) == 0);
		// memcpy(p2 - 1, p2)
		var p3 = p2 - 1;
		Mem.memcpy(p3, p2, len);
		__eq(Mem.memcmp(p1, p3, len) == 0);
		// memcpy(p3 + 1, p3)
		Mem.memcpy(p2, p3, len);
		__eq(Mem.memcmp(p1, p2, len) == 0);
		// memcpy(p2, p2)
		Mem.memcpy(p2, p2, len);
		__eq(Mem.memcmp(p1, p2, len) == 0);
		// memset
		var p3 = p2 + len;
		Mem.memset(p2, "a".code, len); Mem.memset(p3, "z".code, len);
		__eq(Mem.memcmp(p2, p3, len) < 0 && Mem.memcmp(p3, p2, len) > 0);
		Mem.free(p1);
		Mem.free(p23);
		__eq(Alloc.length == 0 && Alloc.frags == 0 && Alloc.isEmpty());
	}

	// haxe generated too many unnecessary temporary variables
	static function too_many_local_var() {
		inline function rand() return MemTest.rand(100);
		var p = Mem.malloc(256);
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
		Mem.free(p);
		__eq(Alloc.length == 0 && Alloc.frags == 0 && Alloc.isEmpty());
	}

	static function t_utils() {
		__eq(Ut.TRAILING_ONES(0x7FFFFFFF) == 31);
		__eq(Ut.TRAILING_ONES(0xFFFFFFF7) ==  3);
		__eq(Ut.TRAILING_ONES(0x00000000) ==  0);
		__eq(Ut.TRAILING_ONES(0xFFF0FFFF) == 16);
		__eq(Ut.TRAILING_ONES(0xFFFFFF0F) ==  4);
		__eq(Ut.align(0, 8) == 8 && Ut.align(8, 8) == 8 && Ut.align(1, 8) == 8 && Ut.align(9, 8) == 16);
	}

	static function t_struct() {
		// no idea.
		__eq(Monkey.CAPACITY == 21);
		__eq(FixedBlock.CAPACITY == 70);
		__eq(FlexibleStruct.CAPACITY == 4 && FlexibleStruct.OFFSET_FIRST == -4);
	}
	///////

	static function __eq(b, ?pos: haxe.PosInfos) {
		if (!b) throw "ERROR: " + pos.lineNumber;
	}
	static function rand(max: Int, start = 0) {
		return Std.int(Math.random() * (max - start)) + start;
	}
	static function shuffle<T>(a: Array<T>, count = 1, start = 0) {
		var len = a.length;
		var r:Int, t:T;
		for (j in 0...count) {
			for (i in start...len) {
				r = rand(len, start);	// 0 ~ (len -1 )
				t = a[r];
				a[r] = a[i];
				a[i] = t;
			}
		}
	}
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
	static function main() {
		Mem.init();
		t_utils();
		t_alloc();
		t_fixed();
		t_struct();
		t_mem();
		t_utf8();
		too_many_local_var();
		trace(platform() + " done!");
	}
}

enum abstract Color(Int) {
	var R = 1;
	var G = 1 << 1;
	var B = 1 << 2;
}

@:build(mem.Struct.auto()) abstract Monkey(Ptr) {
	@idx(16) var name: String;  // 16bytes for name
	@idx var color: Color;      // same as Int, default is 1 byte.
	@idx var favor: Monkey;     // pointer to another
}

@:build(mem.Struct.auto()) abstract FlexibleStruct(Ptr) {
	@idx(4, -4) var length: Int; // @idx(bytes, offset); offset(relative to this) of the first field is -4
	@idx(0) var _b: AU8;         // Specify size by `new FlexibleStruct(size)` and the variable Type must be "array",
}

@:build(mem.Struct.auto({bulk: 1})) abstract FixedBlock(Ptr) {
	@idx(1) var b: Bool;
	@idx(1) var u8: Int;
	@idx(2) var u16: Int;
	@idx(4) var i32: Int;
	@idx(4) var f32: Float;
	@idx(8) var f64: Float;
	@idx(10) var au8: AU8;   // count = 10, byte = 1, bytes = 10 * 1
	@idx(10) var ai32: AI32; // count = 10, byte = 4, bytes = 10 * 4.
}
