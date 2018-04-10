package raw;

import raw.Ptr;

#if !macro
@:build(raw.Struct.make())
#end
@:allow(raw.Malloc)
extern abstract Block(Ptr) to Ptr {
	@idx(4,  0) var psize: Int; // size of prev block. [0x0000 - 0x0004)
	@idx(1,  0) var _free: Int; // union with _size.   [0x0004 - 0x0005)
	@idx(4, -1) var _size: Int; // size of this block. [0x0004 - 0x0008)

	public var size(get, set): Int;
	inline function get_size(): Int return _size & (0xFFFFFFFE); // i32(~1) == 0xFFFFFFFE
	inline function set_size(i: Int): Int {
		_size = i | (_free & 1);
		return i;
	}

	public var is_free(get, set): Bool;
	inline function get_is_free(): Bool return (_free & 1) == 0; // 0 == free
	inline function set_is_free(b: Bool): Bool {
		_free = b ? (0xFE & _free) : (1 | _free);
		return b;
	}

	public var entry(get, never): Ptr;
	inline function get_entry(): Ptr return this + OFFSET_END;

	public var entrySize(get, never):Int;
	inline function get_entrySize():Int return size - CAPACITY;

	public inline function prev() :Block return new Block(this - psize);
	public inline function next() :Block return new Block(this + size);

	public inline function new(block_addr: Ptr) this = block_addr; // override

	inline function init(block_size: Int, clear: Bool): Void {
		Raw.memset(this, 0, (clear ? block_size : CAPACITY));
		_size = block_size | 1;  // `.free = false` for new block
	}

	public inline function free():Void Malloc.free(entry);         // override created by macro

	public inline function toString():String {
		return 'size: $size, psize: $psize, free: $is_free, address: ${this.toInt()}';
	}
}

class Malloc {
	static var first: Block = cast Ptr.NUL;
	static var last : Block = cast Ptr.NUL;

	public static var frag_count(default, null):Int = 0;
	public static var length(default, null):Int = 0;

	public static inline function getUsed(): Int {
		return isEmpty() ? ADDR_START : (last: Ptr).toInt() + last.size;
	}

	public static inline function isEmpty() return first == Ptr.NUL;

	static inline function add(b: Block) {
		if (isEmpty()) {
			// b.psize = 0;
			first = b;
		} else {
			b.psize = last.size; // same as: b.prev = last;
		}
		last = b;
		++ length;
	}

	static function split(b: Block, size: Int): Bool {
		var bsize = b.size;
		if (bsize >= (size << 1)) {     // if double
			b._size = 1 | size;         // reset b.size and then b.free = false;
			var next = b.next();
			next._size = bsize - size;  // next.size and then next.free = true;
			next.psize = size;          // next.prev = b
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
		if (entry.toInt() >= (ADDR_START + Block.CAPACITY)) {
			var b: Block = new Block(entry - Block.CAPACITY);
			if (b == last || b == first) return b;
			if ((b: Ptr) < (last: Ptr)) {
				var prev = b.prev(), next = b.next();
				if (prev.next() == b && next.prev() == b) return b;
			}
		}
		return cast Ptr.NUL;
	}

	public static function free(p: Ptr) {
		var b = indexOf(p);
		if (b == Ptr.NUL || last == Ptr.NUL || b.is_free) return;
		b.is_free = true;
		++ frag_count;
		while (last.is_free) {
			-- length;
			-- frag_count;
			if (last == first) {
				last = cast Ptr.NUL;
				first = cast Ptr.NUL;
				break;
			} else {
				last = last.prev();
			}
		}
	}

	static inline var LB = 8;
	static inline var ADDR_START = 16;
	public static function make(req_size: Int, zero: Bool, pb: Int): Ptr {
		pb = pb <= LB ? LB : Ut.nextPow(pb);
		req_size = Ut.align(req_size, pb);

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
			block.init(req_size + Block.CAPACITY, zero);
			add(block);
		} else if (split(block, req_size + Block.CAPACITY) == false) {
			block.is_free = false;
			-- frag_count;
		}
		return block.entry;
	}
	#if debug
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
	#end
}
#if debug
@:dce class BlockIterator {

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
#end