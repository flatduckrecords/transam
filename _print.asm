; print to screen helper functions

print_bc_cr:
	call STACKBC				; Use the FPC to help print
print_fp_cr:
	call print_fp
	ld a,CHR_RETN
	rst 0x10
	ret

print_bc_kb:
	call STACKBC
	ld bc,0x0400
	call STACKBC
	rst 0x28
	defb DIVN
	defb ONELIT
	defb 0x64
	defb MULT
	defb INT
	defb ONELIT
	defb 0x64
	defb DIVN
	defb EXIT
	call print_fp
	ret

print_cr:
	call print
	ld a,CHR_RETN
	rst 0x10
	ret	

print:
	ld a,(hl)
	inc hl
	rst 0x10
	djnz print
	ret

print_bc:
	call STACKBC
print_fp:
	push hl
	call JSTR					; the value as an ASCII string
	ex de,hl					; hl = adhoc print buffer
	ld b,c						; number of chars to print
	call print
	pop hl
	ret

;print_fp_hex:
;	push de
;	push hl
;		call print_fp_hex_0
;		call print
;	pop hl
;	pop de
;	ret

;print_fp_hex_cr:
;	push de
;	push hl
;		call print_fp_hex_0
;		call print_cr
;	pop hl
;	pop de
;	ret

print_bc_hex:
	push de
	push hl
		call print_bc_hex_0
		call print
	pop hl
	pop de
	ret

print_bc_hex_cr:
	push de
	push hl
		call print_bc_hex_0
		call print_cr
	pop hl
	pop de
	ret

print_bc_hex_0:
	call STACKBC
print_fp_hex_0:
	rst 0x28			; Invoke calculon
	defb HEX			; Transform to HEX$
	defb EXIT			; Exit calculon
	call JSBUFFET		; DE=start BC=length
	ex de,hl
	ld b,c
	ret

tokens_off:
	ld a,(INQUFG)
	ld (myqflg),a
	ld a,1
	ld (INQUFG),a
	ret

tokens_restore:
	ld a,(myqflg)
	ld (INQUFG),a
	ret