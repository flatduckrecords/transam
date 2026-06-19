wait:
	di				; prevent keystrokes being buffered by OS
none:
	call anyscan
	jr nz,none
any:
	call anyscan
	jr z,any
	call delay
none2:
	call anyscan
	jr nz,none2
	ei
	ret

delay:					; delay to allow switch settling
	ld b,0x60			; for mechanical keyboards.
delay_lp:
	push af
	pop af
	djnz delay_lp
	ret

anyscan:
	ld bc,0x00F9		; STATUS (keyboard hi)
	in a,(c)
	and %11100000
	ld l,a
	ld bc,0x00FE		; BORDER (keyboard lo)
	in a,(c)
	and %00011111
	or l
	cp 0xFF				; =0xFF if no keys pressed
	ret

