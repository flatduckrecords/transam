; self-extracting DEBUG:
; might be useful? ¯\_(ツ)_/¯
get_debug:
	ld hl,pack_debug
	ld de,module
	call dzx0_standard
	ld bc,module
	ret

; zx0 packed modules:
pack_loader:
	mdat "build/loader.zx0"
pack_tape:
	mdat "build/tape.zx0"
pack_BTRANS:
	mdat "build/btrans.zx0"
pack_VTRANS:
	mdat "build/vtrans.zx0"
pack_debug:
	mdat "build/debug.zx0"
pack_kick:
	mdat "build/kick.zx0"