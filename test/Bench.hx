package;

import mem.Ptr;
import mem.Malloc.NUL;

#if !macro
@:build(mem.Struct.make())
#end
abstract Point_0(Ptr) to Ptr {
	@idx var x: Float;
	@idx var y: Float;
	public function new(_x:Float, _y:Float) {
		mallocAbind(CAPACITY, false);
		x = _x;
		y = _y;
	}
	public inline function lengthSq() return x * x + y * y;
}


class Point_1 {
	public var x(default, null): Float;
	public var y(default, null): Float;
	public function new(x, y){
		this.x = x;
		this.y = y;
	}
	public inline function lengthSq() return x * x + y * y;
}

class Bench {

	static function main() {
		Fraw.attach(1024 * 1024 * 2);
		trace("- " + flatform());
		VectorWR(); // uint_8
		objectCreate();
	}

	static function VectorWR() {
		var au8 = Fraw.malloc(vector_count);
		var t0 = now();
		for (i in 0...vector_count) {
			au8[i] = rand();
		}
		var t1 = now() - t0;

		var vc = new haxe.ds.Vector<Int>(vector_count);
		var q0 = now();
		for (i in 0...vector_count) {
			vc[i] = rand();
		}
		var q1 = now() - q0;

		trace('Write - fraw: $t1, vector: $q1.');

		// Read
		var n = 0;
		var t0 = now();
		for (i in 0...vector_count) {
			n += au8[i] & 1;
		}
		var t1 = now() - t0;

		var q0 = now();
		for (i in 0...vector_count) {
			n += vc[i] & 1;
		}
		var q1 = now() - q0;

		trace('Read  - fraw: $t1, vector: $q1${n > 0 ? ".": ""}');

		Fraw.free(au8);
	}

	static function objectCreate() {
		var a32:AI32 = cast Fraw.malloc(object_count * AI32.SIZEOF); // count * 4;
		var vc = new haxe.ds.Vector<Point_1>(object_count);
		var t0 = now();
		for (i in 0...object_count) {
			a32[i] = new Point_0(rand(), rand());
		}
		var t1 = now() - t0;

		var q0 = now();
		for (i in 0...object_count) {
			vc[i] = new Point_1(rand(), rand());
		}
		var q1 = now() - q0;
		var last = object_count - 1;
		trace('Object- fraw: $t1, std: $q1. ' + (vc[last].lengthSq() > toPoint(a32[last - 1]).lengthSq()  ? "" : "."));
	}

	static inline function toPoint(v: Int):Point_0 {
		return untyped ((NUL + v): Point_0);
	}

	static function rand() {
		return Std.int(Math.random() * 255);
	}


	static inline var vector_count = 1024 * 1024;
	static inline var object_count = 10240;
	static inline function now():Float return haxe.Timer.stamp();

	static inline function flatform() {
		return
		#if js
		"nodejs"
		#elseif hl
		"hashlink"
		#elseif cpp
		"hxcpp"
		#elseif neko
		"neko"
		#elseif flash
		"flash"
		#else
		"other"
		#end
		;
	}
}