package raw;

import raw.Ptr;

/**
--- [Block] CAPACITY: 8, OFFSET_FIRST: 0, OFFSET_END: 8
--- baseAddr: xx, Allocter: Raw
offset: [0x0000 - 0x0004), bytes:  4, psize: 0
offset: [0x0004 - 0x0008), bytes:  4, _size: 128
offset: [0x0007 - 0x0008), bytes:  1, _freeb: 0
*/
#if !macro
@:build(raw.Struct.make())
#end
@:allow(raw.Malloc)
@:dce
abstract Block(Ptr) to Ptr {
	@idx(4) var psize: Int;       // size of prev block
	@idx(4) var _size: Int;       // size of this block(31bit)
	@idx(1, -1) var _freeb: Int;  // union with _size;

	public var size(get, set): Int;
	inline function get_size(): Int return _size & 0x7FFFFFFF;
	inline function set_size(i: Int): Int {
		_size = (_size & 0x80000000) | (i & 0x7FFFFFFF);
		return i;
	}

	public var is_free(get, set): Bool;
	inline function get_is_free(): Bool return (_freeb & 0x80) == 0x80;
	inline function set_is_free(b: Bool): Bool {
		_freeb = b ? (0x80 | _freeb) : (0x7F & _freeb);
		return b;
	}

	public var entry(get, never): Ptr;
	inline function get_entry(): Ptr return this + OFFSET_END;

	public var entrySize(get, never):Int;
	inline function get_entrySize():Int return size - CAPACITY;

	public inline function prev() :Block return new Block(this - psize);
	public inline function next() :Block return new Block(this + size);

	public inline function new(block_addr: Ptr) this = block_addr;

	inline function setup(block_size: Int, clear: Bool): Void {
		Raw.memset(this, 0, (clear ? block_size : CAPACITY));
		_size = block_size;
	}

	public inline function free() Malloc.free(entry); // override created by macro

	public inline function toString() {
		return 'size: $size, psize: $psize, free: $is_free, address: ${this.toInt()}';
	}
}

class Malloc {
	static var first: Block = cast Ptr.NUL;
	static var last : Block = cast Ptr.NUL;

	public static var frag_count(default, null):Int = 0;
	public static var length(default, null):Int = 0;

	public static inline function getUsed(): Int {
		return isEmpty() ? 16 : (last: Ptr).toInt() + last.size;
	}

	public static inline function isEmpty() {
		return first == Ptr.NUL;
	}

	public static inline function isFirst(b) {
		return !isEmpty() && b == first; // b.psize == 0 ??
	}

	public static inline function isLast(b) {
		return !isEmpty() && b == last;
	}

	static function clear() {
		first = cast Ptr.NUL;
		last = cast Ptr.NUL;
		frag_count = 0;
		length = 0;
	}

	static function add(b: Block) {
		if (isEmpty()) {
			// b.psize = 0;
			first = b;
		} else {
			b.psize = last.size;
			if (b.prev() != last) throw "TODO";
		}
		last = b;
		++ length;
	}

	static function split(b: Block, size: Int): Bool {
		var bsize = b.size;
		if (bsize >= (size << 1)) {                   // double
			b._size = size;                           // clear free
			var next = b.next();
			next._size = 0x80000000 | (bsize - size); // set free
			next.psize = size;

			if (last == b) {
				last == next;
			} else {
				next.next().psize = bsize - size;
			}
			++ length;
			return true;
		}
		return false;
	}

	static function indexOf(entry: Ptr):Block {
		if (entry - Block.CAPACITY > Ptr.NUL) {
			var b: Block = new Block(entry - Block.CAPACITY);
			if (b == last || b == first) return b;
			if ((b: Ptr) < (last: Ptr)) {
				var prev = b.prev(), next = b.next();
				if (prev.next() == b && next.prev() == b) return b;
			}
		}
		return cast Ptr.NUL;
	}

	public static inline function free(p: Ptr) blockFree(indexOf(p));

	static inline var LB = 8;
	public static function make(req_size: Int, zero: Bool, pb: Int): Ptr {
		pb = pb <= LB ? LB : Ut.nextPow(pb);
		req_size = Ut.align(req_size & 0x7FFFFFFF, pb);

		var block: Block = cast Ptr.NUL;
		var tmp_frag_count = frag_count;
		var entrySize = 0;
		var cc: Block = first;
		while (tmp_frag_count > 0 && cc != last) {
			if (cc.is_free) {
				entrySize = cc.entrySize;
				if (entrySize == req_size) {
					block = cc;
					break;
				} else if (block == Ptr.NUL && entrySize > req_size) {
					block = cc;
				}
				-- tmp_frag_count;
			}
			cc = cc.next(); // the "last" is not be "free"
		}

		if (block == Ptr.NUL) {
			var blockAddr = getUsed();
			@:privateAccess Raw.reqCheck(blockAddr + req_size + Block.CAPACITY);
			block = new Block(Ptr.ofInt(blockAddr));
			block.setup(req_size, zero);
			add(block);
		} else if(!split(block, req_size + Block.CAPACITY)) {
			block.is_free = false;
			-- frag_count;
		}
		return block.entry;
	}

	static function blockFree(b: Block) {
		if (b == Ptr.NUL || last == Ptr.NUL || b.is_free) return;
		b.is_free = true;
		++ frag_count;
		if (b != last) return;
		while (last.is_free) {
			if (last == first) {
				last = cast Ptr.NUL;
				first = cast Ptr.NUL;
			} else {
				last = last.prev();
			}
			-- length;
			-- frag_count;
		}
	}

	static function iterator(): BlockIterator {
		return new BlockIterator(first);
	}

	public static function toString() {
		return 'Malloc: [Blocks: $length, Frags: $frag_count, isEmpty: ${isEmpty()}, check: ${simpleCheck()}]';
	}

	public static function simpleCheck() {
		var i = 0;
		var frags = 0;
		for (b in Malloc) {
			if (b != first) {
				var prev = b.prev();
				if (prev.next() != b) return false;
			}
			if (b != last) {
				var next = b.next();
				if (next.prev() != b) return false;
			}
			if (b.is_free) ++ frags;
			++i;
		}
		return i == length && frags == frag_count;
	}
}

class BlockIterator {

	var hd: Block;

	public inline function new(first:Block) hd = first;

	public inline function hasNext(): Bool @:privateAccess {
		return !Malloc.isEmpty() && (hd: Ptr) <= (Malloc.last: Ptr);
	}

	public inline function next(): Block {
		var b = hd;
		hd = hd.next();
		return b;
	}
}