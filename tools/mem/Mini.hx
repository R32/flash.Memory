package mem;

import mem.Ut;
import mem.Ptr;
import mem.Malloc.NUL;

/**
a simple fixed-width memory allocator. These chunk sizes are 8, 16, 24 ... 128

Note: have not tested
*/
class Mini {

	var lvl: Int;
	var h: MiniNode;
	var q: MiniNode;

	function new (l: Int) {
		if (l < 1 || l > LVL_MAX) l = 1;
		lvl = l;
		h = q = cast NUL;
		add(new MiniNode(lvl));
	}

	function add(b: MiniNode) {
		if( h == NUL )
			h = b;
		else
			q.next = b;
		q = b;
	}

	function destory() {
		var prev: MiniNode = cast NUL;
		var lop = h;
		while (lop != NUL) {
			prev = lop;
			lop = lop.next;
			prev.free();
		}
		chain[lvl] = null;
		h = q = cast NUL;
	}

	function req(zero: Bool): Ptr {
		var ret = NUL;
		var lop = h;
		while (lop != NUL) {
			if (lop.avail > 0 || lop.frags > 0) {
				ret = lop.request();
				if (zero) Ram.memset(ret, 0, lvl2Size(lvl) - 1);
				break;
			} else if(q == lop) {
				add(new MiniNode(lvl));
			}
			lop = lop.next;
		}
		return ret;
	}

	function which(p: Ptr): MiniNode {
		var lop = h;
		while (lop != NUL) {
			if (lop.here(p)) {
				return lop;
			}
			lop = lop.next;
		}
		return cast NUL;
	}

	/////////////// static ///////////////

	static var chain: haxe.ds.Vector<Mini>;

	// Note: size: [0~7]=>8, [8~15] => 16, ...
	public static function malloc(req_size: UInt, zero:Bool): Ptr {
		if (chain == null)
			chain = new haxe.ds.Vector(LVL_MAX + 1); // begin at 1, first item always null

		var size = nextMultOf8(req_size);

		var lvl = size2Lvl(size);

		if (lvl > LVL_MAX)
			return Ram.malloc(req_size, zero);

		if (chain[lvl] == null)
			chain[lvl] = new Mini(lvl);

		return chain[lvl].req(zero);
	}

	public static function free(chunk: Ptr): Void {
		if (chain != null) {
			var lvl = getLvl(chunk);
			if (lvl > 0 &&  lvl <= LVL_MAX) {
				var node = chain[lvl];
				if (node != null) {
					var bx = node.which(chunk);
					if (bx != NUL && valid(chunk, bx, lvl)) {
						return bx.release(chunk);
					}
				}
			}
		}
		Ram.free(chunk);
	}

	// Note: [0~8]=>8, [9~16] => 16
	public static function preFill(min, max, bulk) {
		if (chain == null)
			chain = new haxe.ds.Vector(LVL_MAX + 1);
		if (min < 8) min = 8;
		if (!Ut.divisible(min, GROW)) min = nextMultOf8(min);
		if (!Ut.divisible(max, GROW)) max = nextMultOf8(max);
		if (max < min) max = min;

		while (min <= max) {
			var lvl = size2Lvl(min);

			if (lvl > LVL_MAX) break;

			var node = chain[lvl];
			if (node == null) {
				chain[lvl] = new Mini(lvl);
				node = chain[lvl];
			}
			var j = bulk;
			while (j > 1) {
				node.add(new MiniNode(lvl));
			-- j;
			}
		min += GROW;
		}
	}

	public static function dump(lvl = -1) {
		var total = 0.0;
		var start = 1;
		var end = chain.length;

		if (lvl > 0 && lvl <= LVL_MAX) {
			start = lvl;
			end = lvl + 1;
		}

		for (i in start...end) {
			var node = chain[i];
			if (node == null) continue;
			trace('----- lvl: $i, chunk width: ${lvl2Size(i)} -----');
			var lop = node.h;
			var j = 0;
			while (lop != NUL) {
				total += (MiniNode.DATA_SIZE + MiniNode.CAPACITY);
				trace('Node: $j, Available: ${lop.avail}, Fragments: ${lop.frags}, Caret: ${lop.caret}');
			++ j;
			lop = lop.next;
			}
		}
		if (start == 1 && end == chain.length)
			trace('total: ${Ut.toFixed(total / 1024, 2)}KB');
	}

	static inline var LVL_MAX = 16;

	static inline var GROW = 8;
	public static inline function lvl2Size(lvl) return lvl << 3; // eq: lvl * GROW
	public static inline function size2Lvl(size) return size >> 3;
	// ([0~7] => 8), ([8~15] => 16), (16 => 24)
	static inline function nextMultOf8(x) return x + GROW - (x & (GROW - 1));

	static inline function getLvl(p: Ptr) return p[-1] >> 1;     // Memory.getByte(p - 1) >> 1;

	static inline function valid(p: Ptr, bx: MiniNode, lvl: Int): Bool
		return (p - bx.entry) % lvl2Size(lvl) == 0;
}


@:enum private abstract UseState(Int) to Int {
	var NO  = 0;
	var YES = 1;
}

@:enum private abstract MetaFLAGS(Int) to Int {
	var IN_USING = 0;
}

/**
Layout:
 +----- MiniNode(size = 8) ----+
 | [0~3]: next                 |
 | [...]:                      |
 | [ 15]:  (lvl << 1)          |
 | +----- Chunk_8 ------+      |
 | |[0~6]: USER DATA    |      |
 | |[ 7 ]: (lvl << 1) | USED   |
 | +--- next Chunk8 ----+      |
 | |[0~6]:              |      |
 | |[ 7 ]: (lvl << 1) | USED   |
 | +--- next Chunk8 ----+      |
 . |                    |      .
 +-----------------------------+
*/

#if !macro
@:build(mem.Struct.StructBuild.make())
#end
@:allow(mem.Mini) abstract MiniNode(Ptr) to Ptr {

	@idx    var next: MiniNode;

	@idx(2) var avail: Int; // available
	@idx(2) var frags: Int; // fragments

	@idx(2) var caret: Int;
	@idx(2) var unk_0: Int;

	@idx(2) var unk_1: Int;
	@idx(1) var lvl: Int;
	@idx(1) var lvlA: Int;

	public var entry(get, never): Ptr;
	inline function get_entry() return this + OFFSET_END;

	// lvl is Multiples of 8, [8, 16, 24, 32, ..., 128].length == 16
	public function new(v: Int) {
		this = Ram.malloc(DATA_SIZE + CAPACITY, true);
		avail = Std.int(DATA_SIZE / Mini.lvl2Size(v));
		lvl = v;
		lvlA = v << 1;
	}

	public inline function free() Ram.free(this);

	public inline function here(chunk: Ptr): Bool
		return entry <= chunk && (entry + DATA_SIZE) > chunk;

	function request(): Ptr {
		var ret: Ptr = NUL;
		var width = Mini.lvl2Size(lvl);
		var offset = caret;

		if (frags == 0) {
			ret = entry + offset;
			ret[width - 1] = lvlA | 1; // mark the "new chunk"

			offset += width;
			caret = offset;
			avail = avail - 1;         // "avail -= 1" will be generate more temp variables.
		} else {
			var start = entry;
			var end = start + offset;
			while (start < end) {
				var meta:ABit = cast (start + width - 1);
				if (meta[IN_USING] == NO) {
					frags = frags - 1;
					meta[IN_USING] = YES;
					return start;
				}
				start += width;
			}
			throw "TODO";
		}
		return ret;
	}

	function release(p: Ptr) {

		var width = Mini.lvl2Size(lvl);

		var meta:ABit = cast (p + width - 1);

		if (meta[IN_USING] == NO )
			return;

		meta[IN_USING] = NO;

		var cf = frags;
		var ca = avail;

		++ cf;

		var end = entry + caret;
		while (cf > 0) {
			meta = cast (end - 1);
			if (meta[IN_USING] == NO) {
				end -= width;
				--cf;
				++ca;
			} else {
				break;
			}
		}
		caret = end - entry;
		frags = cf;
		avail = ca;
	}

	static inline var DATA_SIZE = 4096;
}
