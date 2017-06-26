package mem.cpp;

import cpp.RawConstPointer;

@:enum abstract LocaleCategory(Int) {
	var LC_ALL = 0;
	var LC_COLLATE = 1;
	var LC_CTYPE = 2;
	var LC_MONETARY = 3;
	var LC_NUMERIC = 4;
	var LC_TIME = 5;
}

@:include("./lib/mbs.h")
extern class Mbs {
	@:native("::setlocale")
	private static function _setlocale(cat: LocaleCategory, locale: RawConstPointer<cpp.Char>): RawConstPointer<cpp.Char>;

	static inline function setlocale(cat: LocaleCategory, locale: String): Void {
		_setlocale(cat, cpp.NativeString.raw(locale));
	}

	@:native("::utf8tombs") static function utf8tombs(str: String): String;
	@:native("::mbstoutf8") static function mbstoutf8(str: String): String;
}
