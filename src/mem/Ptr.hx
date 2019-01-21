package mem;

extern abstract Ptr(Int) {
	inline function new(i: Int) this = i;
	inline function toInt():Int return this;
	inline function toAU8():AU8 return cast this;
	inline function toAU16():AU16 return cast this;
	inline function toAI32():AI32 return cast this;
	inline function toAF4():AF4 return cast this;
	inline function toAF8():AF8 return cast this;

	inline function getByte():Int return Memory.getByte(this);
	inline function getUI16():Int return Memory.getUI16(this);
	inline function getI32():Int return Memory.getI32(this);
	inline function getFloat():Float return Memory.getFloat(this);
	inline function getDouble():Float return Memory.getDouble(this);
	inline function setByte(v: Int):Void Memory.setByte(this, v);
	inline function setI16(v: Int):Void Memory.setI16(this, v);
	inline function setI32(v: Int):Void Memory.setI32(this, v);
	inline function setFloat(v: Float):Void Memory.setFloat(this, v);
	inline function setDouble(v: Float):Void Memory.setDouble(this, v);

	@:arrayAccess private inline function aget(i: Int):Int return Memory.getByte(this + i);
	@:arrayAccess private inline function aset(i: Int, v:Int):Void Memory.setByte(this + i, v);

	@:op(A + B) private inline function add(b: Int):Ptr return ofInt(this + b);
	@:op(A - B) private inline function sub(b: Int):Ptr return ofInt(this - b);
	@:op(++A) private inline function incr_a():Ptr return ofInt(++this);
	@:op(A++) private inline function incr_b():Ptr return ofInt(this++);
	@:op(--A) private inline function decr_a():Ptr return ofInt(--this);
	@:op(A--) private inline function decr_b():Ptr return ofInt(this--);

	@:op(A < B)  private static inline function lt (a: Ptr, b: Ptr):Bool return a.toInt() < b.toInt();
	@:op(A <= B) private static inline function lte(a: Ptr, b: Ptr):Bool return a.toInt() <= b.toInt();
	@:op(A > B)  private static inline function gt (a: Ptr, b: Ptr):Bool return a.toInt() > b.toInt();
	@:op(A >= B) private static inline function gte(a: Ptr, b: Ptr):Bool return a.toInt() >= b.toInt();
	@:op(A == B) private static inline function eq (a: Ptr, b: Ptr):Bool return a.toInt() == b.toInt();
	@:op(A - B)  private static inline function diff(a: Ptr, b: Ptr):Int return a.toInt() - b.toInt();

	static inline var NUL: Ptr = new Ptr(0);
	static inline function ofInt(i: Int): Ptr return cast i;
}

//////////////

@idx(1, "array") extern abstract AU8(Ptr) to Ptr {
	@:arrayAccess private inline function aget(i:Int):Int return this[i];
	@:arrayAccess private inline function aset(i:Int, v:Int):Void this[i] = v;
}

@idx(2, "array") extern abstract AU16(Ptr) to Ptr {
	@:arrayAccess private inline function aget(i:Int):Int return Memory.getUI16(this.toInt() + (i + i));
	@:arrayAccess private inline function aset(i:Int, v:Int):Void Memory.setI16(this.toInt() + (i + i), v);
}

@idx(4, "array") extern abstract AI32(Ptr) to Ptr {
	@:arrayAccess private inline function aget(i:Int):Int return Memory.getI32(this.toInt() + (i << 2));
	@:arrayAccess private inline function aset(i:Int, v:Int):Void Memory.setI32(this.toInt() + (i << 2), v);
}

@idx(4, "array") extern abstract AF4(Ptr) to Ptr {
	@:arrayAccess private inline function aget(i:Int):Float return Memory.getFloat(this.toInt() + (i << 2));
	@:arrayAccess private inline function aset(i:Int, v:Float):Void Memory.setFloat(this.toInt() + (i << 2), v);
}

@idx(8, "array") extern abstract AF8(Ptr) to Ptr {
	@:arrayAccess private inline function aget(i:Int):Float return Memory.getDouble(this.toInt() + (i << 3));
	@:arrayAccess private inline function aset(i:Int, v:Float):Void Memory.setDouble(this.toInt() + (i << 3), v);
}

/**
* UCS2 String. only works with `mem.Sturct.build()` that will be automatically converted to a String
*/
extern abstract UCString(Ptr) {}
