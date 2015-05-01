package mem;

/**
* 直接复制了 flash::ds.UnsafeStringMap 的源码, 注意: Int 的值不要超出 Int 限制
*/
class UnsafeIntMap<T> implements haxe.Constraints.IMap<Int,T> {
	private var h : flash.utils.Dictionary;

	public function new() : Void {
		h = new flash.utils.Dictionary();
	}

	public inline function set( key : Int, value : T ) : Void {
		untyped h[key] = value;
	}

	public inline function get( key : Int ) : Null<T> {
		return untyped h[key];
	}

	public inline function exists( key : Int ) : Bool {
		return untyped __in__(key,h);
	}

	public function remove( key : Int ) : Bool {
		if( untyped !h.hasOwnProperty(key) ) return false;
		untyped __delete__(h,key);
		return true;
	}

	public function keys() : Iterator<Int> {
		return untyped (__keys__(h)).iterator();
	}

	public function iterator() : Iterator<T> {
		return untyped {
			ref : h,
			it : __keys__(h).iterator(),
			hasNext : function() { return __this__.it.hasNext(); },
			next : function() { var i : Dynamic = __this__.it.next(); return __this__.ref[i]; }
		};
	}

	public function toString() : String {
		var s = new StringBuf();
		s.add("{");
		var it = keys();
		for( i in it ) {
			s.add(i);
			s.add(" => ");
			s.add(Std.string(get(i)));
			if( it.hasNext() )
				s.add(", ");
		}
		s.add("}");
		return s.toString();
	}
}