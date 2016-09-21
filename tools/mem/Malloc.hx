package mem;

import mem.Ptr;
import mem.Struct;

/**
e.g:
 --- Block.CAPACITY: 16, addr: 16
offset: 0x00 - 0x04, bytes: 4, size: 24
offset: 0x04 - 0x08, bytes: 4, prev: 0
offset: 0x08 - 0x0C, bytes: 4, next: 0
offset: 0x0C - 0x0D, bytes: 1, is_free: false
offset: 0x0D - 0x0E, bytes: 1, unk_1: 0
offset: 0x0E - 0x0F, bytes: 1, unk_2: 0
offset: 0x0F - 0x10, bytes: 1, unk_3: 0
offset: 0x0C - 0x10, bytes: 4, info: 0

--- entry = (block_addr + CAPACITY), then block_addr = entry - CAPACITY
--- len = (size - CAPACITY)
*/
#if !macro
@:build(mem.Struct.StructBuild.make())
#end
@:dce abstract Block(Ptr) to Ptr {
	@idx(2) var zero: Int;      // 2 bytes, always 0
	@idx(0) var is_free: Bool;  // 1 bytes, if true, will be remove from chain
	@idx(1) var unknown: Int;   // 1 bytes
	@idx(4) var size: Int;      // 4 bytes,
	@idx(0) var prev: Block;    // 4 bytes, Pointer to prev Block, idx(0) is a offset
	@idx(0) var next: Block;    // 4 bytes

	public var entry(get, never):Ptr;
	inline function get_entry():Ptr return this + CAPACITY;

	public var len(get, never):Int;
	inline function get_len():Int return size - CAPACITY;

	inline public function new(address:Ptr, length:Int, clear:Bool) {
		this = address;
		Ram.memset(this, 0, clear ? length + CAPACITY : CAPACITY);
		size = CAPACITY + length;	// Note: must after memset
	}

	inline public function free() @:privateAccess Malloc.freeBlock(cast this);

	@:op(A == B) private static inline function eqInt( a : Block, b : Block ) : Bool
		return (a:Int) == (b:Int);
}
#if cpp
@:nativeGen @:headerCode("#define Mallochx Mallochx_obj") @:native("mem.Mallochx")
#end
class Malloc {

	public static inline var NUL:Ptr = cast 0;
	public static inline var LB = 8;
	#if cpp
	static var top(default, null):Block;
	static var bottom(default, null):Block;
	public static var frag_count(default, null):Int;
	public static var length(default, null):Int;
	public static function __register():Void {}
	#else
	static var top(default, null):Block = cast NUL;
	static var bottom(default, null):Block = cast NUL;
	public static var frag_count(default, null):Int = 0;
	public static var length(default, null):Int = 0;
	#end

	public static function getUsed():Int {
		return bottom == NUL ? 16 : bottom.entry + bottom.size; // Reserve 16 bytes
	}

	static function clear() {
		top = cast NUL;
		bottom = cast NUL;
		frag_count = 0;
		length = 0;
	}

	// add element at the end of this chain, Only for New Empty Block
	static function add(b:Block):Void {
		if (top == NUL) {
			top = b;
		} else {
			bottom.next = b;
			b.prev = bottom;
		}
		bottom = b;
		++ length;
	}

	// b after a
	static function insertAfter(b:Block, a:Block):Void {
		var cc = a.next;
		a.next = b;
		b.prev = a;
		b.next = cc;
		if (cc == NUL)
			bottom = b;
		else
			cc.prev = b;
		++ length;
	}

	static function indexOf(p:Ptr):Block {
		if (p - Block.CAPACITY > NUL) {
			var b:Block = cast p - Block.CAPACITY;
			//if (b == bottom || b == top || (b.prev.next == b && b.next.prev == b))
			//	return b;
			if (b == bottom || b == top) return b;
			var prev = b.prev, next = b.next;      // for Too many local variables
			if (prev.next == b && next.prev == b) return b;
		}
		return cast NUL;
	}

	public static function make(need:Int, zero:Bool):Ptr {
		need = Ut.padmul(need, LB);

		//if (frag_count > 0) mergeFragment();

		var tmp_frag_count = frag_count;
		var ret:Block = cast NUL;
		var capacity = 0;
		var cc:Block = top;
		while (tmp_frag_count > 0 && cc != NUL) {
			if (cc.is_free) {
				capacity = cc.len;
				if (capacity == need) {
					ret = cc;
					break;
				} else if (ret == NUL && capacity > need) {
					ret = cc;
				}
				-- tmp_frag_count;
			}
			cc = cc.next;
		}

		var block_need = need + Block.CAPACITY;

		if(ret == NUL){
			var p = getUsed();
			@:privateAccess Ram.req(p + block_need);	// check
			ret = new Block(cast p, need, zero);
			add(ret);
		}else{
			capacity = ret.len;
			if (capacity >= 128 && capacity >= (block_need + block_need)) {
				ret.size = block_need;					// resize for split
				var newly = new Block(ret.entry + need, capacity - block_need, false);
				newly.is_free = true;
				insertAfter(newly, ret);
			}else{
				-- frag_count;
			}
			ret.is_free = false;
		}
		return ret.entry;
	}

	public static inline function free(p:Ptr) freeBlock(indexOf(p));

	static function freeBlock(prev:Block):Void {
		if (prev == NUL || bottom == NUL || prev.is_free) return;

		prev.is_free = true;

		++ frag_count;

		while (bottom == prev && bottom.is_free) {
			prev = bottom.prev;
			-- length;
			-- frag_count;
			if (prev == NUL) {
				top = bottom = cast NUL;
				break;
			}
			prev.next = cast NUL;
			bottom = prev;
		}
	}

	static function mergeFragment() {
		var next:Block = cast NUL;
		var head:Block = top;
		while (head != NUL && frag_count > 0) {		// if head == null, Is empty
			if (head.is_free) {
				next = head.next;
				if (next != NUL && next.is_free) {	// if next == null, next is BOTTOM
					head.next = next.next;			// Note: next.next
					if (head.next == NUL) {
						bottom = head;
					} else {
						head.next.prev = head;
					}
					head.size += next.size;
					-- frag_count;
					-- length;
					continue;						// continue combine into this Block
				}
			}
			head = head.next;
		}
	}

	// FOR DEBUG
	static function iterator():BlockIterator {
		return new BlockIterator(top);
	}
}


private class BlockIterator {

	var head:Block;

	public inline function new(h:Block) head = h;

	public inline function hasNext():Bool return head != Malloc.NUL;

	public inline function next():Block {
		var ret = head;
		head = head.next;
		return ret;
	}
}