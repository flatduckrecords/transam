	include "_equ.asm"
	org 0x4000 + offset

; tape loader
; rotine taken from BTRANS
tapeload:
	;ld a,84                 ; ascii "t"
	ld a,(SLDEV)
	ld (SLDEVT),a            ; set default device (sldevt)

	ld a,0xfe
	call JSETSTRM   			; open channel 2 (screen)

loadheader:
	ld hl,headerdata        ; destination
	ld de,80                ; 80 bytes
	xor a
	ld c,a
	inc a
	scf						; CY'=1 means LOAD (otherwise VERIFY)
	call JLOAD              ; jload load cde bytes to hl (a=01 sam or zx header)
	jr nc,loadheader
	ld a,(headerdata)
	and a
	jr nz,loadheader
	
	ld hl,(headerdata+11)	; get data block length from header buffer
	ld bc,(headerdata+15)   ; tape parameter 2: variable offset
	ld (length),hl
	ld (param1),bc			; -> "param1"
	or a
	sbc hl,bc
	ld (varlen),hl
	ld bc,(headerdata+13)   ; tape parameter 1: autostart
	ld (param2),bc			; -> "param2"
	call printsummary
	
	ld a,(PROGP)            ; get progp
	call SETHMPRA           ; make sure prog is paged-in.
	ld hl,(PROG)            ; get prog
	ld (hl),255             ; clear program by setting end marker?
	ld bc,(headerdata+11)	; get data block length from header buffer
	ld a,b
	rlca
	rlca
	and 3
	push af
	push bc
	inc bc					; extra byte for basic marker
	inc bc					; extra byte for vars marker
	call JMKRBIG            ; jmkrbig open a pages and bc bytes at hl
	pop de
	pop af
	ld c,a
	ld hl,(PROG)            ; load destination will be prog
	ld a,255                ; a=ff means load data block
	scf
	call JLOAD              ; jload load cde bytes to hl
	jr nc,loadheader
	ret			; <-- e x i t

	;; --> continue on to translate -->
headerdata:
	defs 0x11
	
printsummary:
	ld hl,m1
	ld b,9
	call print
	ld hl,headerdata+1

	ld a,0x22
	rst 0x10
	ld a,CTRL_BGT
	rst 0x10
	ld a,1
	rst 0x10
	ld b,10
	call print				; print name
	ld a,CTRL_BGT
	rst 0x10
	ld a,0
	rst 0x10
	ld a,0x22
	rst 0x10
	ld a,CHR_RETN
	rst 0x10
	ld hl,(param2)
	ld a,h
	and l
	inc a
	jr z,_noline
	ld hl,m2
	ld b,11
	call print
	ld a,CTRL_BGT
	rst 0x10
	ld a,1
	rst 0x10
	ld a,TOK_LINE
	rst 0x10
	ld bc,(param2)
	call print_bc				; print autostart line
	ld a,CTRL_BGT
	rst 0x10
	xor a
	rst 0x10
	ld a,CHR_RETN
	rst 0x10

_noline:
	ld hl,x1
	ld b,x1e-x1
	call print
	ld bc,(length)
	call print_bc_kb
	ld a,"k"
	rst 0x10
	ld a,"B"
	rst 0x10
	ld a,CHR_RETN
	rst 0x10
	
	ld bc,(varlen)
	ld a,b
	or c
	jr z,_novars

	ld hl,x5
	ld b,x5e-x5
	call print
	ld bc,(param1)
	call print_bc
	ld a," "
	rst 0x10
	ld a,"("
	rst 0x10
	ld bc,(varlen)
	call print_bc
	ld a,"b"
	rst 0x10
	ld a,")"
	rst 0x10
	ld a,CHR_RETN
	rst 0x10
_novars:
	ret