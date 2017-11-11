package raw;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import haxe.macro.PositionTools.here;
import StringTools.hex;
import raw._macros.IDXParams;
#end

/**
Supported field types:

```
mem.Ptr          @idx(sizeof = 4, offset = 0):
  - or "abstract Some(Ptr){}"

Bool:            @idx(sizeof = 1, offset = 0)
Enum             @idx(sizeof = 1, offset = 0)
String           @idx(bytes  = 1, offset = 0)
Int: (1), 2, 4   @idx(sizeof = 1, offset = 0)
Float: (4), 8    @idx(sizeof = 4, offset = 0)
AU8              @idx(count  = 1, offset = 0) [bytesLength = count * sizeof(1)]
AU16             @idx(count  = 1, offset = 0) [bytesLength = count * sizeof(2)]
AI32             @idx(count  = 1, offset = 0) [bytesLength = count * sizeof(4)]
AF4              @idx(count  = 1, offset = 0) [bytesLength = count * sizeof(4)]
AF8              @idx(count  = 1, offset = 0) [bytesLength = count * sizeof(8)]
Ucs2             @idx(count  = 1, offset = 0) [bytesLength = count * sizeof(2)]
```
*/
class Struct {
#if macro
	static inline var IDX = "idx";

	static var def = new haxe.ds.StringMap<IDXParams>();

	static function expr_wrap(e: Expr, unsafe: Bool): Expr {
		return unsafe ? { expr: ECast(e, null), pos: e.pos } : e;
	}

	static function StrPadd(s: String, len: Int, pad: Int = " ".code): String {
		if (s.length < len) {
			var b = haxe.io.Bytes.alloc(len - s.length);
			b.fill(0, b.length, pad);
			return b.toString() + s;
		}
		return s;
	}

	static function toFull(pack, name) {
		return pack.length == 0 ? name : pack.join(".") + "." + name;
	}

	// example: @:build(mem.Struct.make(mem.Mini))
	static public function make(?fixed: {bulk: Int, ?extra: Int}, context:String = "addr") {
		var cls:ClassType = Context.getLocalClass().get();
		if (cls.isInterface) return null;

		var alloc_s = "Raw";
		var abs_type: AbstractType = null;
		switch (cls.kind) {
			case KAbstractImpl(_.get() => t):
				abs_type = t;
				if (fixed != null) alloc_s = toFull(t.pack, t.name);
			default:
		}
		var alloc = macro $i{ alloc_s };
		if (abs_type != null) context = "this";

		var ct_ptr = macro :raw.Ptr;
		var fields:Array<Field> = Context.getBuildFields();
		var offset_first = 0;
		var offset_first_ready = false;
		var offset = 0;
		var flexible = false;
		var param = new IDXParams();
		var out_block: Array<Expr> = [];

		var all_fields = new haxe.ds.StringMap<Bool>();
		for (f in fields) all_fields.set(f.name, true);

		var filter = fields.filter(function(f) {
			switch (f.kind) {
			case FVar(_, _):
				if (f.meta != null) {
					for (meta in f.meta) {
						if (meta.name == IDX) {
							if (f.access.indexOf(AStatic) > -1) Context.error("doesn't support static properties", f.pos);
							return true;
						}
					}
				}
			default:
			}
			return false;
		});

		for (f in filter) {
			var unsafe_cast = false;
			param.clear();
			for (meta in f.meta) {
				if (meta.name == IDX) {
					param.parse(meta);
				}
			}

			switch (f.kind) {
			case FVar(vt = TPath({pack: pack, name: name, params:arrType}), _):
				var path = pack.copy();
				path.push(name);
				var t = Context.getType(path.join("."));
				var ts = "";
				var exprs: Array<Expr> = null;
				var setter_value: Expr = macro v;
				setter_value.pos = f.pos;
				switch (t) {
				case TAbstract(a, _):
					var at = a.get();
					if (at.meta.has(":enum")) {
						switch (Context.followWithAbstracts(t)) {
						case TAbstract(_na , _):
							var _fas = _na.toString();
							if (_fas == "Int" || _fas == "Float") {
								unsafe_cast = true;
								setter_value = expr_wrap(setter_value, true);
								a = _na;
							}
						case _:
						}
					}

					ts = Std.string(a);

					switch (ts) {
					case "Bool":
						param.sizeOf = 1;
						offset += param.offset;
						exprs = [macro Memory.getByte($i{context} + $v{offset}) != 0, macro Memory.setByte($i{context} + $v{offset}, $setter_value ? 1 : 0)];
					case "Int":
						offset += param.offset;
						var sget = "getByte", sset = "setByte";
						switch (param.sizeOf) {
						case 2: sget = "getUI16"; sset = "setI16";
						case 4: sget = "getI32"; sset = "setI32";
						default: param.sizeOf = 1;
						}
						exprs = [macro Memory.$sget($i{context} + $v{offset}), macro (Memory.$sset($i{context} + $v{offset}, $setter_value))];
					case "Float":
						offset += param.offset;
						var sget = "getFloat", sset = "setFloat";
						if (param.sizeOf == 8) {
							sget = "getDouble"; sset = "setDouble";
						} else {
							param.sizeOf = 4;
						}
						exprs = [macro Memory.$sget($i{ context } + $v{ offset } ), macro (Memory.$sset($i{ context } + $v{ offset }, $setter_value))];
					case "raw.Ptr":
						unsafe_cast = true;
						setter_value = expr_wrap(setter_value, true);
						param.sizeOf = 4;
						offset += param.offset;
						exprs = [macro (Memory.getI32($i{context} + $v{offset})), macro (Memory.setI32($i{context} + $v{offset}, $setter_value))];
					default:
						var ats = TypeTools.toString(at.type);
						if (ats == "raw.Ptr") {
							unsafe_cast = true;
							setter_value = expr_wrap(setter_value, true);
							if (at.meta.has(IDX)) {
								var cfg = def.get(ts);
								if (cfg == null) {
									cfg = new IDXParams();          // parse meta from the class define, see: [mem.Ucs2, AU8, AU16, AI32 ...]
									cfg.parse(at.meta.extract(IDX)[0]);
									def.set(ts, cfg);
								}
								if (cfg.unSupported()) Context.error("Type (" + ts +") is not supported for field: " + f.name , f.pos);
								if (cfg.isArray()) {                // force override
									param.count  = param.sizeOf;    // first argument is "count";
									param.sizeOf = cfg.sizeOf;
									param.extra  = cfg.extra;
								}
							}

							if (param.isArray()) {                  // Struct Block
								if (abs_type != null) {
									var apath = abs_type.pack.copy();
									apath.push(abs_type.name);
									if (ts == apath.join(".")) Context.error("Nested error", f.pos);
								}

								if (param.count == 0) {
									if (f == filter[filter.length - 1]) {
										flexible = true;
									} else {
										Context.error("the flexible array member is supports only for the final field.", f.pos);
									}
								}
								offset += param.offset;
								exprs = [(macro ($i{context} + $v{offset})), null];
							} else {                                // Point to Struct
								if (param.argc == 0) param.sizeOf = 4;
								if (param.sizeOf != 4) Context.error("first argument of @idx must be empty or 4.", f.pos);
								offset += param.offset;
								exprs = [(macro Memory.getI32($i{context} + $v{offset})), (macro Memory.setI32($i{context} + $v{offset}, $setter_value))];
							}
						}
					}
				case TEnum(e, _):
					if (!Context.unify(t, Context.getType("haxe.Constraints.FlatEnum")))
						Context.error("Must be FlatEnum", f.pos);
					ts = Std.string(e);
					param.sizeOf = 1;
					offset += param.offset;
					var ex = Context.getTypedExpr( { expr:TTypeExpr(TEnumDecl(e)), t:t, pos:f.pos } );
					exprs = [macro haxe.EnumTools.createByIndex($ex, Memory.getByte($i{context} + $v{offset})),
						macro Memory.setByte($i{context} + $v{offset}, Type.enumIndex(v))
					];

				case TInst(s, _):
					ts = Std.string(s);
					if (ts == "String") {
						offset += param.offset;
						param.count = param.sizeOf;
						param.sizeOf = 1;
						exprs = [macro Raw.readUtf8($i{context} + $v{offset}, $v{param.count}),
							macro Raw.writeUtf8($i{context} + $v{offset}, v, $v{param.count})
						];
					}
				default:
				}

				if (exprs == null) {
					Context.error("Type (" + ts +") is not supported for field: " + f.name , f.pos);
				} else {
					if (param.bytes == 0 && flexible == false) Context.error("Something was wrong", f.pos);

					if (offset_first_ready == false) {
						if (offset < 0) offset_first = offset; // else offset = 0;
						offset_first_ready = true;
					}
					if (offset < offset_first) Context.error("Out of range", f.pos);

					var getter = expr_wrap(exprs[0], unsafe_cast);
					var setter = exprs[1];
					var getter_name = "get_" + f.name;
					var setter_name = "set_" + f.name;
					f.kind = FProp("get", (setter == null ? "never" : "set"), vt, null);
					if (f.access.length == 0 && f.name.charCodeAt(0) != "_".code) f.access = [APublic];

					if (!all_fields.exists(getter_name))
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
						pos: f.pos
					});

					if (setter!= null && !all_fields.exists(setter_name))
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
						pos: f.pos
					});

					fields.push({
						name : "__" + f.name.toUpperCase() + "_OFFSET",
						access: [AStatic, AInline, APublic],
						doc: " == " + $v{offset},
						kind: FVar(macro :Int, macro $v{offset}),
						pos: f.pos
					});

					fields.push({
						name : "__" + f.name.toUpperCase() + "_BYTES_LENGTH",
						access: [AStatic, AInline, APublic],
						doc: "bytesLength == " + $v{param.bytes},
						kind: FVar(macro :Int, macro $v{param.bytes}),
						pos: f.pos
					});

					{  // .__toOut() for debug
						var _start = offset               >= 0 ? "0x" + hex(offset              , 4) : (StrPadd("" +  offset               , 6));
						var _end   = offset + param.bytes >= 0 ? "0x" + hex(offset + param.bytes, 4) : (StrPadd("" + (offset + param.bytes), 6));
						var _exval = param.isArray() ? macro "[...]" : macro $i{ f.name };
						out_block.push( macro buf.push(  // buf was defined inside __toOut
							  "offset: [" + $v{ _start } + " - " + $v{ _end } + "), "
							+  "bytes: " + $v{ StrPadd("" + param.bytes, 2) } + ", "
							+ $v{ f.name } + ": " + $_exval + "\n"
						));
					}

					offset += param.bytes;
				}

			default:
			}

		}

		if (offset - offset_first <= 0) return null;

		fields.push({
			name : "CAPACITY",    // some similar "sizeof struct"
			doc:  "== " + $v{offset - offset_first},
			access: [AStatic, AInline, APublic],
			kind: FVar(macro :Int, macro $v{offset - offset_first}),
			pos: cls.pos
		});

		if (fixed != null && abs_type != null) {
			alloc = macro $alloc.__fx;
			if (fixed.extra == null) fixed.extra = 0;
			if (fixed.bulk < 1) fixed.bulk = 1;
			var f_sz = Ut.align(fixed.extra + offset - offset_first, 8);
			fields.push({
			name : "__fx",
			access: [AStatic],
			kind: FVar(macro :raw.Fixed, macro @:privateAccess new raw.Fixed($v{f_sz}, $v{fixed.bulk})),
			pos: cls.pos
			});
		}

		fields.push({
			name : "OFFSET_FIRST",// This field may be "Negative"
			doc:  "== " + $v{offset_first},
			access: [AStatic, AInline, APublic],
			kind: FVar(macro :Int, macro $v{offset_first}),
			pos: cls.pos
		});

		fields.push({
			name : "OFFSET_END",  // If you want to add a flexible field at the end of the struct
			doc:  "== " + $v{offset},
			access: [AStatic, AInline, APublic],
			kind: FVar(macro :Int, macro $v{offset}),
			pos: cls.pos
		});

		fields.push({
			name : "FLEXIBLE",    // The last field is a flexible array(AU8/AU16/...) member
			access: [AStatic, AInline, APublic],
			kind: FVar(macro :Bool, macro $v{flexible}),
			pos: cls.pos
		});

		if (!all_fields.exists(abs_type == null ? "new" : "_new")) {
			fields.push({
				name : "new",
				access: [AInline, APublic],
				kind: flexible && fixed == null ? FFun({
					args: [{name: "extra", type: macro :Int}],
					ret : null,
					expr: macro {
						mallocAbind(CAPACITY + extra, true);
					}})    :     FFun({
					args: [],
					ret : null,
					expr: macro {
						mallocAbind(CAPACITY, true);
					}}),
				pos: here()
			});
		}

		if (!all_fields.exists("mallocAbind")) // malloc and bind Context
			fields.push({
				name : "mallocAbind",
				doc: ' help for custom constructor',
				access: [AInline, APrivate],
				kind: FFun({
				args: [{name: "entry_size", type: macro :Int}, {name: "zero", type: macro :Bool}],
					ret : macro :Void,
					expr: macro {
						$i{context} = $alloc.malloc(entry_size, zero) - OFFSET_FIRST; // offset_first <= 0
					}
				}),
				pos: here()
			});

		if (!all_fields.exists("realEntry"))
			fields.push({
				name : "realEntry",
				doc: ' for "Malloc.calcEntrySize(entry)", or "Fraw.free(entry)"',
				access: [AInline, APublic],
				kind: FFun({
					args: [],
					ret : macro :raw.Ptr,
					expr: macro {
						return $i{context} + OFFSET_FIRST;
					}
				}),
				pos: here()
			});


		if (!all_fields.exists("free"))
			fields.push({
				name : "free",
				doc: ' == .free( this.realEntry() );',
				access: [AInline, APublic],
				kind: FFun({
					args: [],
					ret : null,
					expr: macro {
						$alloc.free(realEntry());
						$i{context} = cast raw.Ptr.NUL;
					}
				}),
				pos: here()
			});

		if (!all_fields.exists("isNull"))
			fields.push({
				name : "isNull",
				doc: ' $context == 0',
				access: [AInline, APublic],
				kind: FFun({
					args: [],
					ret : macro :Bool,
					expr: macro {
						return ($i{context}: raw.Ptr) == raw.Ptr.NUL;
					}
				}),
				pos: here()
			});

		if (abs_type == null && all_fields.exists(context) == false) { //  for class Some implements Struct{}
			fields.push({
				name : context,
				access: [APublic],
				kind: FProp("default", "null",macro :raw.Ptr),
				pos: here()
			});
		}

		var clsname = abs_type == null ? cls.name : abs_type.name;
		fields.push({
			name : "__toOut", // for debug
			meta: [{name: ":dce", pos: here()}],
			access: [APublic],
			kind: FFun({
				args: [],
				ret : macro :String,
				expr: fixed == null ? (macro {
					var actual_space = "";
					if ($v{clsname} != "Block") @:privateAccess {
						var b = raw.Malloc.indexOf($i{context} + OFFSET_FIRST);
						if (b != raw.Ptr.NUL)
							actual_space = "SIZEOF: " + (b.size - raw.Malloc.Block.CAPACITY) + ", ";
					}
					var buf = ["\n--- [" + $v{ clsname } + "] CAPACITY: " + $i{ "CAPACITY" } + ", OFFSET_FIRST: " + OFFSET_FIRST
						+ ", OFFSET_END: " + OFFSET_END  + $v{flexible ? ", FLEXIBLE: True" : ""}
						+ "\n--- " + actual_space + "ADDR: " + ($i{ context } + OFFSET_FIRST)
						+ "\n"];
					$a{out_block};
					return buf.join("");
				}) : (macro {
					var buf = ["\n--- [" + $v{ clsname } + " (Fixed)] CAPACITY: " + $i{ "CAPACITY" } + ", SIZEOF: " + $v{ Ut.align(fixed.extra + offset - offset_first, 8) }
					+ ", COUNT: " + $v{ fixed.bulk << 5 }
					+ ", ADDR: " + ($i{ context } + OFFSET_FIRST)
					+ "\n"];
					$a{out_block};
					return buf.join("");
				})
			}),
			pos: here()
		});

		return fields;
	}
#end
}