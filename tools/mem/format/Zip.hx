package mem.format;

import mem.Ptr;

#if !macro
@:build(mem.Struct.make())
#end
abstract ZFile(Ptr) to Ptr {
	@idx(4) var sign: Int;               // aways be 0x04034b50
	@idx(2) var version: Int;
	@idx(2) var flags: Int;
	@idx(2) var compression: Int;
	@idx(2) var mtime: Int;
	@idx(2) var mdate: Int;
	@idx(4) var crc32: Int;
	@idx(4) var csize: Int;
	@idx(4) var usize: Int;
	@idx(2) var fnamelen: Int;
	@idx(2) var extralen: Int;
	@idx(0) private var pfname: AU8;     // addr of fname

	public var date(get, never): Date;

	public var filename(get, never): String;

	public var pextra(get, never): Ptr;  // addr of extra

	public var pdata(get, never): Ptr;   // addr of data

	public var next(get, never): ZFile;

	public inline function valid() return sign == 0x04034b50;

	public inline function isDirectory() return pfname[fnamelen - 1] == "/".code;

	// garbled if non-ascii
	inline function get_filename(): String return Fraw.readUTFBytes(cast pfname,  fnamelen);

	inline function get_pextra(): Ptr return (pfname: Ptr) + fnamelen;

	inline function get_pdata(): Ptr return pextra  + extralen;

	inline function get_next(): ZFile return cast (pdata + csize);

	function get_date(): Date {
		var t = mtime;
		var hour = (t >> 11) & 31;
		var min = (t >> 5) & 63;
		var sec = t & 31;
		var d = mdate;
		var year = d >> 9;
		var month = (d >> 5) & 15;
		var day = d & 31;
		return new Date(year + 1980, month-1, day, hour, min, sec << 1);
	}

	public inline function encrypted():Bool return (flags & 1) == 1;

	public inline function toString(){
		return '[name: $filename, csize: $csize, usize: $usize, compression: $compression]';
	}
}

/**
Only archive

example:

```
var file = haxe.Resource.getBytes("some.zip");
var fblock = Fraw.mallocFromBytes(file);
var zf: ZFile = cast fblock;

while (zf.valid()) {
	trace(zf.toString());
	zf = zf.next;
}
```
*/
class Zip {

}