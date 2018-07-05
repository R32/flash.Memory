package mem;

import mem.Ptr;

private extern abstract Header(Ptr) to Ptr {
	var __free(get, set): Int;   // union with __size.   [0x0000 - 0x0001]
	var __size(get, set): Int;   // size of this Header. [0x0000 - 0x0003]
	var psize(get, set): Int;    // size of prev Header. [0x0004 - 0x0007]
	var is_free(get, set): Bool; // reference to __free
	var size(get, set): Int;     // reference to __size
	var entry(get, never): Ptr;
	var entrySize(get, never):Int;

	inline function prev():Header return new Header(this - psize);
	inline function next():Header return new Header(this + size);
	inline function new(ptr: Ptr) this = ptr;

	private inline function get___free():Int return this.getByte();
	private inline function get___size():Int return this.getI32();
	private inline function get_psize():Int return (this + 4).getI32();
	private inline function get_size():Int return __size & (0xFFFFFFFE); // i32(~1) == 0xFFFFFFFE
	private inline function get_is_free():Bool return (__free & 1) == 0; // 0 == free
	private inline function get_entry():Ptr return this + CAPACITY;
	private inline function get_entrySize():Int return size - CAPACITY;

	private inline function set___size(v: Int): Int {
		this.setI32(v);
		return v;
	}
	private inline function set___free(v: Int): Int {
		this.setByte(v);
		return v;
	}
	private inline function set_psize(v: Int): Int {
		(this + 4).setI32(v);
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

	static inline function init(h: Header, bsize: Int, clear: Bool): Void {
		Mem.memset(h, 0, (clear ? bsize : CAPACITY));
		h.__size = bsize | 1;  // `.free = false` for new Header()
	}

	static inline var CAPACITY = 8;
}

class Alloc {

	static var first: Header = cast Ptr.NUL;
	static var last: Header = cast Ptr.NUL;

	static public var frags(default, null): Int = 0;
	static public var length(default, null): Int = 0;

	static public inline function isEmpty() return first == Ptr.NUL;

	static public inline function used(): Int {
		return isEmpty() ? ADDR_START : ((last: Ptr).toInt() + last.size);
	}

	static public function req(size: Int, z: Bool, pad: Int): Ptr {
		pad = pad <= LB ? LB : Ut.nextPow(pad);
		var bsize = Header.CAPACITY + Ut.align(size, pad) ;

		var h: Header = frags > 16 ? fromFrags(bsize) : cast Ptr.NUL;

		if (h == Ptr.NUL) {
			var addr: Int = used();
			Mem.grow(addr + bsize);
			h = new Header(Ptr.ofInt(addr));
			Header.init(h, bsize, z);
			add(h);
		} else if (split(h, bsize) == false) {
			h.is_free = false;
			-- frags;
		}
		return h.entry;
	}

	// TODO: Temporary method, later should use "abstract Frag(Ptr){}" instead of it
	static function fromFrags(bsize: Int): Header {
		var ct = frags;
		var h = first;
		while (ct > 0 && h != last) {
			if (h.is_free) {
				if (bsize <= h.size) return h;
				-- ct;
			}
			h = h.next();
		}
		return cast Ptr.NUL;
	}

	static function hd(entry: Ptr): Header {
		if (entry.toInt() >= (ADDR_START + Header.CAPACITY)) {
			var h: Header = new Header(entry - Header.CAPACITY);
			if ( h == last || h == first ) return h;
			if ( (h:Ptr) < (last:Ptr) ) {
				var prev = h.prev();
				var next = h.next();
				if ( prev.next() == h && next.prev() == h ) return h;
			}
		}
		return cast Ptr.NUL;
	}

	static public function free(h: Header): Void {
		if (isEmpty() || h == Ptr.NUL || h.is_free) return;
		h.is_free = true;
		++ frags;
		while (last.is_free) {
			-- length;
			-- frags;
			if (last == first) {
				last = cast Ptr.NUL;
				first = cast Ptr.NUL;
				break;
			} else {
				last = last.prev();
			}
		}
	}

	static function add(h: Header) {
		if (isEmpty()) {
			first = h;
		} else {
			h.psize = last.size;
		}
		last = h;
		++ length;
	}

	static function split(h: Header, bsize: Int): Bool {
		var hsize = h.size;
		if (hsize >= (bsize << 1)) {
			h.__size = 1 | bsize;        // reset h.size and h.free = false
			var next = h.next();
			next.__size = hsize - bsize; // next.size and next.free = true
			next.psize = bsize;          // next.prev = h
			if (last == h) {
				last = next;
			} else {
				next.next().psize = hsize - bsize;
			}
			++ length;
			return true;
		}
		return false;
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
				if (h != last) {
					var next = h.next();
					if (next.prev() != h) return false;
					h = next;
				} else {
					break;
				}
			}
		}
		return i == length && fs == frags;
	}

	static inline var LB = 8;
	static inline var ADDR_START = 32;
}

/**
 hasn't been used yet.

 Double linked list(Weird) for fragments
    ┌─prev──────────────────────────────────────┐
 ┌──┴───┐       ┌──────┐       ┌──────┐       ┌──────┐
 │  FN  │<--prev┤  F3  │<--prev┤  F2  │<--prev┤  F1  │
 │ last ├next-->│      ├next-->│      ├next-->│ tail ├next == NULL
 └──────┘       └──────┘       └──────┘       └──────┘
*/
@:native("mem_frag") private abstract Frag(Ptr) {
	static inline var CAPACITY = 12;
	public var next(get, set): Frag;   // [0 - 3]
	public var prev(get, set): Frag;   // [4 - 7]
	public var data(get, set): Header; // [8 - 11]

	inline function get_next():Frag return cast this.getI32();
	inline function get_prev():Frag return cast (this + 4).getI32();
	inline function get_data():Header return cast (this + 8).getI32();

	inline function set_next(f):Frag {
		this.setI32(cast f);
		return f;
	}
	inline function set_prev(f):Frag {
		(this + 4).setI32(cast f);
		return f;
	}
	inline function set_data(h):Header {
		(this + 8).setI32(cast h);
		return h;
	}

	inline function alone() next = cast this;
	inline function isAlone() return next == cast this;

	static var head:Frag = cast Ptr.NUL;

	static public inline function isEmpty(): Bool return head == cast Ptr.NUL;

	static public function add(f: Frag) {
		if (isEmpty()) {
			f.next = cast Ptr.NUL;
			f.prev = f;
		} else {
			f.next = head;
			f.prev = head.prev;
			head.prev = f;
		}
		head = f;
	}

	static public function push(f: Frag) { // add to tail
		f.next = cast Ptr.NUL;
		if (isEmpty()) {
			f.prev = f;
			head = f;
		} else {
			var tail = head.prev;
			f.prev = tail;
			tail.next = f;
			head.prev = f;
		}
	}

	static public function remove(f: Frag) {
		if (isEmpty()) return;
		if (f == head) {             // head
			if (f == head.prev) {    // singular
				head = cast Ptr.NUL;
			} else {
				head = f.next;
				head.prev = f.prev;
			}
		} else if (f == head.prev) { // tail and f is not head
			var prev = f.prev;
			prev.next = cast Ptr.NUL;
		} else if (!f.isAlone()) {
			var prev = f.prev;
			var next = f.next;
			prev.next = next;
			next.prev = prev;
		}
		f.alone();
	}

	static public function find(check: Frag->Bool): Frag {
		var f = head;
		while (f != cast Ptr.NUL) {
			if (check(f)) break;
			f = f.next;
		}
		return f;
	}
}
