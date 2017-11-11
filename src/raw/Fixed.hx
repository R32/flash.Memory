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
		var diff;
		while (cur != Ptr.NUL) {
			diff = p.toInt() - chunk_data_ptr(cur).toInt();
			if (diff >= 0 && diff < ct * sz && diff % sz == 0) {
				release(cur, Std.int(diff / sz));
				break;
			}
			cur = cur.next;
		}
	}

	function new(sz, bulk) {
		this.sz = sz;
		this.ct = (bulk & 2047) << 5;
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

	function TRAILING_ONES(x) {
		// if (x == 0xFFFFFFFF) return 32;
		x = ~x;
		var n = 0;
		if ((x & 0x0000FFFF) == 0) {
			n += 16;
			x >>= 16;
		}
		if ((x & 0x000000FF) == 0) {
			n += 8;
			x >>= 8;
		}
		if ((x & 0x0000000F) == 0) {
			n += 4;
			x >>= 4;
		}
		if ((x & 0x00000003) == 0) {
			n += 2;
			x >>= 2;
		}
		if ((x & 0x00000001) == 0) {
			n += 1;
		}
		return n;
	}

	// ------ ChunkHelps ------
	inline function meta_bytes(n) return (n >> 3);
	inline function meta_pos(ci) return ((ci >> 3) & 0xFFFC);
	inline function chunk_data_ptr(c: Chunk) return (c: Ptr) + Chunk.CAPACITY + meta_bytes(ct);
	inline function chunk_piece_ptr(c: Chunk, ci: Int) return chunk_data_ptr(c) + ci * sz;
	inline function chunk_rest(c: Chunk) return ct - c.caret + c.frags;
	inline function chunk_detail(c: Chunk): String {
		return 'SIZEOF: $sz, COUNT: $ct, frags: ${c.frags}, caret: ${c.caret}, rest: ${chunk_rest(c)}';
	}

	function in_using(p: Ptr, caret: Int, t: Bool) {
		p = p + meta_pos(caret);
		if (t) {
			Memory.setI32(p, (1 << (caret & 31)) | Memory.getI32(p));
		} else {
			Memory.setI32(p, (~(1 << (caret & 31))) & Memory.getI32(p));
		}
	}

	function is_free(p: Ptr, caret: Int) {
		return ((Memory.getI32(p + meta_pos(caret)) >> (caret & 31)) & 1) == 0;
	}

	// make sure "c.caret < ct || c.frags > 0"
	function request(c: Chunk, z: Bool): Ptr {
		var ret = raw.Ptr.NUL;
		var cr = c.caret;
		var meta = c.meta;
		if (cr < ct) {
			ret = chunk_piece_ptr(c, cr);
			in_using(meta, cr, true);
			c.caret = cr + 1;
		} else {
			var i = 0, value = 0, len = meta_pos(ct);
			while (i < len) {
				value = Memory.getI32(meta + i);
				if (value != 0xFFFFFFFF) {
					cr = (i << 3) + TRAILING_ONES(value);
					in_using(meta, cr, true);
					c.frags = c.frags - 1;
					ret = chunk_piece_ptr(c, cr);
					break;
				}
				i += 4;
			}
		}
		if (z) Raw.memset(ret, 0, sz);
		return ret;
	}

	function release(c: Chunk, cr: Int) {
		var meta = c.meta;
		if (is_free(meta, cr)) return;
		in_using(meta, cr, false);
		var fg = c.frags + 1;
		cr = c.caret - 1;
		while (fg > 0 && is_free(meta, cr)) {
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
		this = Raw.malloc(CAPACITY + (count >> 3) + count * sizof, false);
		Raw.memset(this, 0, CAPACITY + (count >> 3)); // .next = 0, .frags = 0, .caret = 0;
	}

	public static inline var CAPACITY = 8;
}
