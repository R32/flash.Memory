package raw;

import raw.Ptr;
/**
This Class is auto called by macro.
*/
class Fixed {

	var h: Chunk;
	var q: Chunk;

	var ct: Int; // COUNT
	var sz: Int; // SIZEOF

	public function malloc(x: Int, z: Bool): Ptr {
		var ret = Ptr.NUL;
		var cur = h;
		while (cur != Ptr.NUL) {
			if (cur.caret < ct || cur.frags > 0) {
				ret = request(cur, z);
				break;
			}
			cur = cur.next;
		}
		if (ret == Ptr.NUL) { // create a new chunk
			var c = new Chunk(ct, sz);
			add(c);
			ret = request(c, z);
		}
		return ret;
	}

	public function free(p: Ptr): Void {
		var cur = h;
		while (cur != Ptr.NUL) {
			if (valid(cur, p)) {
				release(cur, p);
				break;
			}
			cur = cur.next;
		}
	}

	function new(sz, ct) {
		this.sz = sz;
		this.ct = ct;
		this.h = cast raw.Ptr.NUL;
	}

	function add(c: Chunk) {
		if (h == Ptr.NUL)
			h = c;
		else
			q.next = c;
		q = c;
	}

	function destory() {
		var cur = h;
		while (cur != Ptr.NUL) {
			var prev = cur;
			cur = cur.next;
			Raw.free(prev);
		}
		h = cast Ptr.NUL;
	}

	function toString() {
		var n = 0;
		var r = 0;
		var cur = h;
		while (cur != Ptr.NUL) {
			++ n;
			r += chunk_rest(cur);
			cur = cur.next;
		}
		return '[chunk: $n, total: ${n * (Chunk.CAPACITY + ct + ct * sz)}B, used: ${n * ct - r}, rest: $r]';
	}

	// ------ ChunkHelps ------

	inline function chunk_entry(c: Chunk) return (c: Ptr) + Chunk.CAPACITY + ct;
	inline function chunk_rest(c: Chunk) return ct - c.caret + c.frags;
	inline function chunk_detail(c: Chunk): String {
		return 'SIZEOF: $sz, COUNT: $ct, frags: ${c.frags}, caret: ${c.caret}, rest: ${chunk_rest(c)}';
	}

	function valid(c: Chunk, p: Ptr) {
		var diff = p.toInt() - chunk_entry(c).toInt();
		return diff >= 0 && diff < ct * sz && diff % sz == 0;
	}

	// make sure "c.caret < ct || c.frags > 0"
	function request(c: Chunk, z: Bool): Ptr {
		var ret = raw.Ptr.NUL;
		var cr = c.caret;
		var fg = c.frags;
		var meta = c.meta;
		if (cr < ct) {
			ret = chunk_entry(c) + cr * sz;
			meta[cr] = 1;
			c.caret = cr + 1;
		} else {
			for (i in 0...ct) { // in bytes, TODO: not performance..
				if( meta[i] == 0) {
					meta[i] = 1;
					c.frags = fg - 1;
					ret = chunk_entry(c) + i * sz;
					break;
				}
			}
		}
		//if (ret == Ptr.NUL) throw "TODO";
		if (z) Raw.memset(ret, 0, sz);
		return ret;
	}

	function release(c: Chunk, p: Ptr) {
		var i = Std.int((p.toInt() - chunk_entry(c).toInt()) / sz);
		var meta = c.meta;
		if (meta[i] == 0) return;
		meta[i] = 0;
		var fg = c.frags + 1;
		var cr = c.caret - 1; // last elem. same as `a[a.length - 1]`
		//if (cr < 0) throw "TODO";
		while (fg > 0 && meta[cr] == 0) {
			-- cr;
			-- fg;
		}
		c.frags = fg;
		c.caret = cr + 1;
	}
}

/*
0x00 ~ 0x04: Ptr to   next,
0x04 ~ 0x06: uint16_t frags
0x06 ~ 0x08: uint16_t caret

capacity: 8
*/
@:allow(raw.Fixed)
extern abstract Chunk(Ptr) to Ptr {
	public var next(get, set): Chunk;    // 4 bytes
	inline function get_next(): Chunk return cast Memory.getI32(this);
	inline function set_next(c: Chunk): Chunk {
		Ptr.Memory.setI32(this, cast c);
		return c;
	}

	public var frags(get, set): Int;     // 2 bytes
	inline function get_frags(): Int return Ptr.Memory.getUI16(this + 4);
	inline function set_frags(v: Int): Int { Ptr.Memory.setI16(this + 4, v); return v; }

	public var caret(get, set): Int;     // 2 bytes
	inline function get_caret(): Int return Ptr.Memory.getUI16(this + 6);
	inline function set_caret(v: Int): Int { Ptr.Memory.setI16(this + 6, v); return v; }

	public var meta(get, never): Ptr;
	inline function get_meta(): Ptr return this + CAPACITY;

	inline function new(count: Int, sizof: Int) {
		this = Raw.malloc(CAPACITY + count + count * sizof, false);
		Raw.memset(this, 0, CAPACITY + count); // .next = 0, .frags = 0, .caret = 0;
	}

	public static inline var CAPACITY = 8;
}
