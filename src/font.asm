CHARS:		equ 0x5190
JSETSTRM:	equ 0x0112


	org 0x8000
	dump 1,0
	autoexec
	
	ld hl,font
	ld de,CHARS
	call dzx0_standard
	
	ld hl,udgs
	ld de,CHARS + (112*8) ; CHR$144
	call dzx0_standard
	
	ret
	
font:
	mdat "../build/zxfont.bin.zx0"
udgs:
	mdat "../build/udg.zx0"
	
	include "dzx0_standard.asm"