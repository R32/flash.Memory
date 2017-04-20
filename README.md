fstruct (WIP)
------

Way to typedef struct like c language

### usage

normal struct:

```haxe
import mem.Ptr;                   // 1. import mem.Ptr

@:build(mem.Struct.make())
abstract Monkey(Ptr) {            // 2. define struct
  @idx(4 ) var id: Int;
  @idx(16) var name: String;
}

class App {
    static function main() {
        Ram.attach();             // 3. init Ram
        var jojo = new Monkey();
    jojo.name = "jojo";
    jojo.id = 101;
    trace('id: ${jojo.id}, name: ${jojo.name},');
    }
}
```

flexible struct:


### extra

Providing some crypto method using flash.Memory, Including Md5, Sha1, Sha256, Base64, Crc32, AES128(only cbc/ecb)
