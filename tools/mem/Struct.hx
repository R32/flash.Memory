package mem;

import mem.Ptr;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.PositionTools.here;

typedef Param = {
	width:Int,
	nums:Int,
	dx:Int
};
#end

/**
* in bytes
* new 方法应该定义成 **inline** 形式的

```
<bytes=4>mem.Ptr            @idx(?offset)
<bytes=1>Bool:              @idx(?offset)
<bytes=1>Enum               @idx(?offset)
<bytes=1>String             @idx(length, ?offset)
Int: (1), 2, 4              @idx(?bytes, ?offset)
Float: (4), [8|2]           @idx(?bytes, ?offset)
haxe.EnumFlags: (1), 2, 4   @idx(?bytes, ?offset)
Array<Int|Float>            @idx(length, ?bytes, ?offset)
 - Int: (1), 2, 4
 - Float: if(bytes == 2 or 8) then 8 else 4
```
*/
#if !macro
@:autoBuild(mem.ZStructBuild.build())
#end
@:remove interface Struct{
	var ptr(default, null):mem.Ptr;

/*  if not have, macro will be auto create below these:

	public var ptr(default, null):mem.Ptr;
	public inline function new(p:Ptr) this.ptr = p;
	public inline function free(p:Ptr){
		Ram.free(ptr);
		this.ptr = -1;
	}
*/
}

class ZStructBuild{
	#if macro
	static inline var IDX = "idx";

	static function parseInt(s:String):Int{
		if (s == null) return 0;
		var i = Std.parseInt(s);
		return Math.isNaN(i) ? 0 : i;
	}
	static inline function notZero(v:Int, def:Int = 1):Int{
		return v <= 0 ? def : v;
	}

	static function parseMeta(arr:Array<Int>, type:String):Param{
		var ret;
		var len = arr.length;
		switch(type){
			case "Bool", "Enum":
				ret = {width:1, dx: arr[0], nums: 0};
			case "Array":
				switch(len){
					case 1: ret = {width:1, dx: 0, nums: notZero(arr[0])};
					case 2: ret = {width:notZero(arr[1]), dx: 0, nums: notZero(arr[0])};
					case 3: ret = {width:notZero(arr[1]), dx: arr[2], nums: notZero(arr[0])};
					default: Context.warning("array idx data?????", here()); // 0,
				}
			case "mem.Ptr":
				ret = {width:4, dx: arr[0], nums: 0};
			default: // Float, String, Int, haxe.EnumFlags
				switch(len){
				case 1: ret = {width:notZero(arr[0]), dx: 0, nums: 0};
				case 2: ret = {width:notZero(arr[0]), dx: arr[1], nums: 0};
				default: ret = {width:0, dx: 0, nums: 0};	// width=0;
				}
		}
		return ret;
	}

	static public function build(){
		var cls:ClassType = Context.getLocalClass().get();
		var fields:Array<Field> = Context.getBuildFields();

		var all_fields:Array<String> = [];
		var attrs = {};

		var offset = 0;
		var params:Param;
		var metaParams;

		var constructor:Field = null;
		var hasPtr = false;
		var hasFree = false;
		var hasToString = false;

		for (f in fields.copy()){
			if (f.name == "new") constructor = f;
			if (f.name == "ptr") hasPtr = true;
			if (f.name == "free") hasFree = true;
			if (f.name == "toString") hasToString = true;

			metaParams = null;
			params = null;

			for(meta in f.meta){
				if(meta.name == IDX){
					switch (meta.params) {
						case [{expr: EConst(CInt(v))}, {expr: EConst(CInt(v2))}, {expr: EConst(CInt(v3))}]:
							metaParams = [parseInt(v), parseInt(v2), parseInt(v3)];

						case [{expr: EConst(CInt(v2))}, {expr: EConst(CInt(v3))}]:
							metaParams = [parseInt(v2), parseInt(v3)];

						case [{expr: EConst(CInt(v3))}]:
							metaParams = [parseInt(v3)];

						default:
							metaParams = [0];
					}
				}
			}
			if (metaParams == null) continue;

			switch (f.kind) {
			case FVar(vt = TPath({pack: pack, name: name, params:arrType}), init):
				var path = pack.copy();
				path.push(name);
				var t = Context.getType(path.join("."));
				var ts = "";
				var exprs = switch (t) {
					case TType(a, _):
						ts = Std.string(a);
						if (ts == "mem.Ptr"){
							params = parseMeta(metaParams, ts);
							offset += params.dx;
							[macro Memory.getI32(ptr + $v{offset}), macro (Memory.setI32(ptr + $v{offset}, v))];
						}else{
							null;
						}
					case TAbstract(a, _):
						ts = Std.string(a);
						params = parseMeta(metaParams, ts);
						offset += params.dx;
						switch (ts) {
						case "Bool":
							[macro Memory.getByte(ptr+ $v{offset}) != 0, macro Memory.setByte(ptr+ $v{offset}, v ? 1 : 0)];
						case "Int":
							var sget = "getByte", sset = "setByte";
							switch (params.width) {
							case 2: sget = "getUI16"; sset = "setI16";
							case 4: sget = "getI32"; sset = "setI32";
							default: params.width = 1;
							}
							[macro Memory.$sget(ptr + $v{offset}), macro (Memory.$sset(ptr + $v{offset}, v))];
						case "Float":
							var sget = "getFloat", sset = "setFloat";
							if (params.width == 2) params.width = 8;
							if(params.width == 8){
								sget = "getDouble"; sset = "setDouble";
							}else{
								params.width = 4;
							}
							[macro Memory.$sget(ptr + $v{offset}), macro (Memory.$sset(ptr + $v{offset}, v))];
						case "haxe.EnumFlags":
							switch(arrType[0]){	// ComplexType
							case TPType(ct):
								var sget = "getByte", sset = "setByte";
								switch(params.width){
								case 2: sget = "getUI16"; sset = "setI16";
								case 4: sget = "getI32"; sset = "setI32";
								default: params.width = 1;
								}
								if (params.width * 8 < TypeTools.getEnum(ComplexTypeTools.toType(ct)).names.length)
									throw "Unsupported width for EnumFlags" + params.width;
								[macro { new haxe.EnumFlags<$ct>(Memory.$sget(ptr + $v{offset}));}
									, macro { Memory.$sset(ptr + $v{offset}, v.toInt());}];
							default: throw "EnumFlags instance expected";
							}
						default: null;
						}
					case TEnum(e, _):
						ts = Std.string(e);
						params = parseMeta(metaParams, ts);
						offset += params.dx;
						params.width = 1;
						var epr = Context.getTypedExpr({expr:TTypeExpr(TEnumDecl(e)), t:t, pos:f.pos});
						[macro haxe.EnumTools.createByIndex($epr, Memory.getByte(ptr + $v{offset})),
							macro Memory.setByte(ptr + $v{offset}, Type.enumIndex(v))];

					case TInst(s, _):
						ts = Std.string(s);
						params = parseMeta(metaParams, ts);
						offset += params.dx;
							switch(ts) {
							case "String":
							[macro Ram.readUTFBytes(ptr + $v{offset}, $v{params.width})
								,macro Ram.writeUTFBytes(ptr + $v{offset}, v)];
							case "Array":
								switch (arrType[0]) {
								case TPType(ct = TPath(at)):
									var sget = null, sset = null;
									switch (at.name) {
										case "Int":
											switch(params.width){
											case 2: sget = "getUI16"; sset = "setI16";
											case 4: sget = "getI32"; sset = "setI32";
											default:
												params.width = 1;
												sget = "getByte"; sset = "setByte";
											}
										case "Float":
											if (params.width == 2) params.width = 8;
											if(params.width == 8){
												sget = "getDouble"; sset = "setDouble";
											}else{
												params.width = 4;
												sget = "getFloat"; sset = "setFloat";
											}
										default: null;
									}// end(at.name)
									if (sget == null || sset == null){
										null;
									}else{
										[macro{ var ret:Array<$ct> = [];
											for (i in 0...$v{params.nums}) ret.push(Memory.$sget(ptr + i));
											ret;
										}, macro{ for (i in 0...$v{params.nums}) Memory.$sset(ptr + i, v[i]); }];
									}
								default: null;
								}
							default: null;
							}
					default: null;
				}

				if(exprs == null){
					Context.warning("Type (" + ts +") is not supported for field: " + f.name ,here());
				}else{
					f.kind = FProp("get", "set", vt, null);
					f.access = [APublic];
					var getter = exprs[0];
					var setter = exprs[1];

					fields.push({
						name : "get_" + f.name,
						access: [AInline],
						kind: FFun({
							args: [],
							ret : vt,
							expr: macro {
								return $getter;
							}
						}),
						pos: here()
					});

					fields.push({
						name: "set_" + f.name,
						access: [AInline],
						kind: FFun({
							args: [{name: "v", type: vt}],
							ret : vt,
							expr: macro {
								$setter;
								return v;
							}
						}),
						pos: here()
					});

					fields.push({
						name : "__" + f.name.toUpperCase() + "_OF",
						access: [AStatic, AInline, APublic],
						doc: " == " + $v{offset},
						kind: FVar(macro :Int, macro $v{offset}),
						pos: here()
					});

					var is_array = ts == "Array";
					fields.push({
						name : "__" + f.name.toUpperCase() + "_LEN",
						doc: " == " + $v{is_array ? params.nums : params.width},
						access: [AStatic, AInline, APublic],
						kind: FVar(macro :Int, macro $v{is_array ? params.nums : params.width}),
						pos: here()
					});

					if(is_array){
						fields.push({
							name : "__" + f.name.toUpperCase() + "_BYTE",
							access: [AStatic, AInline, APublic],
							doc: " == " + $v{params.width},
							kind: FVar(macro :Int, macro $v{params.width}),
							pos: here()
						});

						Reflect.setField(attrs, f.name, {offset: offset,bytes: params.width,len: params.nums});
						offset += params.nums * params.width;
					}else{
						Reflect.setField(attrs, f.name, {offset: offset, len: params.width, bytes: 1});
						offset += params.width;
					}
					all_fields.push(f.name);
				}

			default:
			}

		}
		fields.push({
			name : "CAPACITY",
			doc:  "== " + $v{offset},
			access: [AStatic, AInline, APublic],
			kind: FVar(macro :Int, macro $v{offset}),
			pos: here()
		});

		fields.push({
			name : "ALL_FIELDS",
			doc:  "== " + $v{offset},
			access: [AStatic, AInline, APublic],
			kind: FFun({
					args: [],
					ret : macro :Iterator<String>,
					expr: macro {
						return $v{all_fields}.iterator();
					}
				}),
			pos: here()
		});

		if(constructor == null){
			fields.push({
				name : "new",
				access: [AInline, APublic],
				kind: FFun({
					args: [{name: "p", type: macro :mem.Ptr}],
					ret : null,
					expr: macro {
						ptr = p;
					}
				}),
				pos: here()
			});
		}else if (constructor.access.indexOf(AInline) == -1){
			Context.warning("Suggestion: add **inline** for " + cls.name + "'s constructor new" , here());
		}

		if (!hasFree)
			fields.push({
				name : "free",
				access: [AInline, APublic],
				kind: FFun({
					args: [],
					ret : null,
					expr: macro {
						Ram.free(ptr);
						ptr = -1;
					}
				}),
				pos: here()
			});

		if(!hasPtr)
			fields.push({
				name : "ptr",
				access: [APublic],
				kind: FProp("default", "null",macro :mem.Ptr),
				pos: here()
			});

		if (!hasToString){
			var block:Array<Expr> = [];
			for (k in all_fields.iterator()){
				var node = Reflect.field(attrs, k);
				var _w = hexWidth(offset);
				var _dx = StringTools.hex( node.offset, _w);
				var _len = node.len * node.bytes;
				var _end = StringTools.hex(node.offset + _len, _w);
				block.push(macro buf.push("offset: 0x" + $v{_dx} + " - 0x" + $v{_end} + ", bytes: "+ $v{_len} +", " + $v{k} + ": " + $i{k} + "\n"));
			}
			fields.push({
				name : "toString",
				access: [AInline, APublic],
				kind: FFun({
					args: [],
					ret : macro :String,
					expr: macro {
						var buf = ["--- " + $v{cls.name} + ".CAPACITY: " + $v{offset} + "\n"];
						$b{block};

						return buf.join("");
					}
				}),
				pos: here()
			});
		}
		return fields;
	}

	static function hexWidth(n){
		var i = 0;
		while (n >= 1) {
			n = n >> 4;
			i += 1;
		}
		if ((i & 1) == 1) i += 1;
		if (i < 2) i = 2;
		return i;
	}
	#end
}