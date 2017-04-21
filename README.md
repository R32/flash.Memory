fraw (WIP)
------

A way to typedef struct like c language

### normal struct

all of `@idx` Supported types in [Struct.hx](tools/mem/Struct.hx#L20)

```haxe
import mem.Ptr;                   // 1. import mem.Ptr

@:build(mem.Struct.make())
abstract Monkey(Ptr) {            // 2. define struct
  @idx(4 ) var id: Int;
  @idx(16) var name: String;
}

class App {
    static function main() {
        Fraw.attach();            // 3. init Fraw
        var jojo = new Monkey();
        jojo.name = "jojo";
        jojo.id = 101;
        trace('id: ${jojo.id}, name: ${jojo.name},');
    }
}
```

### flexible struct

Currently only supported types are AU8, AU16, AI32, AF4, AF8, Ucs2.

Note: Could not assign multiple values to there types directly.

```haxe
@:build(mem.Struct.make())
abstract UString(Ptr) to Ptr {
    @idx(4) var length: Int;
    @idx(0) var __s: mem.Ucs2;    // idx({length: 0})
}
```

Actually the offset of first field can be defined as a negative value.

```haxe
import mem.Ptr;

@:build(mem.Struct.make())
abstract UString(Ptr) to Ptr {
    @idx(4, -4) var length: Int;  // idx({sizeof: 4, offset: -4})
    @idx(0) var __s: mem.Ucs2;
    public function new(str: String) {
        var bytesLength = (str.length + 1) << 1;
        mallocAbind(bytesLength + CAPACITY, false);  // mallocAbind & CAPACITY defined by macro
        length = str.length;      // assign values after malloc
        __s.copyfromString(str);
        Memory.setI16(bytesLength - 2, 0);
    }
    public function toString() return __s.toString();
}

class App {
    static function main() {
        Fraw.attach();
        var us = new UString("hello 世界!");
        log(cast us); // UString => mem.Ucs2, since (us: Ptr) == (us.__s: Ptr)
        trace(us.__toOut());
    }

    static function log(ucs2: mem.Ucs2) {
        trace(ucs2.toString());
    }
}
```

output:

```
App.hx:26: hello 世界!
App.hx:22:
--- [UString] CAPACITY: 4, OFFSET_FIRST: -4, OFFSET_END: 0, FLEXIBLE: True
--- ACTUAL_SPACE: 32, baseAddr: 72, Allocter: Fraw
offset: (-4) - 0x00, bytes: 4, length: 9
offset: 0x00 - 0x00, bytes: 0, __s: [...]
```

### [mem.Mini](tools/mem/Mini.hx#L8)

this a simple fixed-width memory allocator.

```haxe
@:build(mem.Struct.make(mem.Mini))  // use Mini as memory allocter
abstract Commit(Ptr) {
  @idx(4) var value: Int;
  @idx(2) var key: Int;
}
```

## benchmark

soon. (maybe only faster in flash platform.)

## extra

Providing some crypto method using flash.Memory, Including Md5, Sha1, Sha256, Base64, Crc32, AES128(only cbc/ecb)
