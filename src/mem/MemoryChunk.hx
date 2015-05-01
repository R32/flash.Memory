package mem;

import Ram;

class MemoryChunk{
	
	private static var last:MemoryChunk = null;
	
	private static var first:MemoryChunk = null;
	
	/**
	* Int -> MemoryChunk::position
	*/
	private static var pool:Map < Int, MemoryChunk > = new Map<Int,MemoryChunk>();
		
	/**
	* instance计数器,
	*/
	private static var COUNT:Int = 0;
	/**
	* 碎片数量
	*/
	public static var fragCount(default, null):Int = 0;

	/**
	* free 
	* @param	ptr
	* @return
	*/
	public static function release(ptr:Int):Bool {
		return pool.exists(ptr) ? pool.get(ptr).free() : false;	
	}
	
	/**
	*  查找 碎片,优先检测是否有可用碎片
	* @param	size
	* @return
	*/
	public static function calcPtr(size:UInt):Int {
		var ptr:Int = used;
		if (fragCount > 0) {
			
			var fb = combFree(); 	// 合并 连续碎片
			
			var kyes = fb.keys();	
			
			var big:Bool = true;
			
			var len:UInt = 0;
			
			for (k in kyes) {
				len = fb.get(k);
				// 只找一个 大于 size 的 单元
				if(big && len > size){
					ptr = k;
					big =  false;
				}
				// 如果有 等于 size 的单元,覆盖并 退出循环
				if (len == size) {
					ptr = k;
					break;
				}
			}
		}
		return ptr;
	}

	/**
	* 检测是否存在
	* @param	ptr position
	* @return
	*/
	public static inline function has(ptr:Int):Bool {
		return pool.exists(ptr);
	}
	
	/**
	* 获得 id 值
	* @param	ptr
	* @return
	*/
	public static function getId(ptr:UInt):Int {
		var c:MemoryChunk = pool.get(ptr);
		return (c != null) && (c.isFree == false) ? c.id : -1; 
	}
	
	/**
	* 	返回一个 Map, id 值指向 ptr
	* @return
	*/
	public static function getIds():Map<Int,UInt> {
		var ret:Map<Int,UInt> = new Map<Int,UInt>();
		for (c in pool) {
			if(!c.isFree){
				ret.set(c.id, c.position);		
			}
		}
		return ret;
	}
	
	public static var used(get, never):Int;
	private static function get_used():Int {
		return last == null ? 0 : last.position + last.length;
	}
		
	/**
	* 是否标记为 free
	*/
	public var isFree(default,null):Bool;

	
	/**
	* 当前记录这个片段 于memory的地址
	*/
	public var position(default,null): UInt;
	
	/**
	* 当前 chunk 长度 
	*/
	public var length(default,null): UInt;

	
	private var next: MemoryChunk;
	
	private var prev: MemoryChunk;
	
	/**
	* 当前 chunk 的 id 值 
	*/
	public var id(default,null):Int;
	
	/**
	* 新的 构造函数
	*/
	@:allow(Ram.malloc)
	private function new(position:UInt,len:UInt):Void {
		
		var exists:MemoryChunk = pool.get(position);
		
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
				exists.position = position + len;
				pool.set(exists.position, exists); 	 // 新的 key 值
				exists.length = exists.length - len; // 新的长度值
			}
		}else {
			throw "分配错误";	
		}
		this.id = COUNT++;
		this.isFree = false;
		this.position = position;
		this.length = len;
		pool.set(position, this);
	}
	
	public function toString():String{
		return '[MemoryChunk size: 0x'+StringTools.hex(this.length) +'\tposition: 0x'+StringTools.hex(this.position) + '\tfree: '+this.isFree+ ']';
	}
	
	/*public function toString():String {
		return '[MemoryChunk position: 0x' + StringTools.hex(position,2) +
				', size: 0x' + StringTools.hex(length, 2) + '\tisFree '+this.isFree +//']';
			'\t prev is 0x' + (this.prev==null ? '---' : StringTools.hex(this.prev.position)) + ' \t.next is 0x' + (this.next == null ? '---' : StringTools.hex(this.next.position)) + '\t id: '+this.id +']\t';// + Ram.readString(this.position,16);	
	}*/
		
	public function free() :Bool {
		if(!this.isFree){
			this.isFree = true;	// 标记就OK 了.
			
			fragCount += 1;	//  碎片值加 1, 后边的 clean_函数, 如符合条件将会 处理这个值
			
			clean_();		// 从链尾往前清除 标记为free 的单元
		}
		return true;
	}
	

	
	/**
	* 从 链尾向上依次清除连继被标记为 free 的 chunk
	*/
	private static function clean_():Void {
		var prev:MemoryChunk = null;
		while (last != null && last.isFree) {
			prev = last.prev;
			pool.remove(last.position);//trace(last.id +" ->dispose:\t 0x" + StringTools.hex(last.position));
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
	
	/**
	* 合并所有 连续 碎片 单元
	*/
	public static function combFree():Map<Int,Int> {
		var a:MemoryChunk = first;
		var b:MemoryChunk = null;
		// 构建一个 freeBlock 的	Map<ptr,length>, 保存 所有 碎片
		var fb:Map<Int,Int> = new Map<Int,Int>();
		
		//接下来合并所有 连续碎片
		while (a != null && fragCount > 0) {
			if (a.isFree) {
				b = a.next;
				if ((b != null) && b.isFree) {
					a.next = b.next;
					if (a.next == null) {
						last = a;	
					}else {
						a.next.prev = a;
					}
					
					b.prev = b.next = null;
					pool.remove(b.position); // 移除 第二个
					a.length += b.length;	 // 扩充 length
					
					fragCount -= 1;			// 计数器
					continue;				// a 没变,只是扩充了长度,continue 就好		
				}
				fb.set(a.position, a.length);
			}
			a = a.next;
		}
		return fb;	
	}
	
	/**
	* 警告(重要): 
		// 因为 format 将会移动内存块的位置,所以会使已保存了 ptr 的变量指向错误的位置.
		// 如果你无法获得新 ptr 的位置,不要调用这个函数
		// 需要通过获得新的内存块位置( ptr )，getIds() 将返回一个 id => ptr 的 Map
				
		// 实际上如果没怪异的操作 申请/释放  不会产生内存碎片的问题,也不用调用这个函数
	*/
	public static function format():Void {
		var a:MemoryChunk = first;
		var b:MemoryChunk = null;
		var pos:UInt = 0;
		
		if (fragCount > 0) {
			while (a != null) {
				if (null == (b = a.next)) {
					break;// 这时候 a == last; b 为 null 时,已经不需要再移动单元了
				}
				if (a.isFree) {	//这里处理方式和 comblineFree 相反 
					b.prev = a.prev;
					if (b.prev == null) {	
						first = b;
					}else {
						b.prev.next = b;	
					}
					a.prev = a.next = null;
					
					if (b.isFree) {
						// 只要合并 连续的 free 单元就行了
						b.length += a.length;// trace("合并 连续的 free 单元") ;
					}else {
						Ram.memcpy(a.position,	b.position,	b.length);//
					}
					pool.remove(b.position);	// 移除 b 旧的指向
					pool.set(a.position, b);	// 设置 a.position为另一个chunk的同时,会自动移除 对 a 的指引.
					b.position = a.position;	// 更新 b.position 的位置
					fragCount -= 1;	
				}else {
					pos = a.position + a.length;
					if (b.position != pos) {
						Ram.memcpy(pos,	b.position,	b.length);//trace("调用内存复制方法 memcpy -- move") ;
						pool.remove(b.position);
						pool.set(pos, b);
						b.position = pos;
					}
				}
				a = b;
			}
		}
	}
}	