package mem;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import mem._macros.IDXParams;
import StringTools.hex;
import StringTools.rpad;
import haxe.macro.PositionTools.here;
#end

/**
Supported field types:

```
mem.Ptr          @idx(sizeof = 4, offset = 0):
  - or "abstract XXX(Ptr){}"

Bool:            @idx(sizeof = 1, offset = 0)
String           @idx(bytes  = 1, offset = 0)
UCString         @idx(count  = 1, offset = 0, sizeof = 2)
Int: (1), 2, 4   @idx(sizeof = 1, offset = 0)
Float: (4), 8    @idx(sizeof = 4, offset = 0)
AU8              @idx(count  = 1, offset = 0) [bytesLength = count * sizeof(1)]
AU16             @idx(count  = 1, offset = 0) [bytesLength = count * sizeof(2)]
AI32             @idx(count  = 1, offset = 0) [bytesLength = count * sizeof(4)]
AF4              @idx(count  = 1, offset = 0) [bytesLength = count * sizeof(4)]
AF8              @idx(count  = 1, offset = 0) [bytesLength = count * sizeof(8)]
```
*/
class Struct {
#if macro
	static inline var IDX = "idx";

	static var defs = new haxe.ds.StringMap<IDXParams>();

	static function exprCast(e: Expr, unsafe = true): Expr return unsafe ? { expr: ECast(e, null), pos: e.pos } : e;

	static function toFull(pack, name) return pack.length == 0 ? name : pack.join(".") + "." + name;

	static function isPtrType(t: Type) {
		return if (TypeTools.toString(t) == "mem.Ptr") {
			true;
		} else {
			switch(t) {
			case TAbstract(a, _): isPtrType(a.get().type);
			default: false;
			}
		}
	}

	static function fatalError(msg, pos) { return Context.fatalError("[struct]: " + msg, pos); }

	static public function build() {
		var cls:ClassType = Context.getLocalClass().get();
		var abst = switch (cls.kind) {
			case KAbstractImpl(_.get() => t) if ( isPtrType(t.type) ):
				t;
			default:
				fatalError("UnSupported Type", cls.pos);
		}
		var ct_ptr = macro :mem.Ptr;
		var ct_int = macro :Int;
		var ct_bool= macro :Bool;

		var fields:Array<Field> = Context.getBuildFields();
		var offset_first = 0;
		var offset = 0;
		var flexible = false; // flexible struct
		var idx = new IDXParams();
		var reserves = new haxe.ds.StringMap<Bool>();

		var fds = fields.filter(function(f) {
			reserves.set(f.name, true);
			switch (f.kind) {
			case FVar(_, _) if (f.meta != null):
				for (meta in f.meta) {
					if (meta.name == IDX) {
						if (f.access.indexOf(AStatic) > -1)
							fatalError("doesn't support static properties", f.pos);
						return true;
					}
				}
			default:
			}
			return false;
		});

		for (f in fds) {
			idx.reset();
			for (meta in f.meta) {
				if (meta.name == IDX) {
					idx.parse(meta);
					break; // only first @idx
				}
			}
			var unsafe_cast = false;
			switch (f.kind) {
			case FVar(vt = TPath(path), _):
				var t = Context.getType(toFull(path.pack, path.name));
				var ts = "";
				var exprs: Array<Expr> = null;
				var setter_value: Expr = macro @:pos(f.pos) v;
				switch (t) {
				case TAbstract(a, _):
					var at = a.get();
					if (at.meta.has(":enum")) { // for enum abstract XXX{}
						switch (Context.followWithAbstracts(t)) {
						case TAbstract(sa , _):
							var sas = sa.toString();
							if (sas == "Int" || sas == "Float") {
								unsafe_cast = true;
								setter_value = exprCast(setter_value);
								a = sa;
							}
						case _:
						}
					}
					ts = a.toString();
					switch (ts) {
					case "Bool":
						idx.sizeOf = 1;
						offset += idx.offset;
						exprs = [macro (this+$v{offset}).getByte() != 0, macro (this+$v{offset}).setByte($setter_value ? 1 : 0)];
					case "Int":
						offset += idx.offset;
						var sget = "getByte", sset = "setByte";
						switch (idx.sizeOf) {
						case 2: sget = "getUI16"; sset = "setI16";
						case 4: sget = "getI32"; sset = "setI32";
						default: idx.sizeOf = 1;
						}
						exprs = [macro (this+$v{offset}).$sget(), macro (this+$v{offset}).$sset($setter_value)];
					case "Float":
						offset += idx.offset;
						var sget = "getFloat", sset = "setFloat";
						if (idx.sizeOf == 8) {
							sget = "getDouble"; sset = "setDouble";
						} else {
							idx.sizeOf = 4;
						}
						exprs = [macro (this+$v{offset}).$sget(), macro (this+$v{offset}).$sset($setter_value)];

					case "mem.Ptr":
						unsafe_cast = true;
						setter_value = exprCast(setter_value);
						idx.sizeOf = 4;
						offset += idx.offset;
						exprs = [macro (this+$v{offset}).getI32(), macro (this+$v{offset}).setI32($setter_value)];
					case "mem.UCString":
						idx.count = idx.sizeOf; // first param
						idx.sizeOf = 2;
						offset += idx.offset;
						vt = macro :String;     // convert UCString to String.
						exprs = [macro mem.Ucs2.getString(this + $v{offset}, $v{idx.bytes >> 1}),
							macro mem.Ucs2.ofString(this + $v{offset}, $v{idx.bytes >> 1}, $setter_value)
						];
					default:
						if ( isPtrType(at.type) ) {
							unsafe_cast = true;
							setter_value = exprCast(setter_value);
							if (at.meta.has(IDX)) {              // parse meta from the class define, see: [AU8, AU16, AI32]
								var FORCE = defs.get(ts);
								if (FORCE == null) {
									FORCE = new IDXParams();
									FORCE.parse(at.meta.extract(IDX)[0]);
									defs.set(ts, FORCE);
								}
								if (FORCE.unSupported())
									fatalError("Type (" + ts +") is not supported for field: " + f.name , f.pos);
								if (FORCE.isArray()) {           // force override
									idx.count  = idx.sizeOf;     // first argument is "count";
									idx.sizeOf = FORCE.sizeOf;
									idx.extra  = FORCE.extra;
								}
							}
							if (idx.isArray()) {                 // Struct Block
								if (ts == toFull(abst.pack, abst.name))
									fatalError("Nested error", f.pos);
								if (idx.count == 0) {
									if (f == fds[fds.length - 1]) {
										flexible = true;
									} else {
										fatalError("the flexible array member is supports only for the final field.", f.pos);
									}
								}
								offset += idx.offset;
								exprs = [(macro (this + $v{offset})), null];
							} else {                             // Point to Struct
								if (idx.argc == 0) idx.sizeOf = 4;
								if (idx.sizeOf != 4)
									fatalError("first argument of @idx must be empty or 4.", f.pos);
								offset += idx.offset;
								exprs = [macro (this+$v{offset}).getI32(), macro (this+$v{offset}).setI32($setter_value)];
							}
						}
					}
				case TInst(s, _):
					ts = Std.string(s);
					if (ts == "String") {
						offset += idx.offset;
						idx.count = idx.sizeOf;
						idx.sizeOf = 1;
						exprs = [macro mem.Utf8.getString(this + $v{offset}, $v{idx.count}),
							macro mem.Utf8.ofString(this + $v{offset}, $v{idx.count}, v)
						];
					}
				default:
					ts = haxe.macro.TypeTools.toString(t); // for error.
				}

				if (exprs == null) {
					fatalError("Type (" + ts +") is not supported for field: " + f.name , f.pos);
				} else {
					if (idx.bytes == 0 && flexible == false)
						fatalError("Something is wrong", f.pos);
					if (f == fds[0]) {
						if (offset > 0)
							fatalError("offset of the first field can only be <= 0",f.pos);
						offset_first = offset;
					} else if (offset < offset_first) {
						fatalError("offset is out of range", f.pos);
					}
					var getter = exprCast(exprs[0], unsafe_cast);
					var setter = exprs[1];
					var getter_name = "get_" + f.name;
					var setter_name = "set_" + f.name;
					// overwrite
					f.kind = FProp("get", (setter == null ? "never" : "set"), vt, null);
					if (f.access.length == 0) {
						f.access = f.name.charCodeAt(0) == "_".code ? [APrivate] : [APublic];
					}
					if (!reserves.exists(getter_name))
						fields.push({
							name : getter_name,
							access: [AInline, APrivate],
							kind: FFun({
								args: [],
								ret : vt,
								expr: macro {
									return $getter;
								}
							}),
							pos: f.pos
						});
					if (setter!= null && !reserves.exists(setter_name))
						fields.push({
							name: setter_name,
							access: [AInline, APrivate],
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
						name : "OFFSETOF_" + f.name.toUpperCase(),
						access: [AStatic, AInline, APublic],
						doc: "" + $v{offset},
						kind: FVar(macro :Int, macro $v{offset}),
						pos: f.pos
					});
					offset += idx.bytes;
				}
			default:
			}

		}
		if (offset - offset_first <= 0) return null;
		fields.push({
			name : "CAPACITY",    // similar "sizeof struct"
			doc:  "" + $v{offset - offset_first},
			access: [AStatic, AInline, APublic],
			kind: FVar(ct_int, macro $v{offset - offset_first}),
			pos: cls.pos
		});
		fields.push({
			name : "OFFSET_FIRST",// Relative to "this"
			doc:  "" + $v{offset_first},
			access: [AStatic, AInline, APublic],
			kind: FVar(ct_int, macro $v{offset_first}),
			pos: cls.pos
		});
		fields.push({
			name : "OFFSET_END",  // Relative to "this"
			doc:  "" + $v{offset},
			access: [AStatic, AInline, APublic],
			kind: FVar(ct_int, macro $v{offset}),
			pos: cls.pos
		});
		if (!reserves.exists("_new"))
			fields.push({
				name : "new",
				access: [AInline, APublic],
				kind: flexible ? FFun({
					args: [{name: "extra", type: ct_int}],
					ret : null,
					expr: (macro this = alloc(CAPACITY + extra, true))
				}) : FFun({
					args: [],
					ret : null,
					expr: (macro this = alloc(CAPACITY, true))
				}),
				pos: cls.pos
			});
		if (!reserves.exists("free"))
			fields.push({
				name : "free",
				access: [AInline, APublic],
				kind: FFun({
					args: [],
					ret : macro: Void,
					expr: (macro Mem.free(realptr()))
				}),
				pos: cls.pos
			});
		if (!reserves.exists("realptr")) //
			fields.push({
				name : "realptr",
				access: [AInline, APrivate],
				kind: FFun({
					args: [],
					ret : ct_ptr,
					expr: (macro return this + OFFSET_FIRST)
				}),
				pos: cls.pos
			});
		if (!reserves.exists("alloc")) { // private
			fields.push({
				name : "alloc",
				access: [AInline, APrivate],
				kind: FFun({
					args: [{name: "size", type: ct_int}, {name: "clean", type: ct_bool}],
					ret : ct_ptr,
					expr: macro return Mem.malloc(size, clean) - OFFSET_FIRST
				}),
				pos: cls.pos
			});
		}
		return fields;
	}
#end
}
