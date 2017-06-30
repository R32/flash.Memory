package raw;

/**
example:

```
class Monkey implements raw.IStruct {
	@idx(4 ) var id: Int;
	@idx(16) var name: String;
}

new Monkey();
```
*/
#if !macro
@:autoBuild(raw.Struct.make())
#end
@:remove interface IStruct {
	var addr(default, null): raw.Ptr;
}