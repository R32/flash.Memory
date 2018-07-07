package mem._macros;

import haxe.macro.Expr;

class IDXParams {

	public var sizeOf : Int;
	public var offset : Int;
	public var count  : Int;
	public var extra  : String;
	public var bytes(get, never): Int;
	inline function get_bytes():Int return sizeOf * count;

	public var argc (default, null): Int;  // do not include "extra" field

	public function new() {
		reset();
	}

	static var reserve = ["array", "no"];
	public inline function isArray():Bool return extra == reserve[0];
	public inline function unSupported():Bool return extra == reserve[1];

	function set(order: Int, value: Int) {
		switch (order) {
		case 0: sizeOf = value;
		case 1: offset = value;
		case 2: count  = value;
		default: throw haxe.io.Error.OutsideBounds;
		}
	}

	function get(order: Int): Int {
		return switch (order) {
		case 0: sizeOf;
		case 1: offset;
		case 2: count;
		default: throw haxe.io.Error.OutsideBounds;
		}
	}

	public function reset() {
		sizeOf = 1;
		offset = 0;
		count  = 1;
		argc   = 0;
		extra = null;
	}

	public function parse(ent: MetadataEntry) {
		var skip = 0;
		argc = ent.params.length;
		for (i in 0...argc) {
			var e = ent.params[i];
			switch (e.expr) {
			case EConst(c):
				switch (c) {
				case CString(s) | CIdent(s):
					if (reserve.indexOf(s) == -1) throw "UnSupported " + s;
					extra = s;
					++skip;
				case CInt(n) | CFloat(n):
					set(i - skip, Std.parseInt(n));
				default:
				}
			default:
			}
		}
		argc -= skip;
	}

	public function toString() {
		return 'sizeOf: $sizeOf, offset: $offset, count: $count, bytesLength: $bytes, argc: $argc, extra: $extra';
	}
}