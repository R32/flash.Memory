package mem.obs;

#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.PositionTools.here;
import haxe.crypto.Md5;
import haxe.io.Bytes;
import mem.Ut;
using StringTools;

class DLockBuild{
	public static function make(dm = "dm-lock"){
		var dms:String = Context.definedValue(dm);
		if (dms == null || dms == "" || dms == "1") {
			Context.warning("Can Only be run locally. Maybe you need to define: -D " + dm + "=domain_1,domain_2", here());
			dms = "";
		}
		dms = dms.trim().urlDecode() +  ",localhost,file://,mk:@,"; // CHM URI prefix is "mk:@MSITStore"

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
						Memory.setByte(s_0.addr + i, Memory.getByte(s_0.addr + i) ^ "a".code);
					var len = $v{split};
					var s_1:AString = AString.fromString(filter(rec(Ram.readUTFBytes(s_0.addr + len + 1, s_0.length - len - 1))));
					try{
						match(s_0, s_1, len);
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
	// if s == "a.b" then return Lib.current.a.b
	static inline function rec(s:String):String{
		var a = s.split(".");
		var o:Dynamic = Lib.current;
		for(k in a) o = Reflect.field(o, k);
		return o;
	}

	static inline function filter(s:String):String{
		var ds = s.indexOf("//");
		if(ds != -1){
			var slash = s.indexOf("/", ds + 3); // file:///
			if (slash != -1) s = s.substr(0, slash + 1);
		}
		return s;
	}

	static inline function match(dms:AString, url:AString, len:Int):Void{
		var left:Ptr = dms.addr;
		// parse domain from url
		for (p in left...left + len){
			if(Memory.getByte(p) == ",".code && p - left > 1){
				//trace(Ram.readUTFBytes(left, p - left));
				if (findA(left, p - left, url.addr, url.addr + url.length) != Malloc.NUL)
					throw "no";		// in fact, it have done without nothing error.
				left = p + 1;
			}
		}
	}

	// Same as Ram.findA except inline
	static inline function findA(src:Ptr, len:Int, start:Ptr, end:Ptr):Ptr{
		var ptr = Malloc.NUL;
		end -= len;
		while (end >= start){
			var size = len;
			var cc = src;
			var cs = start;
			var eq = true;
			while (0 != size--)
				if (Memory.getByte(cs++) != Memory.getByte(cc++)){
					start += 1;
					eq = false;
					break;
				}
			if (!eq) continue;
			ptr = start;
			break;
		}
		return ptr;
	}
}
#end