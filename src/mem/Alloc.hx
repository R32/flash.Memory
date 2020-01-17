package mem;

import mem.Ptr;

private extern abstract Header(Ptr) to Ptr {
	var __free(get, set): Int;   // union with __size.   [0x0000 - 0x0001]
	var __size(get, set): Int;   // size of this Header. [0x0000 - 0x0003]
	var is_free(get, set): Bool; // reference to __free
	var size(get, set): Int;     // reference to __size
	var entry(get, never): Ptr;
	var entrySize(get, never):Int;

	var free_next(get, set): Header; //

	inline function next():Header return cast this + size;
	inline function new(ptr: Ptr) this = ptr;

	private inline function get___free():Int return this.getByte();
	private inline function get___size():Int return this.getI32();
	private inline function get_size():Int return __size & (0xFFFFFFFE); // i32(~1) == 0xFFFFFFFE
	private inline function get_is_free():Bool return (__free & 1) == 0; // 0 == free
	private inline function get_entry():Ptr return this + CAPACITY;
	private inline function get_entrySize():Int return size - CAPACITY;
	private inline function get_free_next():Header return cast entry.getI32();

	private inline function set___size(v: Int): Int {
		this.setI32(v);
		return v;
	}
	private inline function set___free(v: Int): Int {
		this.setByte(v);
		return v;
	}
	private inline function set_size(i: Int): Int {
		__size = i | (__free & 1);
		return i;
	}
	private inline function set_is_free(b: Bool): Bool {
		__free = b ? (0xFE & __free) : (1 | __free);
		return b;
	}

	private inline function set_free_next(h: Header): Header {
		entry.setI32(cast h);
		return h;
	}

	static inline function init(h: Header, bsize: Int, clear: Bool): Void {
		if (clear)
			Mem.memset(h, 0, bsize);
		h.__size = bsize | 1;  // `.free = false` for new Header()
	}

	static inline var CAPACITY = 4;
}

class Alloc {

	static var first: Header = cast Ptr.NUL;
	static var last: Header = cast Ptr.NUL;
	static var hfree_a: Array<Header> = cast [0, 0, 0, 0, 0, 0, 0, 0]; // length = (FREE_MAX + 1)

	static inline function hfree_index(bsize:Int) : Int {
		return (((bsize - Header.CAPACITY) >>> LBITS) - 1) & FREE_MAX;
	}

	static inline function hfree_add(h:Header) {
		var i = hfree_index(h.size);
		h.free_next = hfree_a[i];
		hfree_a[i] = h;
	}

	static public var frags(default, null): Int = 0;
	static public var length(default, null): Int = 0;

	static public inline function isEmpty() return first == Ptr.NUL;

	static public inline function used(): Int {
		return isEmpty() ? ADDR_START : ((last: Ptr).toInt() + last.size);
	}

	static inline function ALIGN_LB(size:Int) return ((size - 1) | (LB - 1)) + 1; // multiple of LB

	static public function req(size: Int, zero: Bool): Ptr {
		if (size <= LB) {
			size = LB;
		} else {
			size = ALIGN_LB(size);
		}
		var bsize = size + Header.CAPACITY;
		var h = hfree_frags(bsize);
		if (h == Ptr.NUL) {
			var addr = used();
			Mem.grow(addr + bsize);
			h = new Header(cast addr);
			Header.init(h, bsize, zero);
			if ( isEmpty() )
				first = h;
			last = h;
			++ length;
		} else {
			h.is_free = false;
			-- frags;
		}
		return h.entry;
	}

	static function hfree_frags(bsize: Int): Header {
		var i = hfree_index(bsize);
		var cur = hfree_a[i];
		if (cur == cast Ptr.NUL)
			return cur;
		if (i == FREE_MAX) {
			var prev: Header = cast Ptr.NUL;
			do {
				if (cur.size >= bsize) {
					if (prev == cast Ptr.NUL) { // if first element
						hfree_a[i] = cur.free_next;
					} else {
						prev.free_next = cur.free_next;
					}
					break;
				}
				prev = cur;
				cur = cur.free_next;
			} while (cur != cast Ptr.NUL);
		} else {
			hfree_a[i] = cur.free_next;
		}
		return cur;
	}

	static function hd(entry: Ptr): Header {
		if (entry.toInt() >= (ADDR_START + Header.CAPACITY)) {
			var h: Header = new Header(entry - Header.CAPACITY);
			if ( h == last || h == first || (h:Ptr) < (last:Ptr) )
				return h;
		}
		return cast Ptr.NUL;
	}

	static public function free(h: Header): Void {
		if (isEmpty() || h == Ptr.NUL || h.is_free) return;
		h.is_free = true;
		++ frags;
		hfree_add(h);
		if (frags == length) { // reset
			last = cast Ptr.NUL;
			first = cast Ptr.NUL;
			for (i in 0...(FREE_MAX + 1))
				hfree_a[i] = cast Ptr.NUL;
			frags = 0;
			length = 0;
		}
	}

	static public function simpleCheck() {
		var i = 0;
		var fs = 0;
		if (first != Ptr.NUL) {
			var h = first;
			while (true) {
				++ i;
				if (h.is_free)
					++fs;
				if ((h:Ptr) < (last:Ptr)) {
					var next = h.next();
					h = next;
				} else {
					break;
				}
			}
		}
		return i == length && fs == frags;
	}

	static inline var LB = 16;
	static inline var LBITS = 4;        // 1 << 4 == 16
	static inline var FREE_MAX = (8-1); // 0b111
	static inline var ADDR_START = 32;
}
