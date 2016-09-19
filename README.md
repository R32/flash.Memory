flash.Memory
------

**WIP**

Example:

```haxe
import mem.Ptr;                          // 1. import mem.Ptr

#if !macro
@:build(mem.Struct.StructBuild.make())   // 2. macro build
#end
abstract EndianDetect(Ptr){              // 3. define struct
    @idx        var littleEndian:Bool;
    @idx(2, -1) var i:Int;               ///idx(bytes: 2, offset: -1)
    @idx(-1)    var bigEndian:Bool;
}


class Main {
    static function main() {
        Ram.attach();                    // 4. init Ram
        var endian = new EndianDetect(); /// can be directly initialized
        endian.i = 1;
        trace('littleEndian: ${endian.littleEndian}, bigEndian: ${endian.bigEndian}');
        trace(endian.__toOut());         /// output struct info
    }
}
```

**output**: `haxe -cp tools -main Main -swf exa.swf`,

```bash
littleEndian: true, bigEndian: false
--- EndianDetect.CAPACITY: 2 .OFFSET_FIRST: 0 .ACTUAL_SPACE: 8, ::baseAddr: 32
offset: 0x00 - 0x01, bytes: 1, littleEndian: true
offset: 0x00 - 0x02, bytes: 2, i: 1
offset: 0x01 - 0x02, bytes: 1, bigEndian: false
```

It's very useful to read a fixed-bin-struct directly!
<br />
