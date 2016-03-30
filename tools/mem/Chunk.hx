package mem;

import Ram;
import haxe.ds.IntMap;

class Chunk{
	public var id(default,null):Int;
	public var isFree(default,null):Bool;
	public var ptr(default,null): Ptr;
	public var length(default, null): Int;

	var next: Chunk;
	var prev: Chunk;

	@:allow(Ram.malloc)
	private function new(ptr:Ptr, len:Int):Void {

		var exists:Chunk = pool.get(ptr);

		if (exists == null) {						// 添加到链尾
			if (first == null) {
				this.prev = null;
				this.next = null;
				first = this;
				last  = this;
			}else {
				last.next = this;
				this.prev = last;
				this.next = null;
				last = this;
			}
		}else if (exists.isFree && exists.length >= len) {// 插入到 pool 中间位置
			if ((this.prev = exists.prev) == null) {
				first = this;
			}else {
				this.prev.next = this;
			}

			if (exists.length == len) {				// 替换并移除 exists
				if ((this.next = exists.next) == null) {
					last = this;
				}else {
					this.next.prev = this;
				}
				exists.prev = exists.next = null;
				fragCount -= 1;
			}else{									// 分割 exists
				this.next = exists;
				exists.prev = this;
				exists.ptr = ptr + len;
				pool.set(exists.ptr, exists); 		 // 新的 key 值
				exists.length = exists.length - len; // 新的长度值
			}
		}else {
			throw "崩溃的分配错误";
		}
		this.id = COUNT++;
		this.isFree = false;
		this.ptr = ptr;
		this.length = len;
		pool.set(ptr, this);
	}

	public function toString():String{
		return '[Chunk size: 0x'+StringTools.hex(this.length) +'\tposition: 0x'+StringTools.hex(this.ptr) + '\tfree: '+this.isFree+ "\tid: "+ this.id +']';
	}

	public function release() :Bool {
		if(!this.isFree){
			this.isFree = true;
			fragCount += 1;
			_clean();
		}
		return true;
	}

	static var COUNT:Int = 0;
	static var last:Chunk = null;
	static var first:Chunk = null;
	public static var fragCount(default, null):Int = 0;

	// ptr => id
	static var pool = new IntMap<Chunk>();

	public static inline function has(ptr:Ptr):Bool {
		return pool.exists(ptr);
	}

	public static inline function get(ptr:Ptr):Chunk{
		return pool.get(ptr);
	}

	public static inline function getId(ptr:Ptr):Int {
		var c = pool.get(ptr);
		return c != null ? c.id : -1;
	}

	// for Debug
	static function allPtrSort(a:Ptr, b:Ptr):Int return a > b ? 1 : -1;
	public static function allPtr():Array<Ptr>{
		var ret = new Array<Ptr>();
		for(ptr in pool.keys()){
			ret.push(ptr);
		}
		ret.sort(allPtrSort);
		return ret;
	}

	public static inline function get_used():Ptr {		// space used
		return last == null ? 16 : last.ptr + last.length;
	}

	public static inline function free(ptr:Ptr):Bool {
		return pool.exists(ptr) ? pool.get(ptr).release() : false;
	}

	public static function calc(size:Int):Ptr {
		var ptr:Ptr = get_used();
		if (fragCount > 0) {
			var fb = mergeFragment(); 					// 合并连续碎片
			var big:Bool = true;
			var len = 0;
			for (k in fb.keys()) {
				len = fb.get(k);
				if(big && len > size){					// 只找一个 大于 size 的 单元
					ptr = k;
					big =  false;
				}
				if (len == size) {						// 如果有 等于 size 的单元,覆盖并 退出循环
					ptr = k;
					break;
				}
			}
			for (k in fb.keys()) fb.remove(k);
		}
		return ptr;
	}

	static function _clean():Void {
		var prev:Chunk = null;
		if(last != null){
			while (last.isFree) {
				prev = last.prev;
				pool.remove(last.ptr);
				fragCount -= 1;
				if (prev == null ) {
					first = last = null;	// 当 prev 值为 null时，表示这是第一个 单元
					break;
				}
				last.prev = prev.next = null;
				last = prev;
			}
		}
	}

	/**
	收集被标记为 free 的 Chunk, 并将连续的块合成一个.
	*/
	public static function mergeFragment():IntMap<Int> {
		var a:Chunk = first;
		var b:Chunk = null;

		var fb = new IntMap<Int>();

		while (a != null && fragCount > 0) {	// if a == null, is empty
			if (a.isFree) {
				b = a.next;
				if ((b != null) && b.isFree) {	// if b == null, so b is last
					a.next = b.next;
					if (a.next == null) {
						last = a;
					}else {
						a.next.prev = a;
					}
					b.prev = b.next = null;
					pool.remove(b.ptr);			// 移除 第二个
					a.length += b.length;		// 扩充 length

					fragCount -= 1;				// 计数器
					continue;					// a 没变,只是扩充了长度,continue 就好
				}
				fb.set(a.ptr, a.length);
			}
			a = a.next;
		}
		return fb;
	}
}