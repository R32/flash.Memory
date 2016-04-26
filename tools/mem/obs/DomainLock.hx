package mem.obs;

#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.PositionTools.here;
import haxe.crypto.Md5;
import haxe.io.Bytes;
import mem.Ut;


class DLockBuild{
	public static function make(dm = "dm-lock"){
		var dms:String = Context.definedValue(dm);
		if (dms == null || dms == "" || dms == "1") Context.error("Must provide -D " + dm + "=domain_1,domain_2", here());
		dms = "file://," + ~/\s/g.replace(dms, "");

		//  use "^" for split
		var bytes = Bytes.ofString(dms + "^loaderInfo.url");
		var split = dms.length;

		// simple obf
		for (i in 0...bytes.length) bytes.set(i, bytes.get(i) ^ "a".code);

		var fields = Context.getBuildFields();
		var pos = here();
		fields.push({
			name: "check",
			access: [APublic, AStatic, AInline],
			pos: pos,
			kind: FFun({
				ret: macro :Void,
				args:[],
				expr: macro {
					var s_0:AString = AString.fromHexString($v{bytes.toHex()});
					for (i in 0...s_0.length)
						Memory.setByte(s_0.c_ptr + i, Memory.getByte(s_0.c_ptr + i) ^ "a".code);
					var p = $v{split};
					var s_1:AString = AString.fromString(filter(rec(Ram.readUTFBytes(s_0.c_ptr + p + 1, s_0.length - p - 1))));

					try{
						match(s_0, s_1, p);
						trace("TODO: some func to crash here ");
					}catch(err:String){
						trace("TODO: have done!");
					}
					s_0.free();
					s_1.free();
				}
			})
		});

		return fields;
	}
}
#elseif (flash || as3)

import flash.Lib;
import mem.struct.AString;
import mem.Ptr;
import mem.Malloc;

/**
only in flash - DomainLock.check()

网址通过 `-D dm-lock=XOR("test.com,example.com,hello.com")` 传入
 - 不支持通配符
 - 不支持转义字符
*/
@:build(mem.obs.DomainLock.DLockBuild.make())
@:dce class DomainLock{

	static inline function rec(s:String):String{
		var a = s.split(".");
		var o:Dynamic = Lib.current;
		for(k in a) o = Reflect.field(o, k);
		return o;
	}

	static inline function filter(s:String):String{
		var dot = s.indexOf(".");
		if(dot != -1){
			var slash = s.indexOf("/", dot);
			if (slash != -1) s = s.substr(0, slash);
		}
		return s;
	}

	static inline function match(dms:AString, url:AString, len:Int):Bool{
		var left:Ptr = dms.c_ptr;
		var w:Int = 0;
		var ret = false;
		for (p in left...left + len){
			if(Memory.getByte(p) == ",".code){
				w = p - left;
				//trace(Ram.readUTFBytes(left, w));
				//trace(url.toString());
				//trace(findA(left, w, url.c_ptr, url.c_ptr + url.length));
				//trace(Ram.findA(left, w, url.c_ptr, url.c_ptr + url.length));
				if (findA(left, w, url.c_ptr, url.c_ptr + url.length) != Malloc.NUL)
					throw "no";		// in fact, it have done without nothing error.
				left = p + 1;
				w = 0;
			}
		}
		return ret;
	}

	// Same as Ram.findA except inline
	static inline function findA(src:Ptr, len:Int, start:Ptr, end:Ptr):Ptr{
		var ptr = Malloc.NUL;
		end -= len;
		while (end >= start){
			var size = len;
			var cc = src;
			var cs = start;
			var ct = 0;
			while (0 != size--)
				if (Memory.getByte(cs++) != Memory.getByte(cc++)){
					start += 1;
					ct = 1;
				}
			if (ct == 1) continue;
			ptr = start;
			break;
		}
		return ptr;
	}
}
#end