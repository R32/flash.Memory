package raw;

abstract Bits(Int) to Int {

	public inline function new(i: Int) this = i;

	@:arrayAccess inline function get(p:Int):Int
		return (this >> p) & 1;

	@:arrayAccess inline function set(p:Int, v:Int):Void
		this = v == 0 ? this & (~(1 << p)) : this | (1 << p);

	public static inline function toInt(): Int return this;
	public static inline function ofInt(i: Int): Bits return new Bits(i);
}