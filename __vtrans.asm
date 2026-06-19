	org 0x4000 + offset
	
	ld bc,(varlen)
	ld a,b
	or c
	ret z					; exit now if no ZX vars

	call parse_vars			; examine/translate variables
	call reclaim_vars		; reclaim space used
	ret
	
	include "_variables.asm"
	include "_print.asm"
	include "_memory.asm"
