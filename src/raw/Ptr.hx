package raw;

typedef Memory  = raw.mem.Memory;

// similar to (uint_8*)
abstract Ptr(Int) {

	inline function new(i: Int) this = i;

	public inline function toInt() return this;

	@:arrayAccess inline function get(i: Int):Int return Memory.getByte(add(i));
	@:arrayAccess inline function set(i: Int, v:Int):Void Memory.setByte(add(i), v);

	@:op(A + B)  private inline function add(b: Int): Ptr
		return ofInt(this + b);

	@:op(A - B)  private inline function sub(b: Int): Ptr
		return ofInt(this - b);

	@:op(++A)  private inline function incr_a(): Ptr
		return ofInt(++this);

	@:op(A++)  private inline function incr_b(): Ptr
		return ofInt(this++);

	@:op(--A)  private inline function decr_a(): Ptr
		return ofInt(--this);

	@:op(A--)  private inline function decr_b(): Ptr
		return ofInt(this--);

	@:op(A < B)  private static inline function lt (a: Ptr, b: Ptr): Bool
		return a.toInt() < b.toInt();

	@:op(A <= B) private static inline function lte(a: Ptr, b: Ptr): Bool
		return a.toInt() <= b.toInt();

	@:op(A > B)  private static inline function gt (a: Ptr, b: Ptr): Bool
		return a.toInt() > b.toInt();

	@:op(A >= B) private static inline function gte(a: Ptr, b: Ptr): Bool
		return a.toInt() >= b.toInt();

	@:op(A == B) private static inline function eq (a: Ptr, b: Ptr): Bool
		return a.toInt() == b.toInt();

	@:op(A - B)  private static inline function diff(a: Ptr, b: Ptr): Int
		return a.toInt() - b.toInt();

	public static inline var NUL: Ptr = new Ptr(0);

	public static inline function ofInt(i): Ptr return cast i;
}


@idx(1, "&") abstract AU8(Ptr) to Ptr from Ptr {
	@:arrayAccess inline function get(i:Int):Int return Memory.getByte(this + i);
	@:arrayAccess inline function set(i:Int, v:Int):Void Memory.setByte(this + i, v);
	public static inline var SIZEOF = 1;
}

@idx(2, "&") abstract AU16(Ptr) to Ptr {
	@:arrayAccess inline function get(k:Int):Int return Memory.getUI16(this + (k + k));
	@:arrayAccess inline function set(k:Int, v:Int):Void Memory.setI16(this + (k + k), v);
	public static inline var SIZEOF = 2;
}

@idx(4, "&") abstract AI32(Ptr) to Ptr {
	@:arrayAccess inline function get(k:Int):Int return Memory.getI32(this + (k << 2));
	@:arrayAccess inline function set(k:Int, v:Int):Void Memory.setI32(this + (k << 2), v);
	public static inline var SIZEOF = 4;
}

@idx(4, "&") abstract AF4(Ptr) to Ptr {
	@:arrayAccess inline function get(k:Int):Float return Memory.getFloat(this + (k << 2));
	@:arrayAccess inline function set(k:Int, v:Float):Void Memory.setFloat(this + (k << 2), v);
	public static inline var SIZEOF = 4;
}

@idx(8, "&") abstract AF8(Ptr) to Ptr {
	@:arrayAccess inline function get(k:Int):Float return Memory.getDouble(this + (k << 3));
	@:arrayAccess inline function set(k:Int, v:Float):Void Memory.setDouble(this + (k << 3), v);
	public static inline var SIZEOF = 8;
}

@idx("no") abstract ABit(Ptr) to Ptr {
	@:arrayAccess function get(k:Int):Int {
		var byte = Memory.getByte(this + (k >> 3));
		var p = 7 - (k & 7);
		return (byte >> p) & 1;
	}
	@:arrayAccess function set(k:Int, v:Int):Void {
		var byte = Memory.getByte(this + (k >> 3));
		var p = 7 - (k & 7);
		Memory.setByte(this + (k >> 3),
			v == 0
			? byte & (~(1 << p))
			: byte | (1 << p)
		);
	}
}