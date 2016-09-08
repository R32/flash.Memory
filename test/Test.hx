package;

import mem.obs.SXor;
import mem.obs.Hex;
import mem.Ptr;
import mem.Ut;
import mem.Ph;
import mem.obs.DomainLock;
import mem.obs.Md5;
import Type;
import mem.struct.WString;
import mem.struct.AString;
import mem.struct.Utf8;


class Test {


	public static function main(){
		Ram.select(Ram.create());
		Ram.malloc(Ut.rand(128, 1), false);

		Hex.init();
		SXor.init();
		Utf8.init();
		Md5.init();

		//test_utf8();
		//test_xor_domainLock();
		ASS.test();
		test_md5();
	}

	public static function test_md5() {
		var output = Ram.malloc(16, true);

		var as = AString.fromString("hello world");
		Md5.make(as.c_ptr, as.length, output);
		Hex.trace(output, 16);
		trace(haxe.crypto.Md5.encode(as.toString()));

		var file = haxe.Resource.getBytes("testjs");
		var filePtr = Ram.mallocFromBytes(file);

		var now = haxe.Timer.stamp();

		for (i in 0...3) Md5.make(filePtr, file.length, output);
		var aend = haxe.Timer.stamp() - now;

		var hout:haxe.io.Bytes = null;
		now = haxe.Timer.stamp();
		for (i in 0...3) hout = haxe.crypto.Md5.make(file);
		var bend = haxe.Timer.stamp() - now;

		trace('time aaa: $aend, bbb: $bend');

		Hex.trace(output, 16);
		trace(hout.toHex());
		as.free();
	}

	public static function test_utf8() {
		trace("values of utf8d...");
		var t = @:privateAccess Utf8.inst._utf8_data;  // duplicate copy
		var p = 0;
		for (i in 0...7) {
			trace(t.slice(p, p + 0x20).join(", "));
			p += 0x20;
		}
		for (i in 0...3) {
			trace(t.slice(p, p + 0x10).map(function(v) { return "0x" + StringTools.hex(v); } ).join(", "));
			p += 0x10;
		}
		for (i in 0...4) {
			trace(t.slice(p, p + 0x20).join(", "));
			p += 0x20;
		}
		trace("");
		var str = "这里有几a个中b文c字符";
		trace('str: $str, utf-length: ${str.length}');

		var as = Ram.mallocFromString(str);

		trace("Utf8.length(str): " + Utf8.length(as.c_ptr, as.length));
		Utf8.iter(as.c_ptr, as.length, function(ch) {
			trace(String.fromCharCode(ch));
		} );
		as.free();

		var ba = haxe.io.Bytes.ofString(str);
		trace(haxe.crypto.Crc32.make(ba));
		var p = Ram.malloc(ba.length);
	#if flash
		ba.getData().position = 0;
		Ram.writeBytes(p, ba.length, ba.getData());
	#else
		Ram.writeBytes(p, ba.length, ba);
	#end
		trace(Ph.crc32(p, ba.length));
		Ram.free(p);
	}

	public static function test_xor_domainLock(){
		var sa:WString = Ram.mallocFromString("我可以永远笑着扮演你的配角, 在你的背后自已煎熬, 如果你不想要, 想退出要趁早, 就算迷恋你的微笑..ABC");
		SXor.make(sa.c_ptr, sa.length, sa.c_ptr);
		SXor.make(sa.c_ptr, sa.length, sa.c_ptr);
		trace(sa.toString());
		sa.free();
#if flash
		DomainLock.check();
		//trace(DomainLock.filter("http://cn.bing.com/search?q=i+have+no+idea+for+this&go=%E6%8F%90%E4%BA%A4&qs=n&form=QBLH&pq=i+have+no+idea+for+this&sc=0-23&sp=-1&sk=&cvid=CBE4556873664FCE8D1E1E8B4418FA47"));
#end
	}
}

class ASS implements mem.Struct{
	@idx(10, 1) var a1:Array<Int>;
	@idx(10, 2) var a2:Array<Int>;
	@idx(10, 4) var a4:Array<Int>;
	@idx(10) var u8:AU8;
	@idx(10) var u16:AU16;
	@idx(10) var i32:AI32;
	@idx(10) var f4:AF4;
	@idx(10) var f8:AF8;
	public static function test() {
		var len = 10;
		if((
		   ASS.__A1_BYTE == len
		&& ASS.__A2_BYTE == len * 2
		&& ASS.__A4_BYTE == len * 4
		&& ASS.__U8_BYTE == len
		&& ASS.__U16_BYTE == len * 2
		&& ASS.__I32_BYTE == len * 4
		&& ASS.__F4_BYTE == len * 4
		&& ASS.__F8_BYTE == len * 8
		) && (
		   ASS.__A1_OF == 0
		&& ASS.__A2_OF == len
		&& ASS.__A4_OF == len * 2 + len
		&& ASS.__U8_OF == len * 4 + len * 2 + len
		&& ASS.__U16_OF == len + len * 4 + len * 2 + len
		&& ASS.__I32_OF == len * 2 + len + len * 4 + len * 2 + len
		&& ASS.__F4_OF  == len * 4 + len * 2 + len + len * 4 + len * 2 + len
		&& ASS.__F8_OF  == len * 4 + len * 4 + len * 2 + len + len * 4 + len * 2 + len
		&& ASS.CAPACITY == len * 8 + len * 4 + len * 4 + len * 2 + len + len * 4 + len * 2 + len
		) && (
		   ASS.__A1_LEN == len
		&& ASS.__A2_LEN == len
		&& ASS.__A4_LEN == len
		&& ASS.__U8_LEN == len
		&& ASS.__U16_LEN == len
		&& ASS.__I32_LEN == len
		&& ASS.__F4_LEN == len
		&& ASS.__F8_LEN == len
		)) trace("************************ struct done.");
		else throw "struct";
	}
}