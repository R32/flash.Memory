package;

import raw.Ptr;
import raw.Fixed;

class RawTest {

	static function main() {
		Raw.attach();
		//t_malloc();
		//t_fixed();
		var jojo = new Monkey(101, "Jo 乔");
		trace(jojo.__toOut());

		var j2 = new Monkey(202, "Xo 什么");
		trace(j2.__toOut());
	}


	static function t_malloc() {
		function randAlloc() {
			return Raw.malloc(Std.int(512 * Math.random()) + 16);
		}
		var ap = [];

		for (i in 0...512) ap.push(randAlloc());   // alloc 512
		raw.Ut.shuffle(ap);

		for (i in 0...256) Raw.free(ap.pop());     // free 256
		trace(raw.Malloc.toString());

		for (i in 0...256) ap.push(randAlloc());   // alloc 256
		raw.Ut.shuffle(ap);

		for (i in 0...256) Raw.free(ap.pop());     // free 256
		trace(raw.Malloc.toString());

		for (i in 0...256) Raw.free(ap.pop());     // free 256
		trace(raw.Malloc.toString());

		eq(raw.Malloc.isEmpty(), "raw.Malloc");
	}

	static function t_fixed() @:privateAccess {
		function iter(v) {
			var cur = Chunk.h;
			var rest = 0;
			while (cur != Ptr.NUL) {
				trace(cur.toString());
				rest += cur.rest;
				cur = cur.next;
			}
			eq(v == rest, "t_fixed");
			trace('-----------------');
		}

		var ap = [];
		for (i in 0...64) ap.push(Chunk.malloc(0, false));
		raw.Ut.shuffle(ap);

		for (i in 0...32) Chunk.free(ap.pop());     // free 256
		iter(32);

		for (i in 0...32) ap.push(Chunk.malloc(0, false));
		iter(0);
		raw.Ut.shuffle(ap);
		for (i in 0...64) Chunk.free(ap.pop());     // free 512
		iter(64);
		trace(Chunk.dump());
	}
	static inline function eq(expr, msg) if (!expr) throw msg;
}

#if !macro
@:build(raw.Struct.make({count: 64}))
#end
abstract Monkey(Ptr) to Ptr {
	@idx(4 ) var id: Int;
	@idx(16) var name: String;

	public inline function new(i, n) {
		mallocAbind(CAPACITY, false);
		id = i;
		name = n;
	}
}
