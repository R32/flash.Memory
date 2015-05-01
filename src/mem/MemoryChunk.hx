package mem;

import Ram;

class MemoryChunk{
	
	public var id(default,null):Int;
	
	public var isFree(default,null):Bool;

	public var ptr(default,null): Int;			// ptr
	
	public var length(default,null): Int;
	
	var next: MemoryChunk;
	
	var prev: MemoryChunk;
	
	@:allow(Ram.malloc)
	private function new(ptr:Int,len:Int):Void {
		
		var exists:MemoryChunk = pool.get(ptr);
		
		if (exists == null) {// 添加到链尾
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
			
			if (exists.length == len) {// 替换并移除 exists
				if ((this.next = exists.next) == null) {
					last = this;
				}else {
					this.next.prev = this;
				}
				exists.prev = exists.next = null;
				fragCount -= 1;
			}else{// 分割 exists
				this.next = exists;
				exists.prev = this;
				exists.ptr = ptr + len;
				pool.set(exists.ptr, exists); 	 // 新的 key 值
				exists.length = exists.length - len; // 新的长度值
			}
		}else {
			throw "分配错误";	
		}
		this.id = COUNT++;
		this.isFree = false;
		this.ptr = ptr;
		this.length = len;
		pool.set(ptr, this);
	}
	
	public function toString():String{
		return '[MemoryChunk size: 0x'+StringTools.hex(this.length) +'\tposition: 0x'+StringTools.hex(this.ptr) + '\tfree: '+this.isFree+ "\tid: "+ this.id +']';
	}
	
	/*public function toString():String {
		return '[MemoryChunk ptr: 0x' + StringTools.hex(ptr,2) +
				', size: 0x' + StringTools.hex(length, 2) + '\tisFree '+this.isFree +//']';
			'\t prev is 0x' + (this.prev==null ? '---' : StringTools.hex(this.prev.ptr)) + ' \t.next is 0x' + (this.next == null ? '---' : StringTools.hex(this.next.ptr)) + '\t id: '+this.id +']\t';// + Ram.readString(this.ptr,16);	
	}*/
		
	public function release() :Bool {
		if(!this.isFree){
			
			this.isFree = true;
			
			fragCount += 1;	
			
			_clean();		
		}
		return true;
	}
	
	static var COUNT:Int = 0;
	
	static var last:MemoryChunk = null;
	
	static var first:MemoryChunk = null;
	
	public static var fragCount(default, null):Int = 0;
	
	// ptr => id
	static var pool = new UnsafeIntMap<MemoryChunk>();
	
	public static inline function has(ptr:Int):Bool {
		return pool.exists(ptr);
	}
	
	public static function get(ptr:Int):MemoryChunk{
		return pool.get(ptr);
	}
	
	public static function getId(ptr:Int):Int {
		var c = pool.get(ptr);
		return c != null ? c.id : -1;
	}
	
	public static function allPtr():Array<Int>{
		var ret = new Array<Int>();
		for(ptr in pool.keys()){
			ret.push(ptr);
		}
		ret.sort(function(a:Int,b:Int):Int{
			return a > b ? 1 : -1;
		});
		return ret;
	}
	
	public static function get_used():Int {		// space used
		return last == null ? 0 : last.ptr + last.length;
	}
	
	public static function free(ptr:Int):Bool {
		return pool.exists(ptr) ? pool.get(ptr).release() : false;	
	}
	
	/**
	*  查找 碎片,优先检测是否有可用碎片
	* @param	size
	* @return
	*/
	public static function calc(size:Int):Int {
		var ptr:Int = get_used();
		if (fragCount > 0) {
			
			var fb = mergeFragment(); 					// 合并连续碎片
			
			var kyes = fb.keys();	
			
			var big:Bool = true;
			
			var len = 0;
			
			for (k in kyes) {
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
		}
		return ptr;
	}
	
	static function _clean():Void {
		var prev:MemoryChunk = null;		
		if(last != null){
			while (last.isFree) {
				prev = last.prev;
				pool.remove(last.ptr);
				fragCount -= 1;
				if (prev == null ) {
					// 当 prev 值为 null时，表示这是第一个 单元
					first = last = null;
					break;
				}
				last.prev = prev.next = null;
				last = prev;
			}						
		}
	}
	
	/**
	* Merge all fragments of the continuous
	* 合并所有 连续 碎片 单元
	*/
	public static function mergeFragment():UnsafeIntMap<Int> {
		var a:MemoryChunk = first;
		var b:MemoryChunk = null;
		// 构建一个 freeBlock 的	Map<ptr,length>, 保存 所有 碎片
		var fb = new UnsafeIntMap<Int>();
		
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
					pool.remove(b.ptr);	// 移除 第二个
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