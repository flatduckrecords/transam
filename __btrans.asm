	include "_equ.asm"

	org 0x4000 + offset
	
	include "_btrans.asm"	; BASIC translation

	defs 0xA5-$\0x100			; table alignment padding
	include "_tables.asm"   ; (i.e. word boundary + 0xA5)
	include "_memory.asm"
