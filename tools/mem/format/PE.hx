package mem.format;

import mem.Ptr;

#if !macro
@:build(mem.Struct.make())
#end
abstract DOS(Ptr) to Ptr {
	@idx(2) var sign: Int;        // 0x5A4D == "MZ"
	@idx(58)var _sk: AU8;         // skip
	//@idx(2) var cblp: Int;      // Bytes on last page of file
	//@idx(2) var cp  : Int;      // Pages in file
	//@idx(2) var crlc: Int;      // Relocations
	//@idx(2) var cparhdr : Int;  // Size of header in paragraphs
	//@idx(2) var minalloc: Int;  // Minimum extra paragraphs needed
	//@idx(2) var maxalloc: Int;  // Maximum extra paragraphs needed
	//@idx(2) var ss  : Int;      // Initial (relative) SS value
	//@idx(2) var sp  : Int;      // Initial SP value
	//@idx(2) var csum: Int;      // Checksum
	//@idx(2) var ip  : Int;      // Initial IP value
	//@idx(2) var cs  : Int;      // Initial (relative) CS value
	//@idx(2) var lfarlc  : Int;  // File address of relocation table
	//@idx(2) var ovno: Int;      // Overlay number
	//@idx(4) var resv_0  : AU16; // Reserved words. sizeof(2 *  4)
	//@idx(2) var oemid   : Int;  // OEM identifier (for e_oeminfo)
	//@idx(2) var oeminfo : Int;  // OEM information; e_oemid specific
	//@idx(10)var resv_1  : AU16; // Reserved words. sizeof(2 * 10)
	@idx(4) var lfanew  : Int;    // File address of new exe header

	public inline function addrOfNT(): Ptr return this + lfanew;

	public inline function valid():Bool return sign == 0x5A4D;
}

#if !macro
@:build(mem.Struct.make())
#end
abstract NT32(Ptr) to Ptr {    // docs: https://msdn.microsoft.com/en-us/library/windows/desktop/ms680336(v=vs.85).aspx
	@idx(4) var sign                : Int;  // "PE00" 0x00004550

	                           // FILE_HEADER: https://msdn.microsoft.com/en-us/library/windows/desktop/ms680313(v=vs.85).aspx
	@idx(2) var machine             : Machine;
	@idx(2) var numberOfSections    : Int;
	@idx(4) var timeDateStamp       : Int;  // create stamp since 1970-1-1 00:00
	@idx(4) var pointerToSymbolTable: Int;  // if link with Debug
	@idx(4) var numberOfSymbols     : Int;
	@idx(2) var sizeOfOptionalHeader: Int;
	@idx(2) var characteristics     : Int;  // see FILE_HEADER_CHARACTERISTICS

	                           // OPTIONAL_HEADER_32: https://msdn.microsoft.com/en-us/library/windows/desktop/ms680339(v=vs.85).aspx
	@idx(2) var magic               : Magic;
	@idx(1) var majorLinkerVersion  : Int;
	@idx(1) var minorLinkerVersion  : Int;
	@idx(4) var sizeOfCode          : Int;
	@idx(4) var sizeOfInitializedData      : Int;
	@idx(4) var sizeOfUninitializedData    : Int;
	@idx(4) var addressOfEntryPoint        : Int;
	@idx(4) var baseOfCode          : Int;
	@idx(4) var baseOfData          : Int;
	@idx(4) var imageBase           : Int;
	@idx(4) var sectionAlignment    : Int;
	@idx(4) var fileAlignment       : Int;
	@idx(2) var majorOperatingSystemVersion: Int;
	@idx(2) var minorOperatingSystemVersion: Int;
	@idx(2) var majorImageVersion   : Int;
	@idx(2) var minorImageVersion   : Int;
	@idx(2) var majorSubsystemVersion      : Int;
	@idx(2) var minorSubsystemVersion      : Int;
	@idx(4) var win32VersionValue   : Int;
	@idx(4) var sizeOfImage         : Int;
	@idx(4) var sizeOfHeaders       : Int;  // [DOS~SECTION_TABLE], including sizeof all SECTION_TABLE
	@idx(4) var checkSum            : Int;
	@idx(2) var subsystem           : Subsystem;
	@idx(2) var dllCharacteristics  : Int;
	@idx(4) var sizeOfStackReserve  : Int;
	@idx(4) var sizeOfStackCommit   : Int;
	@idx(4) var sizeOfHeapReserve   : Int;
	@idx(4) var sizeOfHeapCommit    : Int;
	@idx(4) var loaderFlags         : Int;
	@idx(4) var numberOfRvaAndSizes : Int;

	@idx(8) var dataDirectory       : AU8;  // http://blog.csdn.net/zfpigpig/article/details/11203249
	@idx(8, -8, "&") var tableExport       : DataDirectory;  // .edata
	@idx(8, "&") var tableImport           : DataDirectory;  // .idata
	@idx(8, "&") var tableResource         : DataDirectory;  // .rsrc
	@idx(8, "&") var tableException        : DataDirectory;  // .pdata
	@idx(8, "&") var tableCertificate      : DataDirectory;  // .reloc
	@idx(8, "&") var tableBaseRelocation   : DataDirectory;  //
	@idx(8, "&") var tableDebug            : DataDirectory;
	@idx(8, "&") var tableArchitecture     : DataDirectory;
	@idx(8, "&") var tableGlobalPtr        : DataDirectory;
	@idx(8, "&") var tableTLS              : DataDirectory;
	@idx(8, "&") var tableLoadConfig       : DataDirectory;
	@idx(8, "&") var tableBoundImport      : DataDirectory;
	@idx(8, "&") var tableIAT              : DataDirectory;
	@idx(8, "&") var tableDelayImportDesc  : DataDirectory;
	@idx(8, "&") var tableCLR              : DataDirectory;
	@idx(8, "&") var tableReserved         : DataDirectory;
    // Remarks: The number of directories is not fixed. Check the "numberOfRvaAndSizes" member before looking for a specific directory.

	                          // SECTION_HEADER: https://msdn.microsoft.com/en-us/library/windows/desktop/ms680341(v=vs.85).aspx

	public function indexOfRVA(rva: Int): SECTION_HEADER {
		var sh: SECTION_HEADER = cast Ptr.NUL;
		for (i in 0...numberOfSections) {
			sh = getSectionHeader(i);
			if (sh.onHere(rva)) return sh;
		}
		return cast Ptr.NUL;
	}

	// dos: addrOfDOS
	public function getEDT(dos: Ptr, sh: SECTION_HEADER): EDT {
		var rva = tableExport.virtualAddress;
		if (sh == Ptr.NUL) sh = indexOfRVA(rva);
		if (sh != Ptr.NUL)
			return EDT.fromPtr(dos + sh.calcPointerToRawData(rva));
		return cast Ptr.NUL;
	}

	// i in [0 ~ numberOfRvaAndSizes)
	public inline function getDataDirectory(i: Int): DataDirectory {
		return DataDirectory.fromPtr((dataDirectory: Ptr) + i * DataDirectory.CAPACITY);
	}

	// i in [0 ~ numberOfSections). Note: make sure `numberOfRvaAndSizes == 16`
	public inline function getSectionHeader(i: Int): SECTION_HEADER {
		return SECTION_HEADER.fromPtr(this + CAPACITY + i * SECTION_HEADER.CAPACITY);
	}

	public inline function valid() return sign == 0x4550 && magic == 0x10b;

	public inline function isDLL() return characteristics & (1 << C_DLL) != 0;

	static public inline function fromPtr(p: Ptr): NT32 return cast p;
}

#if !macro
@:build(mem.Struct.make())
#end
abstract DataDirectory(Ptr) to Ptr {
	@idx(4) var virtualAddress: Int;
	@idx(4) var size          : Int;
	static public inline function fromPtr(p: Ptr): DataDirectory return cast p;
	public inline function toString() return 'virtualAddress: $virtualAddress, size: $size';
}

#if !macro
@:build(mem.Struct.make())
#end
abstract SECTION_HEADER(Ptr) to Ptr {
	@idx(8) var name                 : String;
	@idx(4) var virtualSize          : Int;
	@idx(4) var virtualAddress       : Int;
	@idx(4) var sizeOfRawData        : Int;
	@idx(4) var pointerToRawData     : Int;
	@idx(4) var pointerToRelocations : Int;
	@idx(4) var pointerToLinenumbers : Int;
	@idx(2) var numberOfRelocations  : Int;
	@idx(2) var numberOfLinenumbers  : Int;
	@idx(4) var characteristics      : SECTION_CHARACTERISTICS;

	public function onHere(rva): Bool {
		var va = virtualAddress;
		return rva == va || (rva > va && rva < va + virtualSize);
	}

	// make sure that "rva" is located here
	public inline function calcPointerToRawData(rva: Int): Ptr
		return cast (pointerToRawData + rva - virtualAddress);

	static public inline function fromPtr(p: Ptr): SECTION_HEADER return cast p;
}



/**
 https://msdn.microsoft.com/en-us/library/windows/desktop/ms680198(v=vs.85).aspx

 https://en.wikibooks.org/wiki/X86_Disassembly/Windows_Executable_Files

+--------------------+
|     DOS header     |
+--------------------+-------+
|    PE Signature    |       |
+--------------------+   N   |
|    FILE HEADER     |       |
+--------------------+   T   |
|    OPTIANAL HEADER |       |
+--------------------+-------+
|    SECTION TABLE   |
+--------------------+
|  MAPPABLE SECTIONS |
+--------------------+
*/
class PE {

}


@:enum abstract Machine(Int) to Int {
	var I386  = 0x014c;  // x86
	var IA64  = 0x0200;  // Intel Itanium
	var AMD64 = 0x8664;  // x64
	var ARMLE = 0x01c0;  // ARM little endian
}

@:enum abstract Magic(Int) to Int {
	var M32  = 0x10B;  // The file is an executable image.
	var M64  = 0x20B;  // The file is an executable image.
	var MROM = 0x107;  // The file is a ROM image. maybe is https://msdn.microsoft.com/en-us/library/ms909531.aspx
}

@:enum abstract Subsystem(Int) to Int {
	var UNKNOWN     = 0;
	var NATIVE      = 1;
	var WINDOWS_GUI = 2;
	var WINDOWS_CUI = 3;
	var OS2_CUI     = 5;
	var POSIX_CUI   = 7;
	var WINDOWS_CE_GUI          =  9;
	var EFI_APPLICATION         = 10;
	var EFI_BOOT_SERVICE_DRIVER = 11;
	var EFI_RUNTIME_DRIVER      = 12;
	var EFI_ROM     = 13;
	var XBOX        = 14;
	var WINDOWS_BOOT_APPLICATION= 16;
}

@:enum abstract DllCharacteristics(Int) to Int {
	var RESERVED_1     = 0x0001;
	var RESERVED_2     = 0x0002;
	var RESERVED_3     = 0x0004;
	var RESERVED_4     = 0x0008;
	var DYNAMIC_BASE   = 0x0040;
	var FORCE_INTEGRITY= 0x0080;
	var NX_COMPAT      = 0x0100;
	var NO_ISOLATION   = 0x0200;
	var NO_SEH         = 0x0400;
	var NO_BIND        = 0x0800;
	var RESERVED_5     = 0x1000;
	var WDM_DRIVER     = 0x2000;
	var RESERVED_6     = 0x4000;
	var TERMINAL_SERVER_AWARE = 0x8000;
}


@:enum abstract SECTION_CHARACTERISTICS(Int) to Int {
	var TYPE_NO_PAD           = 0x00000008;  // This flag is obsolete
	var CNT_CODE              = 0x00000020;  // The section contains executable code.    ".text"
	var CNT_INITIALIZED_DATA  = 0x00000040;  // The section contains initialized data.   ".data"
	var CNT_UNINITIALIZED_DATA= 0x00000080;  // The section contains uninitialized data. ".bss"
	var LNK_INFO              = 0x00000200;  // The section contains comments or other information. This is valid only for object files.
	var LNK_REMOVE            = 0x00000800;  // The section will not become part of the image. This is valid only for object files.
	var LNK_COMDAT            = 0x00001000;  // The section contains COMDAT data. This is valid only for object files.

	var NO_DEFER_SPEC_EXC     = 0x00004000;  // Reset speculative exceptions handling bits in the TLB entries for this section.
	var SCN_GPREL             = 0x00008000;  // The section contains data referenced through the global pointer.

	var ALIGN_1BYTES          = 0x00100000;  // Align data on a    1-byte boundary. This is valid only for object files.
	var ALIGN_2BYTES          = 0x00200000;  // Align data on a    2-byte boundary. This is valid only for object files.
	var ALIGN_4BYTES          = 0x00300000;  // Align data on a    4-byte boundary. This is valid only for object files.
	var ALIGN_8BYTES          = 0x00400000;  // Align data on a    8-byte boundary. This is valid only for object files.
	var ALIGN_16BYTES         = 0x00500000;  // Align data on a   16-byte boundary. This is valid only for object files.
	var ALIGN_32BYTES         = 0x00600000;  // Align data on a   32-byte boundary. This is valid only for object files.
	var ALIGN_64BYTES         = 0x00700000;  // Align data on a   64-byte boundary. This is valid only for object files.
	var ALIGN_128BYTES        = 0x00800000;  // Align data on a  128-byte boundary. This is valid only for object files.
	var ALIGN_256BYTES        = 0x00900000;  // Align data on a  256-byte boundary. This is valid only for object files.
	var ALIGN_512BYTES        = 0x00A00000;  // Align data on a  512-byte boundary. This is valid only for object files.
	var ALIGN_1024BYTES       = 0x00B00000;  // Align data on a 1024-byte boundary. This is valid only for object files.
	var ALIGN_2048BYTES       = 0x00C00000;  // Align data on a 2048-byte boundary. This is valid only for object files.
	var ALIGN_4096BYTES       = 0x00D00000;  // Align data on a 4096-byte boundary. This is valid only for object files.
	var ALIGN_8192BYTES       = 0x00E00000;  // Align data on a 8192-byte boundary. This is valid only for object files.

	var LNK_NRELOC_OVFL       = 0x01000000;  // The section contains extended relocations
	var MEM_DISCARDABLE       = 0x02000000;  // The section can be discarded as needed.
	var MEM_NOT_CACHED        = 0x04000000;  // The section cannot be cached.
	var MEM_NOT_PAGED         = 0x08000000;  // The section cannot be paged.
	var MEM_SHARED            = 0x10000000;  // The section can be shared in memory.
	var MEM_EXECUTE           = 0x20000000;  // The section can be executed as code.
	var MEM_READ              = 0x40000000;  // The section can be read.
	var MEM_WRITE             = 0x80000000;  // The section can be written to.
}


/**
 example:

 ```
 var b: Bits = new Bits(nt32.characteristics);
 if (b[C_DLL] == 1)
	//....
 ```
*/
@:enum abstract FILE_HEADER_CHARACTERISTICS(Int) to Int {
	var C_RELOCS_STRIPPED = 0;          // Relocation information was stripped from the file.
	var C_EXECUTABLE_IMAGE = 1;         // The file is executable (there are no unresolved external references).
	var C_LINE_NUMS_STRIPPED = 2;       // COFF line numbers were stripped from the file.
	var C_LOCAL_SYMS_STRIPPED = 3;      // COFF symbol table entries were stripped from file.
	var C_AGGRESIVE_WS_TRIM = 4;        // Aggressively trim the working set. This value is obsolete.
	var C_LARGE_ADDRESS_AWARE = 5;      // The application can handle addresses larger than 2 GB.
	var C_UNKNOW_0 = 6;
	var C_BYTES_REVERSED_LO = 7;        // The bytes of the word are reversed. This flag is obsolete.
	var C_32BIT_MACHINE = 8;            // The computer supports 32-bit words.
	var C_DEBUG_STRIPPED = 9;           // Debugging information was removed and stored separately in another file
	var C_REMOVABLE_RUN_FROM_SWAP = 10; // If the image is on removable media, copy it to and run it from the swap file.
	var C_NET_RUN_FROM_SWAP = 11;       // If the image is on the network, copy it to and run it from the swap file.
	var C_SYSTEM = 12;                  // The image is a system file.
	var C_DLL = 13;                     // The image is a DLL file. While it is an executable file, it cannot be run directly.
	var C_UP_SYSTEM_ONLY = 14;          // The file should be run only on a uniprocessor computer.
	var C_BYTES_REVERSED_HI = 15;       // The bytes of the word are reversed. This flag is obsolete.
}


/**
* .edata (export table)
* https://msdn.microsoft.com/en-us/library/ms809762.aspx
*/
#if !macro
@:build(mem.Struct.make())
#end
abstract EDT(Ptr) to Ptr {
	@idx(4) var characteristics       : Int;  // aways be 0
	@idx(4) var timeDateStamp         : Int;  // same as nt32.timeDateStamp
	@idx(2) var majorVersion          : Int;
	@idx(2) var minorVersion          : Int;
	@idx(4) var name                  : Int;  // The RVA of an ASCIIZ string with the name of this DLL.
	@idx(4) var base                  : Int;
	@idx(4) var numberOfFunctions     : Int;
	@idx(4) var numberOfNames         : Int;
	@idx(4) var addressOfFunctions    : Int;
	@idx(4) var addressOfNames        : Int;
	@idx(4) var addressOfNameOrdinals : Int;

	static public inline function fromPtr(p: Ptr): EDT return cast p;
}