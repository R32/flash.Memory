flash.Memory (WIP)
------

A way to typedef struct like c language

### normal struct

all of `@idx` Supported types in [Struct.hx](tools/mem/Struct.hx#L98)

```haxe
import raw.Ptr;                   // 1. import raw.Ptr

@:build(raw.Struct.make())
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
