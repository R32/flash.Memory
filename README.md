flash.Memory
------

**WIP**

### features

* can define a fixed struct, It's useful to read a bin file directly.

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

  **output**: `haxe -cp tools -main Main -swf test.swf`,

  ```bash
  littleEndian: true, bigEndian: false

  --- EndianDetect.CAPACITY: 2, OFFSET_FIRST: 0, OFFSET_END: 2
  --- ACTUAL_SPACE: 8, baseAddr: 32, Allocter: Ram
  offset: 0x00 - 0x01, bytes: 1, littleEndian: true
  offset: 0x00 - 0x02, bytes: 2, i: 1
  offset: 0x01 - 0x02, bytes: 1, bigEndian: false
  ```

* Providing some crypto method using flash.Memory, Including Md5, Sha1, Sha256, Base64, Crc32, AES128(only cbc/ecb)

  haxe -cp tools -main Main -swf test.swf -swf-header 800:500:24:0 -resource some.txt@res

  ```haxe
  import mem.obs.Md5;
  import mem.obs.AES128;
  import mem.obs.Crc32;
  import mem.obs.Hex;
  import mem.struct.Base64;
  import mem.struct.AString;

  class Main {
          static function main() {
          Ram.attach();          // 1. init ram
          AES128.init();         // 2. init aes128, if you want to use it
          Md5.init();            // ......
          Hex.init();
          Crc32.init();
          Base64.init();

          var file = haxe.Resource.getBytes("res");       // -resource some.txt@res

          var rf = Ram.mallocFromBytes(file);             // copy bytes to fast ram;

          // Crc32
          trace(Crc32.make(rf, file.length));             // faster than adler32(mem.Ph.adler32)

          // Base64
          var s64 = Base64.encode(rf, file.length);       // will return Base64String
          trace(s64.toString());
          var b64 = s64.toBlock();                        // same as Base64.decode(s64, s64.length);
          trace(Ram.memcmp(rf, b64, b64.length) == 0);    // memcmp(ptr1, ptr2, length);

          // MD5
          var key = Ram.malloc(16);                       // malloc
          var str = AString.fromString("some passwd");    // copy ascii string to ram.
                                                          // if UTF, you should use WString or Ram.mallocFromString
          Md5.make(str, str.length, key);
          Hex.trace(key, 16, true, "Md5: ");

          // AES CBC, KEY must be 16 bytes,
          // allow input == output
          var multi_of_16 = mem.Ut.padmul(file.length, 16);
          AES128.cbcEncryptBuff(rf, key, rf, multi_of_16, cast 0);   // init IV = 0;

          AES128.cbcDecryptBuff(rf, key, multi_of_16, cast 0);

          trace(Ram.readUTFBytes(rf, 32));       // read string from ram
      }
  }
  ```
