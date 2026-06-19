;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; The code here that interprets Spectrum;
; variables is based on "Variables List";
; by Neil R. Canham, published in       ;
; Your Computer, May 1984               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Disassembled and modified to insert   ;
; variables into SAM June 2026.         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

parse_vars:
	IN A,(251)
	AND &1F
	LD (DESTP),A

	ld a,CHR_RETN
	rst 0x10
	ld a,CHR_RETN
	rst 0x10
	
	call tokens_off
	ld hl,m3
	ld b,m3e-m3
	call print
	call tokens_restore
	
	ld hl,(zxvars)
	ld bc,(PROG)
	res 7,b
	set 6,b			; BC=5CD5
	or a
	sbc hl,bc
	ld b,h
	ld c,l
	call huffle
	ld (zxvarsp),a
	ld (zxvarso),hl

NEXT_CHARACTER:
	ld a,(hl)
	cp 0x80
	ret z

CHECK_7:
	bit 7,a
	jr nz,CHECK_6			; if Bit7 is set, next check Bit6…
	bit 5,a					; if Bit7 is NOT set, ignore Bit6 and check Bit5
	jp z,STRING				; must be 010 String [000 is not used]
	jp NUMBER				; must be 011 Number (short name) [001 is not used]
CHECK_6:
	bit 6,a					; we know Bit7 is set
	jr nz,CHECK_5			; if Bit6 is set, next check Bit5…
	bit 5,a					; 10(?)
	jp nz,LONG_NAME			; 101 Number (long name)
	jr ARRAY				; 100 Number array
CHECK_5:
	bit 5,a					; We now know Bit7 and Bit6 are set,
	jr z,STRINGARRAY		; 110 String array
	jr FORNEXT				; 111 FOR..NEXT control


STRINGARRAY:
	call injectstrarr
	ld de,m_string
	jr PRINT_LETTER
ARRAY:
	call injectnumarr
	ld de,m_array
PRINT_LETTER:
	ld a,(hl)
	and %00011111
	add a,0x40
	rst 0x10
	call PRINT_MSG
	ld a,0x20
	rst 0x10

	push hl
		inc hl
		ld c,(hl)
		inc hl
		ld b,(hl)					; BC = Total length of elements & dims + 1
		inc hl

		ld b,(hl)					; B = Number of dimensions
		inc hl						; HL = pointer -> 1st Dims

PRINT_DIMS:
		push bc
			ld c,(hl)
			inc hl
			ld b,(hl)				; BC = size of dimension
			inc hl
			push hl
				call print_bc_cr
			pop hl
		pop bc
		ld a,b
		dec a
		jr z,NO_DELIMITER
		ld a,"x"
		rst 0x10
NO_DELIMITER:
		djnz PRINT_DIMS
	pop hl
SKIP_WORD_LENGTH:
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ADD hl,de
	inc hl
	jr NEXT_CHARACTER


FORNEXT:
	ld a,%01000000			; FORNEXT,namelen -1
	ld (TLBYTE),a			; for this type of var
	ld a,(hl)				; get name as stored
	xor 0x80				; 10000000	111xxxxx -> 011xxxxx
	ld (FIRLET),a			; store it as decoded/lowercase

	ld a,CHR_INVR
	rst 0x10
	ld a,0x01			; 01 inverse ON
	rst 0x10
	ld a,(hl)
	xor 0xA0			; 10100000	111xxxxx -> 010xxxxx
	rst 0x10			; print it (decoded, uppercase)
	inc hl
	ld (datapointer),hl
	ld a,CHR_INVR
	rst 0x10
	xor a				; 00 inverse OFF
	rst 0x10
	ld a,0x20
	rst 0x10
	call STACK_5
	call print_fp
	ld a,TOK_TO	
	rst 0x10
	call STACK_5
	call print_fp
	ld a,TOK_STEP
	rst 0x10
	call STACK_5
	call print_fp
;		ld a,CHR_RETN
;		rst 0x10
;		ld a,0x20
;		rst 0x10
	ld a,0x20
	rst 0x10
	ld c,(hl)
	inc hl
	ld b,(hl)				; BC=line number
	inc hl					; HL=stmt
	push bc					; BC=line number
		push hl				; HL=stmt
			ld a,"["
			rst 0x10
			call print_bc
			ld a,":"
			rst 0x10
		pop hl				; HL=stmt
		ld c,(hl)
		ld b,0				; BC=stmt
		inc hl				; HL=next
		push hl				; HL=next
			call print_bc
			ld a,"]"
			rst 0x10
;				ld a,0x20
;				rst 0x10
;				ld a,"("
;				rst 0x10
		pop bc			; BC=next
	pop hl				; HL=line number
	push bc				; BC=next
		in a,(HMPR)
		ld (page),a
		call FNDLINE	; HL=addr of LINE
		ld (lnaddr),hl
		in a,(HMPR)
		and %00011111
		ld (lnaddrp),a
		ld a,(page)
		out (HMPR),a
		push hl
			call insertnumbervar_0
		pop hl
;			ld b,h
;			ld c,l
;			call print_bc_hex
;			ld a,")"
;			rst 0x10

	pop hl				; HL=next
	ld a,CHR_RETN
	rst 0x10
	jp NEXT_CHARACTER


STRING:
	call injectstring
	ld a,(hl)
	rst 0x10
	ld a,CHR_DOLA
	rst 0x10
	ld a,CHR_EQUA
	rst 0x10
	ld a,CHR_QUOT
	rst 0x10
	inc hl
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	ld a,b
	or c
	jr z,STRING_LOOP_DONE
STRING_LOOP:
	ld a,(hl)
	rst 0x10
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,STRING_LOOP
STRING_LOOP_DONE:
	ld a,CHR_QUOT
	rst 0x10
	ld a,CHR_RETN
	rst 0x10
	jp NEXT_CHARACTER


NUMBER:
	ld a,%00000000			; NUMBER, namelen -1
	ld (TLBYTE),a			; for this type of var
	ld a,(hl)				; get name as stored (already lc)
	ld (FIRLET),a			; store it as decoded/lowercase
	res 5,a					; transform to uppercase
	rst 0x10				; print it
NUMBER_EQ:
	ld a,CHR_EQUA
	rst 0x10
	inc hl
	call STACK_5
	push hl
		call fpc_dup
		call insertnumbervar_0
		call print_fp
	pop hl
	
	ld a,CHR_RETN
	rst 0x10
	jp NEXT_CHARACTER


LONG_NAME:
	ld b,0					; we'll use B as a length count
	ld de,FIRLET			; DE=namebuffer
	ld a,(hl)
	xor 0xE0				; 11100000	101xxxxx -> 010xxxxx
	ld (hl),a				; put printable form back
	ld (de),a
	inc de
	rst 0x10
LONG_NAME_LOOP:
	inc b					; +1 for each letter in name
	inc hl
	ld a,(hl)
	bit 7,a
	jr nz,LONG_NAME_LAST
	ld (de),a
	inc de
	rst 0x10
	jr LONG_NAME_LOOP
LONG_NAME_LAST:
	res 7,a
	ld (de),a				; put printable form back
	rst 0x10
	ld a,b
	ld (TLBYTE),a			; store name length
	ld a,CHR_EQUA
	rst 0x10
	inc hl
	call STACK_5
	push hl
		call fpc_dup
		call insertnumbervar_0
		call print_fp
	pop hl
	ld a,CHR_RETN
	rst 0x10
	jp NEXT_CHARACTER


;; Subroutines ;;
fpc_dup:
	rst 0x28
	defb DUP
	defb EXIT2			; Exit and do a RET

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

PRINT_MSG:
	ld a,(de)
	or a
	ret z
	rst 0x10
	inc de
	jr PRINT_MSG

injectstrarr:
		ld a,%01000001			; t/c : bit 6 is set for string arrays
		jr injectsavars
injectnumarr:
		ld a,%00100001			; t/c : bit 5 is set for numeric arrays
		jr injectsavars
injectstring:
		ld a,1					; t/c : bits 5&6 reset for strings
injectsavars:
		ld (strvarbuf),a
		push hl
			ld a,(hl)					; get varname
			and %00011111
			 or %01100000				; lowercase
			ld (strvarbuf+1),a			; bufferisulatify it
			inc hl
			ld e,(hl)
			inc hl
			ld d,(hl)					; DE=var length
			ld (strvarbuf+12),de		; bufferisulatify it
			inc hl
			push hl						; HL=start of data
			
				ld bc,strvarbufend-strvarbuf
				ex de,hl					; HL=var length
				add hl,bc					; HL=total length
				ld b,h
				ld c,l						; BC=total length

				in a,(HMPR)
				ld (injectstring_1+1),a		; if pages are different
				ld a,(SAVARSP)				; we might need FARLDIR?
				call SETHMPRA

				xor a
				ld hl,(SAVARS)
				call JMKRBIG
				ex de,hl					; DE=start of new SAVARS space
		
				ld bc,strvarbufend-strvarbuf
				ld hl,strvarbuf
				ldir						; copy var header
				ld bc,(strvarbuf+12)		; BC=length of data
			pop hl						; HL=start of data
			;ldir						; copy var data
			xor a
			ld (PAGCOUNT),a
			ld (MODCOUNT),bc
			ld a,(SAVARSP)
			ld c,a
			ld a,(zxvarsp)
			call JFARLDIR	;LDIR (PAGCOUNT) PAGES AND (MODCOUNT) BYTES FROM AHL TO CDE

injectstring_1:
			ld a,0x00
			out (HMPR),a
		pop hl
		ret

strvarbuf:
	defb 0x01				; type/len
	defs 10					; name
	defb 0x00				; pages
	defw 0x0000				; length MOD 16k + 3
strvarbufend:

datapointer:
	defw 0x0000
lnaddr:
	defw 0x0000
lnaddrp:
	defb 0x00

print_bc2:
	call STACKBC				; Use the FPC to help print
print_fp2:
	call JSTR					; the value as an ASCII string
	ex de,hl					; hl = adhoc print buffer
	ld b,c						; number of chars to print
pr:
	ld a,(hl)
	inc hl
	rst 0x10
	djnz pr
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; These functions are a re-enactment of ;
; what SAM's ROM does when the BASIC    ;
; interpreter accepts a new variable.   ;
; Some of the comments are copied from  ;
; Andy's source code too.               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; in: HL=pt. to name, BC=length, A=t/l byte
insertnumbervar:
	; first copy
	ld (TLBYTE),a		; type/length byte
	ld de,FIRLET		; HL=name, BC=length
	ldir				; copy name to buffer

insertnumbervar_0:	
	; second copy
	LD HL,TLBYTE		; start at TLBYTE
	LD DE,TLBYTE+33		; copy to +33 bytes ahead
	ld a,(hl)
	AND &1F				;NAME LEN-1 IF NUMERIC, TRUE NAME LEN IF STR/ARRAY
	ADD A,2				;ALLOW FOR TLBYTE AND (PERHAPS) ANOTHER LETTER
	LD C,A
	LD B,0
	LDIR				;COPY NAME TO BUFFER THAT WON'T BE USED BY EVAL

insertnumbervar_1:
	in a,(HMPR)			; make a note of current HMPR
	ld (page),a			; becuase ADDRNV may change it
	LD A,(FIRLET)
	or 0x20				; force uppercase
	SUB &61
	ADD A,A
	LD E,A				;LETTER TRANSFORMED TO WORD OFFSET (A=0, B=2..)
	LD D,0
	CALL ADDRNV			;PT. HL AT NUMERIC VARS, PAGED IN
	ADD HL,DE			;INDEX INTO TABLE OF WORD PTRS.


; The offset is the distance to move from the MSB of the current offset
; to the type/length byte of the next variable starting with the same
; letter, or FFFFH if there are no more such variables.

loop:
	ld d,h
	ld e,l
	
	ld a,(hl)
	inc hl
	and (hl)
	inc a
	jr z,ok
	ld d,(hl)
	dec hl
	ld e,(hl)
	add hl,de
	inc hl		; align with MSB offset
	inc hl		; skip t/l byte
	jr loop
	
ok:
	ld a,(TLBYTE)	; T/L byte again (self modified)
	bit 6,a
	jr nz,inv_fornext
	call ASNN	; DE should be pointing to link LSB
	
insnvrestore:
	ld a,(page)		; restore previous HMPR
	out (HMPR),a
	ret				; <-- E X I T 
	

inv_fornext:
	ld (temp_link),hl		; HL=prev link MSB
	ld a,(NUMENDP)
	call SETHMPRA
	xor a
	ld bc,22
	ld hl,(NUMEND)
	call JMKRBIG
	push hl
		ld hl,(NUMEND)
		ld bc,22
		add hl,bc
		ld (NUMEND),hl
	pop hl
	push hl					; HL=start of new space
		ld de,(temp_link)	; DE=prev link MSB
		and a
		sbc hl,de			; displacement
		ex de,hl
		dec hl				; HL=prev link LSB
		ld (hl),e
		inc hl
		ld (hl),d
	pop de					; DE=start of new space

	LD A,(TLBYTE)
	ld (de),a
	inc de
	ld a,0xFF
	ld (de),a
	inc de
	ld (de),a
	inc de

	ld bc,15
	ld (MODCOUNT),bc
	xor a
	ld (PAGCOUNT),a
	ld a,(NUMENDP)
	ld c,a
	ld a,(NVARSP)
	ld hl,(datapointer)
	push hl
		push de
			call JFARLDIR
		pop hl
		add hl,bc
		ex de,hl
	pop hl
	add hl,bc
	ld a,(lnaddrp)
	ld (de),a				; Page of BASIC line
	inc de
	ld a,(lnaddr)			; Address of BASIC line
	ld (de),a
	inc de
	ld a,(lnaddr+1)
	ld (de),a
	inc de
	inc hl
	inc hl
	ld a,(hl)
	ld (de),a
	jr insnvrestore

reclaim_vars:
	ld a,(zxvarsp)
	call SETHMPRA
	ld bc,(varlen)
	ld hl,(zxvarso)
	call JRECLAIM
	ld a,1
	call SETHMPRA
	ret
	
temp_link:	defw 0x0000
new_loc:	defw 0x0000

m3:		defb CHR_INVR,1
		defb 0x92
		defm "ZX"
		defb CTRL_PAP,2	;red
		defm "Sp"
		defb CTRL_PAP,6	;yellow
		defm "ec"
		defb CTRL_PAP,4	;green
		defm "tr"
		defb CTRL_PAP,5	;cyan
		defm "um "
		defb CHR_INVR,0
		defb CTRL_PAP,2	;red
		defb 0x92
		defb CTRL_PEN,2	;yellow
		defb CTRL_PAP,6	;yellow
		defb 0x92
		defb CTRL_PEN,6	;yellow
		defb CTRL_PAP,4	;green
		defb 0x92
		defb CTRL_PEN,4	;green
		defb CTRL_PAP,5	;cyan
		defb 0x92
		defb CTRL_PEN,5	;cyan
		defb CTRL_PAP,0	;black (default)
		defb 0x92
		defb CTRL_PEN,7	;cyan
		defb CHR_RETN, CHR_RETN
		defm "Variables:"
		defb CHR_RETN
m3e: