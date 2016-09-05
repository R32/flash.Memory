package;

import mem.obs.SXor;
import mem.obs.Hex;
import mem.Ut;
import mem.Ph;
import mem.obs.DomainLock;
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

		test_utf8();
		test_xor_domainLock();
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