package mem;

/**
example:

```
class Monkey implements mem.IStruct {
	@idx(4 ) var id: Int;
	@idx(16) var name: String;
}

new Monkey();
```
*/
#if !macro
@:autoBuild(mem.Struct.make())
#end
@:remove interface IStruct {
	var addr(default, null): mem.Ptr;
}
