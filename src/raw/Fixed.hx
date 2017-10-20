package raw;

#if !macro
@:genericBuild(raw._macros.FixedMacros.gen())
#end
class Fixed<T, Const> {}

/**
This File Only For Test.....

Fixed alloter template.. [SIZEOF = 32, COUNT = 32];
*/
@:dce abstract Chunk(raw.Ptr) to raw.Ptr {
	public var next(get, set): Chunk;    // 4 bytes
	inline function get_next(): Chunk return cast raw.Ptr.Memory.getI32(this);
	inline function set_next(c: Chunk): Chunk {
		raw.Ptr.Memory.setI32(this, cast c);
		return c;
	}

	public var frags(get, set): Int;     // 2 bytes
	inline function get_frags() return raw.Ptr.Memory.getUI16(this + 4);
	inline function set_frags(v) { raw.Ptr.Memory.setI16(this + 4, v); return v; }

	public var caret(get, set): Int;     // 2 bytes
	inline function get_caret() return raw.Ptr.Memory.getUI16(this + 6);
	inline function set_caret(v) { raw.Ptr.Memory.setI16(this + 6, v); return v; }

	public var entry(get, never): Ptr;
	inline function get_entry() return this + (CAPACITY + COUNT);

	public var meta(get, never): Ptr;
	inline function get_meta() return this + CAPACITY;

	public var rest(get, never): Int;
	inline function get_rest() return COUNT - caret + frags;

	public inline function new() {
		raw._macros.FixedMacros.newz();
	}

	public inline function valid(p: Ptr): Bool {
		raw._macros.FixedMacros.valid(p);
	}

	function request(zero: Bool): Ptr {
		raw._macros.FixedMacros.request(zero);
	}

	function release(p: Ptr) {
		raw._macros.FixedMacros.release(p);
	}

	public inline function toString() {
		var s = "";
		var c = 0;
		for (i in 0...COUNT) {
			if (i != 0 && i % 8 == 0) s += " ";
			var z = raw.Ptr.Memory.getByte(this + CAPACITY + i) == 0;
			if (i < caret && z) ++ c;
			s +=  z ? "0" : "1";
		}
		return 'SIZEOF: $SIZEOF, COUNT: $COUNT, frags: $frags, caret: $caret, rest: $rest\n  c: $c, $s';
		//raw._macros.FixedMacros.toString();
	}

	public static inline var CAPACITY = 8;
	public static inline var COUNT  = 32;
	public static inline var SIZEOF = 32;
	static var h: Chunk = cast Ptr.NUL;
	static var q: Chunk = cast Ptr.NUL;
	static inline function create(): Chunk return new Chunk(); //

	static function add(c: Chunk) {
		raw._macros.FixedMacros.add(c);
	}

	public static function destory() {
		raw._macros.FixedMacros.destory();
	}

	public static function malloc(size: Int, zero: Bool) {
		raw._macros.FixedMacros.malloc(zero);
	}

	public static function free(p: Ptr) {
		raw._macros.FixedMacros.free(p);
	}

	public static function dump() {
		raw._macros.FixedMacros.dump();
	}

}
