	include "_equ.asm"

	org 0x4000 + offset

	include "_kickstart.asm"
	include "_keywait.asm"	; wait for a keypress