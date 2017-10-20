package raw._macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
//using haxe.macro.Tools;
#end

class FixedMacros {
#if macro
	@:deprecated public static function gen() {
		var pos = Context.currentPos();
		var sizof = 0;
		var count = 0;
		var info: TypePath;
		var mod: String;
		switch (Context.getLocalType()) {
		case TInst(_, [TAbstract(_.get() => t, _), TInst(_.get() => { kind: KExpr(macro $v{(i: Int)}) },_)]):
			var n = Std.parseInt(i);
			sizof = n & 0xFFFF;
			count = (n >> 16) & 0xFFFF;
			info = { pack: t.pack, name: t.name + "Alc" };
			mod = t.pack.length == 0 ? t.module : info.pack.join(".") + "." + t.module;
			//trace('mod: ${t.module}, pack: ${t.pack}, name: ${t.name}, sizeof: $sizof, count: $count');
		default:
			Context.error("Class expected", pos);
		}
		return make(sizof, count, info, mod, pos);
	}

	public static function make(sizof, count, info, mod, pos) {
		sizof = Ut.align(sizof, 8);
		count = Ut.align(count, 8);
		if (count < 32) count = 32;
		var ct_ptr = macro :raw.Ptr;
		var ct_int = macro :Int;
		var ct_abs = TPath(info);
		var ct_bool = macro :Bool;
		var ct_void = macro :Void;
		var tdc: TypeDefinition = {
			pack: info.pack,
			name: info.name,
			pos: pos,
			meta: [{name: ":dce", pos: pos}],
			fields: [],
			kind: TDAbstract(ct_ptr, [], [ct_ptr])
		}

		// var next(get, set): XXX; -------
		tdc.fields.push({
			name: "next",
			pos : pos,
			access: [APublic],
			kind: FProp("get", "set", ct_abs)
		});
		tdc.fields.push({
			name: "get_next",
			pos : pos,
			access: [AInline],
			kind: FFun({
				args: [],
				ret : ct_abs,
				expr: macro return cast raw.Ptr.Memory.getI32(this)
			})
		});
		tdc.fields.push({
			name: "set_next",
			pos : pos,
			access: [AInline],
			kind: FFun({
				args: [{name: "c", type: ct_abs}],
				ret : ct_abs,
				expr: macro {
					raw.Ptr.Memory.setI32(this, cast c);
					return c;
				}
			})
		});

		// var frags(get, set): Int; -------
		tdc.fields.push({
			name: "frags",
			pos : pos,
			access: [APublic],
			kind: FProp("get", "set", ct_int)
		});
		tdc.fields.push({
			name: "get_frags",
			pos : pos,
			access: [AInline],
			kind: FFun({
				args: [],
				ret : ct_int,
				expr: macro return raw.Ptr.Memory.getUI16(this + 4)
			})
		});
		tdc.fields.push({
			name: "set_frags",
			pos : pos,
			access: [AInline],
			kind: FFun({
				args: [{name: "v", type: ct_int}],
				ret : ct_int,
				expr: macro {
					raw.Ptr.Memory.setI16(this + 4, v);
					return v;
				}
			})
		});
		// var frags(get, set): Int; -------
		tdc.fields.push({
			name: "caret",
			pos : pos,
			access: [APublic],
			kind: FProp("get", "set", ct_int)
		});
		tdc.fields.push({
			name: "get_caret",
			pos : pos,
			access: [AInline],
			kind: FFun({
				args: [],
				ret : ct_int,
				expr: macro return raw.Ptr.Memory.getUI16(this + 6)
			})
		});
		tdc.fields.push({
			name: "set_caret",
			pos : pos,
			access: [AInline],
			kind: FFun({
				args: [{name: "v", type: ct_int}],
				ret : ct_int,
				expr: macro {
					raw.Ptr.Memory.setI16(this + 6, v);
					return v;
				}
			})
		});

		tdc.fields.push({
			name: "CAPACITY",
			pos : pos,
			access: [APublic, AStatic, AInline],
			kind: FVar(ct_int, macro $v{8})
		});
		tdc.fields.push({
			name: "SIZEOF",
			pos : pos,
			access: [APublic, AStatic, AInline],
			kind: FVar(ct_int, macro $v{sizof})
		});
		tdc.fields.push({
			name: "COUNT",
			pos : pos,
			access: [APublic, AStatic, AInline],
			kind: FVar(ct_int, macro $v{count})
		});

		// var entry(get, never): Ptr;
		tdc.fields.push({
			name: "entry",
			pos : pos,
			access: [APublic],
			kind: FProp("get", "never", ct_ptr)
		});
		tdc.fields.push({
			name: "get_entry",
			pos : pos,
			access: [AInline],
			kind: FFun({
				args: [],
				ret : ct_ptr,
				expr: macro return this + (CAPACITY + COUNT)
			})
		});

		// var meta(get, never): Ptr;
		tdc.fields.push({
			name: "meta",
			pos : pos,
			access: [APublic],
			kind: FProp("get", "never", ct_ptr)
		});
		tdc.fields.push({
			name: "get_meta",
			pos : pos,
			access: [AInline],
			kind: FFun({
				args: [],
				ret : ct_ptr,
				expr: macro return this + CAPACITY
			})
		});

		// var rest(get, never): Ptr;
		tdc.fields.push({
			name: "rest",
			pos : pos,
			access: [APublic],
			kind: FProp("get", "never", ct_int)
		});
		tdc.fields.push({
			name: "get_rest",
			pos : pos,
			access: [AInline],
			kind: FFun({
				args: [],
				ret : ct_int,
				expr: macro return COUNT - caret + frags
			})
		});

		// functions
		tdc.fields.push({
			name: "new",
			pos: pos,
			access: [AInline],
			kind: FFun({
				args: [],
				ret: null,
				expr: macro raw._macros.FixedMacros.newz()
			})
		});
		tdc.fields.push({
			name: "valid",
			pos: pos,
			access: [AInline],
			kind: FFun({
				args: [{name: "p", type: ct_ptr}],
				ret: ct_bool,
				expr: macro raw._macros.FixedMacros.valid(p)
			})
		});

		tdc.fields.push({
			name: "request",
			pos: pos,
			access: [],
			kind: FFun({
				args: [{name: "zero", type: ct_bool}],
				ret: ct_ptr,
				expr: macro raw._macros.FixedMacros.request(zero)
			})
		});

		tdc.fields.push({
			name: "release",
			pos: pos,
			access: [],
			kind: FFun({
				args: [{name: "p", type: ct_ptr}],
				ret: ct_void,
				expr: macro raw._macros.FixedMacros.release(p)
			})
		});

		tdc.fields.push({
			name: "toString",
			pos: pos,
			access: [APublic, AInline],
			kind: FFun({
				args: [],
				ret: macro :String,
				expr: macro raw._macros.FixedMacros.toString()
			})
		});

		// statics
		tdc.fields.push({
			name: "h",
			pos : pos,
			access: [AStatic],
			kind: FVar(ct_abs, macro cast raw.Ptr.NUL)
		});
		tdc.fields.push({
			name: "q",
			pos : pos,
			access: [AStatic],
			kind: FVar(ct_abs, macro cast raw.Ptr.NUL)
		});
		var enew = { expr: ENew(info, []), pos: pos };
		tdc.fields.push({
			name: "create",
			pos: pos,
			access: [AStatic, AInline],
			kind: FFun({
				args: [],
				ret: ct_abs,
				expr: macro return $enew
			})
		});

		tdc.fields.push({
			name: "add",
			pos: pos,
			access: [AStatic],
			kind: FFun({
				args: [{name: "c", type: ct_abs}],
				ret: ct_void,
				expr: macro raw._macros.FixedMacros.add(c)
			})
		});
		tdc.fields.push({
			name: "malloc",
			pos: pos,
			access: [AStatic, APublic],
			kind: FFun({
				args: [{name: "size", type: ct_int}, {name: "zero", type: ct_bool}],
				ret: ct_ptr,
				expr: macro raw._macros.FixedMacros.malloc(p)
			})
		});
		tdc.fields.push({
			name: "free",
			pos: pos,
			access: [AStatic, APublic],
			kind: FFun({
				args: [{name: "p", type: ct_ptr}],
				ret: ct_void,
				expr: macro raw._macros.FixedMacros.free(p)
			})
		});
		tdc.fields.push({
			name: "destory",
			pos: pos,
			access: [AStatic, APublic],
			kind: FFun({
				args: [],
				ret: ct_void,
				expr: macro raw._macros.FixedMacros.destory()
			})
		});

		tdc.fields.push({
			name: "dump",
			pos: pos,
			access: [AStatic, APublic],
			kind: FFun({
				args: [],
				ret: macro: String,
				expr: macro raw._macros.FixedMacros.dump()
			})
		});
		var full= info.pack.length == 0 ? info.name   : info.pack.join(".") + "." + info.name;
		Context.defineType(tdc, mod);
		return Context.toComplexType(Context.getType(full));
	}
#end
	macro public static function request(zero) return macro @:mergeBlock {
		var ret = raw.Ptr.NUL;
		var cr = caret;
		var fg = frags;
		if (cr < COUNT) {
			ret = entry + cr * SIZEOF;
			meta[cr] = 1;
			caret = cr + 1;
		} else if (fg > 0) {
			var start = meta;
			for (i in 0...COUNT) { // in bytes
				if( raw.Ptr.Memory.getByte(start + i) == 0) {
					meta[i] = 1;
					frags = fg - 1;
					ret = entry + i * SIZEOF;
					break;
				}
			}
		}
		if (zero && ret != raw.Ptr.NUL) Raw.memset(ret, 0, SIZEOF);
		return ret;
	}

	macro public static function release(p) return macro @:mergeBlock {
		var i = Std.int((p.toInt() - entry.toInt()) / SIZEOF);
		if (meta[i] == 0) return;
		meta[i] = 0;
		var fg = frags + 1;

		var cr = caret - 1; // last elem. same as `a[a.length - 1]`
		while (fg > 0) {
			if (meta[cr] == 0) {
				-- cr;
				-- fg;
			} else {
				break;
			}
		}
		frags = fg;
		caret = cr + 1;
	}

	macro public static function valid(p) return macro @:mergeBlock {
		var diff = p.toInt() - entry.toInt();
		return diff >= 0 && diff < COUNT * SIZEOF && diff % SIZEOF == 0;
	}

	macro public static function newz() return macro @:mergeBlock {
		this = Raw.malloc(CAPACITY + COUNT + COUNT * SIZEOF, false);
		Raw.memset(this, 0, CAPACITY + COUNT); // next = null, frags = 0, caret = 0;
	}

	macro public static function toString() return macro @:mergeBlock {
		return "SIZEOF: " + SIZEOF + ", COUNT: " + COUNT + ", frags: " + frags + ", caret: " + caret + ", rest: " + rest;
	}
	// statics

	macro public static function malloc(zero) return macro @:mergeBlock {
		var ret = raw.Ptr.NUL;
		var cur = h;
		while (cur != raw.Ptr.NUL) {
			if (cur.caret < COUNT || cur.frags > 0) {
				ret = cur.request(zero);
				break;
			}
			cur = cur.next;
		}
		if (ret == raw.Ptr.NUL) {
			var c = create();
			add(c);
			ret = c.request(zero);
		}
		return ret;
	}

	macro public static function free(p) return macro @:mergeBlock {
		var cur = h;
		while (cur != raw.Ptr.NUL) {
			if (cur.valid(p)) {
				cur.release(p);
				break;
			}
			cur = cur.next;
		}
	}

	macro public static function add(c) return macro @:mergeBlock {
		if (h == raw.Ptr.NUL)
			h = c;
		else
			q.next = c;
		q = c;
	}

	macro public static function destory() return macro @:mergeBlock {
		var cur = h;
		while (cur != raw.Ptr.NUL) {
			var prev = cur;
			cur = cur.next;
			Raw.free(prev);
		}
		h = q = cast raw.Ptr.NUL;
	}

	macro public static function dump() return macro @:mergeBlock {
		var n = 0;
		var r = 0;
		var cur = h;
		while (cur != raw.Ptr.NUL) {
			++ n;
			r += cur.rest;
			cur = cur.next;
		}
		return "[chunk: " + n + ", total: " + (n * (CAPACITY + COUNT + COUNT * SIZEOF))
		+ "Bytes, used: " + (n * COUNT - r) + ", rest: " + r + "]";
	}
}