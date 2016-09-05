package mem;

import mem.Ptr;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.PositionTools.here;

typedef Param = {
	width:Int,
	nums:Int,
	dx:Int
};
#else
/**
* in bytes
* new 方法应该定义成 **inline** 形式的

```
<bytes=4>mem.Ptr            @idx(?offset=0)
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
@:autoBuild(mem.StructBuild.make())
#end
@:remove interface Struct{
	private var addr(default, null):mem.Ptr;		// can overwrite as public

/*  make all @idx fields as inline getter/setter;

	and if not have, macro will be auto create below these:
	public var addr(default, null):mem.Ptr;

	public inline function new(){
		addr = mem.Malloc.make(CAPACITY, true);
	}

	public inline function free(p:Ptr){
		mem.Malloc.free(ptr);
		this.addr = mem.Malloc.NUL;
	}

	public inline function __toOut():String{
		return "long ....";
	}

	static inline var CAPACITY:Int = typeof(this struct);
	static inline var ALL_FIELDS:iterator = ["field_1_name", "field_2_name" .....];
*/
}

class StructBuild{
	#if macro
	static inline var IDX = "idx";

	static function parseInt(s:String):Int{
		if (s == null) return 0;
		var i = Std.parseInt(s);
		return Math.isNaN(i) ? 0 : i;
	}

	static inline function notZero(v:Int, def:Int = 1) return v <= 0 ? def : v;

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

	static public function make(context = "addr"){
		var cls:ClassType = Context.getLocalClass().get();
		if (cls.isInterface) return null;
		var fields:Array<Field> = Context.getBuildFields();

		var abs_type  = null;
		switch (cls.kind) {
			case KAbstractImpl(_.get() => t):
				abs_type = t;
			default:
		}
		if (abs_type != null) context = "this";

		var all_fields:Array<String> = [];
		var attrs = {};
		var offset = 0;
		var params:Param;
		var metaParams;

		var all_in_map = new haxe.ds.StringMap<Field>();

		for (f in fields) all_in_map.set(f.name, f);

		for (f in fields){
			metaParams = null;
			params = null;

			if(f.meta != null)
				for(meta in f.meta){
					if (meta.name == IDX){
						metaParams = [];
						for(ex in meta.params){
							metaParams.push(parseInt(ExprTools.getValue(ex)));
						}
						if (metaParams.length == 0) metaParams.push(0);
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
							[macro Memory.getI32($i{context} + $v{offset}), macro (Memory.setI32($i{context} + $v{offset}, v))];
						}else{
							null;
						}
					case TAbstract(a, _):
						ts = Std.string(a);
						params = parseMeta(metaParams, ts);
						switch (ts) {
						case "Bool":
							offset += params.dx;
							[macro Memory.getByte($i{context}+ $v{offset}) != 0, macro Memory.setByte($i{context}+ $v{offset}, v ? 1 : 0)];
						case "Int":
							offset += params.dx;
							var sget = "getByte", sset = "setByte";
							switch (params.width) {
							case 2: sget = "getUI16"; sset = "setI16";
							case 4: sget = "getI32"; sset = "setI32";
							default: params.width = 1;
							}
							[macro Memory.$sget($i{context} + $v{offset}), macro (Memory.$sset($i{context} + $v{offset}, v))];
						case "Float":
							offset += params.dx;
							var sget = "getFloat", sset = "setFloat";
							if (params.width == 2) params.width = 8;
							if(params.width == 8){
								sget = "getDouble"; sset = "setDouble";
							}else{
								params.width = 4;
							}
							[macro Memory.$sget($i{context} + $v{offset}), macro (Memory.$sset($i{context} + $v{offset}, v))];
						case "haxe.EnumFlags":
							offset += params.dx;
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
								[macro { new haxe.EnumFlags<$ct>(Memory.$sget($i{context} + $v{offset}));}
									, macro { Memory.$sset($i{context} + $v{offset}, v.toInt());}];
							default: throw "EnumFlags instance expected";
							}
						default:
							ts = TypeTools.toString(a.get().type);
							if (abs_type != null && ts == "mem.Ptr"){
								params = parseMeta(metaParams, ts);
								offset += params.dx;
								[macro Memory.getI32($i{context} + $v{offset}), macro (Memory.setI32($i{context} + $v{offset}, v))];
							}else{
								null;
							}
						}
					case TEnum(e, _):
						ts = Std.string(e);
						params = parseMeta(metaParams, ts);
						offset += params.dx;
						params.width = 1;
						var epr = Context.getTypedExpr({expr:TTypeExpr(TEnumDecl(e)), t:t, pos:f.pos});
						[macro haxe.EnumTools.createByIndex($epr, Memory.getByte($i{context} + $v{offset})),
							macro Memory.setByte($i{context} + $v{offset}, Type.enumIndex(v))];

					case TInst(s, _):
						ts = Std.string(s);
						params = parseMeta(metaParams, ts);
						offset += params.dx;
							switch(ts) {
							case "String":
							[macro Ram.readUTFBytes($i{context} + $v{offset}, $v{params.width})
								,macro Ram.writeString($i{context} + $v{offset}, $v{params.width} ,v)];
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
										[macro{[for (i in 0...$v{params.nums}) Memory.$sget($i{context} + $v{offset} + i)];
										}, macro{ for (i in 0...$v{params.nums}) Memory.$sset($i{context} + $v{offset} + i, v[i]); }];
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
					if (f.access.length == 0) f.access = [APublic];
					var getter = exprs[0];
					var setter = exprs[1];
					var getter_name = "get_" + f.name;
					var setter_name = "set_" + f.name;

					if (!all_in_map.exists(getter_name))
					fields.push({
						name : getter_name,
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

					if (!all_in_map.exists(setter_name))
					fields.push({
						name: setter_name,
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
		//if (offset == 0) return null;
		fields.push({
			name : "CAPACITY",
			doc:  "== " + $v{offset},
			access: [AStatic, AInline, APublic],
			kind: FVar(macro :Int, macro $v{offset}),
			pos: here()
		});

	if(offset > 0){
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

		var constructor = all_in_map.get(abs_type == null ? "new" : "_new");
		if(constructor == null){
			fields.push({
				name : "new",
				access: [AInline, APublic],
				kind: FFun({
					args: [],
					ret : null,
					expr: macro {
						$i{context} = mem.Malloc.make(CAPACITY, true);
					}
				}),
				pos: here()
			});
		}else if (constructor.access.indexOf(AInline) == -1){
			Context.warning("Suggestion: add **inline** for " + cls.name + "'s constructor new" , here());
		}

		if (!all_in_map.exists("free"))
			fields.push({
				name : "free",
				doc: "call Pof.free() to release memory",
				access: [AInline, APublic],
				kind: FFun({
					args: [],
					ret : null,
					expr: macro {
						mem.Malloc.free($i{context});
						$i{context} = 0;
					}
				}),
				pos: here()
			});

		if (abs_type != null){
			fields.push({
				name : "__toOrgin",
				meta: [{name:":to", pos: here()}],
				access: [AInline],
				kind: FFun({
					args: [],
					ret : Context.toComplexType(abs_type.type),
					expr: macro {
						return this;
					}
				}),
				pos: here()
			});
		}else if (!all_in_map.exists(context)){
			fields.push({
				name : context,
				access: [APrivate],
				kind: FProp("default", "null",macro :mem.Ptr),
				pos: here()
			});
		}
	}
		#if !no2out
			var prep = abs_type == null ?  (macro null) : (macro if (0 >= this) return "null");
			var block:Array<Expr> = [];
			for (k in all_fields.iterator()){
				var node = Reflect.field(attrs, k);
				var _w = Ut.hexWidth(offset);
				var _dx = StringTools.hex( node.offset, _w);
				var _len = node.len * node.bytes;
				var _end = StringTools.hex(node.offset + _len, _w);
				block.push(macro buf.push("offset: 0x" + $v{_dx} + " - 0x" + $v{_end} + ", bytes: "+ $v{_len} +", " + $v{k} + ": " + $i{k} + "\n"));
			}
			fields.push({
				name : "__toOut",
				access: [AInline, APublic],
				kind: FFun({
					args: [],
					ret : macro :String,
					expr: macro {
						$prep;
						var buf = ["--- " + $v{abs_type == null ? cls.name : abs_type.name } + ".CAPACITY: " + $v{offset} + ", addr: " + $i{context} +
							", BLOCK SPACE: "+ @:privateAccess (mem.Malloc.indexOf($i{context}).size - mem.Malloc.Block.CAPACITY) +"\n"];
						$b{block};
						return buf.join("");
					}
				}),
				pos: here()
			});
		#end
		return fields;
	}
	#end
}