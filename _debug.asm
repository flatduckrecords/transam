debug:
	push af
	push bc
	push de
	push hl

	ld a,0xFE
	call JSETSTRM   ; Open channel 2 (screen)
	
	ld a,CHR_RETN
	rst 0x10
	ld a,CHR_RETN
	rst 0x10

	ld a,0x82
	LD (BGFLG),A		; BGFLG: Block graphics flag
	call tokens_off
	ld a,(ATTRP)
	ld b,a
	and %00111000	;paper
	rra
	rra
	rra
	ld (m6p1),a
	ld (m6p2),a
	ld a,b
	and %00000111	; ink
	ld (m6i),a
	ld hl,m6
	ld b,m6e-m6
	call print
	call tokens_restore
	xor a
	LD (BGFLG),A		; BGFLG: Block graphics flag


	
;	ld hl,d5
;	call prntl
;	ld bc,(HPST)
;	call print_bc_hex
;	ld a,"-"
;	rst 0x10
;	ld a,">"
;	rst 0x10
;	ld bc,(HEAPEND)
;	call print_bc_hex_cr
;
;	ld hl,d6
;	call prntl
;	ld bc,(BASSTK)
;	call print_bc_hex
;	ld a,"-"
;	rst 0x10
;	ld a,">"
;	rst 0x10
;	ld bc,(BSTKEND)
;	call print_bc_hex_cr

	ld hl,d1
	call prntl
	ld a,(PROGP)
	ld b,0
	ld c,a
	call print_bc
	ld a," "
	rst 0x10
	ld bc,(PROG)
	call print_bc_hex_cr

	ld hl,d9
	call prntl
	ld a,(zxvarsp)
	ld b,0
	ld c,a
	call print_bc
	ld a," "
	rst 0x10
	ld bc,(zxvarso)
	call print_bc_hex_cr
	
	ld hl,d2
	call prntl
	ld a,(NVARSP)
	ld b,0
	ld c,a
	call print_bc
	ld a," "
	rst 0x10
	ld bc,(NVARS)
	call print_bc_hex_cr

	ld hl,d3
	call prntl
	ld a,(NUMENDP)
	ld b,0
	ld c,a
	call print_bc
	ld a," "
	rst 0x10
	ld bc,(NUMEND)
	call print_bc_hex_cr

	ld hl,d4
	call prntl
	ld a,(SAVARSP)
	ld b,0
	ld c,a
	call print_bc
	ld a," "
	rst 0x10
	ld bc,(SAVARS)
	call print_bc_hex_cr
	
	ld hl,d5
	call prntl
	ld a,(ELINEP)
	ld b,0
	ld c,a
	call print_bc
	ld a," "
	rst 0x10
	ld bc,(ELINE)
	call print_bc_hex_cr
	
	ld hl,d8
	call prntl
	ld a,(DATADDP)
	ld b,0
	ld c,a
	call print_bc
	ld a," "
	rst 0x10
	ld bc,(DATADD)
	call print_bc_hex_cr
	
	ld a,CHR_RETN
	rst 0x10
	
	ld hl,m7
	ld b,m7e-m7
	call print
	
	ld hl,(NVARS)
	ld a,(NVARSP)
	call SETHMPRA
	
	ld b,26
	ld d,"a"
nvarsloop:
	push bc
		ld c,(hl)
		inc hl
		ld b,(hl)
		push hl
			ld a,b
			or c
			inc a
			call nz,print_vars_entry
			inc d	; letter 
		pop hl
		inc hl
	pop bc
	djnz nvarsloop

;	ld hl,x1
;	call prntl
;	ld bc,(length)
;	call print_bc_cr
;	
;	ld hl,x2
;	call prntl
;	ld bc,(param1)
;	call print_bc_cr
;	
;	ld hl,x3
;	call prntl
;	ld bc,(param2)
;	call print_bc_cr
;	
;	ld hl,x4
;	call prntl
;	ld bc,(zxvars)
;	call print_bc_cr
;	
;	ld hl,x5
;	call prntl
;	ld bc,(varlen)
;	call print_bc_cr
	

	pop hl
	pop de
	pop bc
	pop af
	ret

prntl:
	ld b,8
	call print
	ret

d1:		defm "PROG:   "
d2:		defm "NVARS:  "
d3:		defm "NUMEND: "
d4:		defm "SAVARS: "
d5:		defm "ELINE:  "
;d6:	defm "HEAP:   "
;d7:	defm "STACK:  "
d8:		defm "DATADD: "
d9:		defm "ZX Var: "

STACK_5:
	ld a,(hl)
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	push hl
	call JSTKSTORE
	pop hl
	ret

print_vars_entry:
	push de
		add hl,bc	; HL=addr of var
		ld b,h
		ld c,l
		ld a,CTRL_PEN
		rst 0x10
		ld a,6		; yellow
		rst 0x10
		call print_bc_hex
		ld a,CTRL_PEN
		rst 0x10
		ld a,(ATTRP)	;default colour
		and %00000111
		rst 0x10
		ld a," "
		rst 0x10
		ld a,d			; First letter
		rst 0x10
		ld a,(hl)
		bit 6,a			; is FOR/NEXT?
		push af			; save flags
			inc hl
			ld (chain),hl
			inc hl		;: skip TLBYTE and next chain address
			inc hl
			and %00011111	; var name length (max 32)
			ld b,a		; save to b as well
			jr z,nomorename
morename:
			ld a,(hl)
			rst 0x10
			inc hl
			djnz morename

nomorename:	
			ld a," "
			rst 0x10
			call STACK_5
			ld a,CTRL_BGT
			rst 0x10
			ld a,1
			rst 0x10
			call print_fp
			ld a,CTRL_BGT
			rst 0x10
			xor a
			rst 0x10
		pop af				; retrieve flags
		call nz,thuing		; NZ=fornext control variable
		ld a,CHR_RETN
		rst 0x10
	pop de
						; letter
	ld hl,(chain)
	ld c,(hl)
	inc hl				; HL=chain MSB
	ld b,(hl)			; BC=offset
	ld a,b
	or c
	inc a
	jr nz,print_vars_entry
	ret
	
	thuing:
		;ld a,TOK_TO
		call tokens_off		; make sure tokens printing off
		ld a,0x90			; CHR$ 144 (i.e. UDG "A")
		rst 0x10
		call STACK_5
		call print_fp
		ld a,0x91
		rst 0x10
		call tokens_restore	; restore tokens priting
		call STACK_5
		call print_fp
		ld a," "
		rst 0x10
		ld a,"["
		rst 0x10
		ld a,(hl)				; Page
		add "0"
		rst 0x10
		ld a," "
		rst 0x10
		inc hl					; HL=address
		ld c,(hl)
		inc hl
		ld b,(hl)				; BC=address
		inc hl					; HL=stmt
		push bc					; BC=line number
			push hl				; HL=stmt
				ld a,CTRL_PEN
				rst 0x10
				ld a,3
				rst 0x10
				call print_bc_hex
				ld a,CTRL_PEN
				rst 0x10
				ld a,(ATTRP)	;default colour
				and %00000111
				rst 0x10
				ld a,":"
				rst 0x10
			pop hl				; HL=stmt
			ld c,(hl)
			ld b,0				; BC=stmt
			inc hl				; HL=next
			push hl				; HL=next
				call print_bc
			pop hl				; HL=next
			ld a,"]"
			rst 0x10
		pop bc				; BC=line number
	
		ret
		
chain:	defw 0x0000

m6:		defb CHR_INVR,1
		defb 0x92
		defb CTRL_PAP,1	; blue
		defm "SAM"
		defb CTRL_PAP,2	; red
		defm "Coup"
		defb 0x82	; "é"
		defm "   "
		defb CTRL_PAP
m6p1:	defb 0x00	; black (default)
		defb CHR_INVR,0
		defb CTRL_PAP,1	;red
		defb 0x92
		defb CTRL_PEN,1	;yellow
		defb CTRL_PAP,2	;yellow
		defb 0x92
		defb CTRL_PEN,2	;yellow
		defb CTRL_PAP,0	;green
		defb 0x92
		defb CTRL_PEN,0	;green
		defb CTRL_PAP,7	;cyan
		defb 0x92
		defb CTRL_PEN,7	;white
		defb CTRL_PAP
m6p2:	defb 0x00	;black (default)
		defb 0x92
		defb CTRL_PEN
m6i:	defb 7	;default
		defb CHR_RETN,CHR_RETN
		defm "Memory map:"
		defb CHR_RETN
m6e: