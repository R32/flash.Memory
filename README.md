flash.Memory (WIP)
------

A way to typedef struct like c language

### normal struct

all of `@idx` Supported types in [Struct.hx](src/raw/Struct.hx#L15-L32)

```haxe
import raw.Ptr;                   // 1. import raw.Ptr

@:build(raw.Struct.make())
abstract Monkey(Ptr) {            // 2. define struct
  @idx(4 ) var id: Int;
  @idx(16) var name: String;
}

class App {
    static function main() {
        Raw.attach();             // 3. init Raw
        var jojo = new Monkey();
        jojo.name = "jojo";
        jojo.id = 101;
        trace('id: ${jojo.id}, name: ${jojo.name},');
	jojo.free();              // 4. Manually call free to release memory
    }
}
```

### flexible struct

```hx
import raw.Ptr;

@:build(raw.Struct.make())
abstract UString(Ptr) to Ptr {
    @idx(4) var length: Int;
    @idx(0) var __s: raw.Ucs2;    // see raw.Ucs2 about how to customize the array of raw
}
```