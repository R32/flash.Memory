package mem;

import mem.Ptr;

/**
Fixed size memory allocator.
*/
class Fixed {

	var h: Chunk;
	var q: Chunk;

	var ct: Int; // COUNT
	var sz: Int; // SIZEOF

	public function malloc(z = false): Ptr {
		var ret = Ptr.NUL;
		var cur = h;
		while (cur != Ptr.NUL) {
			if (cur.caret < ct || cur.frags > 0) {
				ret = req(cur, z);
				break;
			}
			cur = cur.next;
		}
		if (ret == Ptr.NUL) { // create a new chunk
			var c = new Chunk(ct, sz);
			add(c);
			ret = req(c, z);
		}
		return ret;
	}

	public function free(p: Ptr): Void {
		var cur = h;
		while (cur != Ptr.NUL) {
			var diff: Int = p - chunk_data_ptr(cur);
			if (diff >= 0 && diff < ct * sz && diff % sz == 0) {
				release(cur, Std.int(diff / sz));
				break;
			}
			cur = cur.next;
		}
	}

	/**
	* @param sz: a block sizeof
	* @param bulk: 1 bulk == 32 blocks that stored in a single chunk. bulk is limit to 2047
	*/
	public function new(sz, bulk) {
		this.sz = sz;
		this.ct = (bulk & 2047) << 5;
		h = q = cast Ptr.NUL;
	}

	function destory() {
		var cur = h;
		while (cur != Ptr.NUL) {
			var prev = cur;
			cur = cur.next;
			Mem.free(prev);
		}
		h = q = cast Ptr.NUL;
	}

	function add(c: Chunk) {
		if (h == Ptr.NUL)
			h = c;
		else
			q.next = c;
		q = c;
	}
	// How many bytes are needed to store the meta
	static inline function meta_bytes(n) return (n >> 3);
	// ------ ChunkHelps ------
	inline function chunk_data_ptr(c: Chunk):Ptr return (c: Ptr) + Chunk.CAPACITY + meta_bytes(ct);
	inline function chunk_piece_ptr(c: Chunk, ci: Int):Ptr return chunk_data_ptr(c) + ci * sz;

	function STATUS(meta: Ptr, pos: Int, t: Bool) {
		var b = meta + meta_bytes(pos);
		if (t) {
			b.setByte((1 << (pos & 7)) | b.getByte());
		} else {
			b.setByte((~(1 << (pos & 7))) & b.getByte());
		}
	}

	function is_free(meta: Ptr, pos: Int) {
		return ((meta + meta_bytes(pos)).getByte() >> (pos & 7)) & 1 == 0;
	}

	// make sure "c.caret < ct || c.frags > 0"
	function req(c: Chunk, z: Bool): Ptr {
		var ret = Ptr.NUL;
		var cr = c.caret;
		var meta = c.meta;
		if (cr < ct) {
			ret = chunk_piece_ptr(c, cr);
			STATUS(meta, cr, true);
			c.caret = cr + 1;
		} else {
			var i = 0, len = meta_bytes(ct);
			while (i < len) {
				cr = Ut.TRAILING_ONES((meta + i).getI32());
				if (cr != 32) {
					cr += (i << 3);
					STATUS(meta, cr, true);
					c.frags = c.frags - 1;
					ret = chunk_piece_ptr(c, cr);
					break;
				}
				i += 4;
			}
		}
		if (z) Mem.memset(ret, 0, sz);
		return ret;
	}

	function release(c: Chunk, cr: Int) {
		var meta = c.meta;
		if (is_free(meta, cr)) return;
		STATUS(meta, cr, false);
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

/**
* should be used with Fixed.
*/
@:allow(mem.Fixed)
extern abstract Chunk(Ptr) to Ptr {
	var next(get, set): Chunk;  // 4 bytes, for link with List
	var frags(get, set): Int;   // 2 bytes, how many frags in current chunk
	var caret(get, set): Int;   // 2 bytes,
	var meta(get, never): Ptr;  // a flexible field. logged whether the block is free

	private inline function get_next():Chunk return cast this.getI32();
	private inline function get_frags():Int return (this + 4).getUI16();
	private inline function get_caret():Int return (this + 6).getUI16();
	private inline function get_meta():Ptr return this + CAPACITY;

	private inline function set_next(c: Chunk): Chunk {
		this.setI32(cast c);
		return c;
	}
	private inline function set_frags(v: Int): Int {
		(this + 4).setI16(v);
		return v;
	}
	private inline function set_caret(v: Int): Int {
		(this + 6).setI16(v);
		return v;
	}
	private inline function new(count: Int, sizof: Int) {
		//        chunk_header(8) + byte_len(meta) + (sizeof(data) * count)
		this = Mem.malloc(CAPACITY + (count >> 3) + count * sizof, false);
		Mem.memset(this, 0, CAPACITY + (count >> 3));
	}

	public static inline var CAPACITY = 8;
}
