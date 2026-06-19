	include "_equ.asm"
	org 0x4000 + offset

	ld hl,1
	ld (sector),hl				; Reset trck/sec counter
	
	call checkname
	jp c,nameerror
	call getbyname
	jp c,nameerror

	; 1) Check SAMDOS file type (@0)
	ld hl,(record)
	ld a,(hl)
	or a
	ret z
	cp 1
	jp nz,typeerror
	
	; 2) Check PlusD info: file type (b@211)
	ld l,211
	ld a,(hl)
	cp 0						; 0 = ZX BASIC
	jp nz,typeerror

	; Check total number of sectors
	ld l,11
	ld b,(hl)
	inc l
	ld c,(hl)
	ld (numsec),bc
	push hl						; hl = record @0
	
	; 4) Get data length (w@212)
	call getdatalengths

	; 5) Get address (Trk/Sect) of first sector (w@13)
	pop hl						; hl = record @0
	ld l,13						; HL = record @13
	ld d,(hl)					; d = track
	inc l
	ld e,(hl)					; e = sector

	; 6) Load all chained file sectors
	ld hl,(PROG)
	ld a,h
	sub 0x40
	ld h,a						; hl= absolute addr, HRSAD will
								; page it in (I think!)

	ld a,1						; we need page 1 in HMPR
	call SETHMPRA				; if the file is larger than 
								; about 7K
								
	push hl
	push de
	ld a,0xFE
	call JSETSTRM   			; Open channel 2 (screen)
	call printsummary
	pop de
	pop hl

loadallsectors:
	push hl
	call getsector_hlde			; hl=dest de=sector address
	pop hl
		
	ld bc,0x01FE				; address of next sector (@510)
	add hl,bc
	inc hl
	ld e,(hl)
	dec hl
	ld d,(hl)
	
	ld a,d
	or e						; 0x0000 means we're done
	jr z,doneloading

	ld bc,(numsec)
	dec bc
	ld a,b
	or c
	jp z,eoferror
	ld (numsec),bc

	jr loadallsectors			; loop until done
	
doneloading:
	ret							; <-- E X I T 
	
namecheck:
	scf
namecheck_1:
	ld a,(de)
	set 5,a				; force lowercase
	set 5,(hl)			; force lowercase
	cpi					; CP (HL): INC HL: DEC BC
	inc de
	ret nz				; nameerror
	jp pe,namecheck_1	; loop until BC=0
	ccf					; no error
	ret

; DOR HRSAD -- D contains the track number, and E contains the sector number.
; The Accumulator holds the drive number (1 or 2). Reads the
; sector pointed to by the DE register pair. The Accumulator
; contains the drive number, while the HL register pair is the
; pointer to the destination.

;   A = drive
;   D = track
;   E = sector
;   HL = memory address (0x4000 to 0xfe00)

getsector:
	ld hl,dir
	ld de,(sector)
getsector_hlde:
	ld a,(SELNUM)		; use current drive
	rst 8
	defb dos.hrsad
	ret

getbyname:
	call getsector

	ld hl,filename		; name of requested file
	ld de,dir			; disk directory buffer
	ld (record),de
	inc e				; step over "type" byte
	ld bc,10			; length of name to compare
	call namecheck
	
	ret nc
	
	ld hl,filename		; name of requested file
	ld de,dir			; disk directory buffer
	inc d				; next record
	ld (record),de
	inc e				; step over "type" byte
	ld bc,10			; length of name to compare
	call namecheck
	
	ret nc
	
	ld a,(sector)
	inc a				; move to next sector
	cp 11				; sector max is 10
	jr nc,next_track	; move to next track
	ld (sector),a
	jr getbyname

next_track:
	ld a,1
	ld e,a				; sector
	ld a,(track)		; track
	inc a			
	cp 4				; max dir track is 3
	jr nc,notfound		; error if track is >= 4
	ld d,a
	ld (sector),de
	jr getbyname

notfound:
	scf					; signal an error
	ret					; end
	
typeerror:
	rst 8
	defb 0x5E			; SAMDOS error "Wrong file type"
	
nameerror:
	rst 8
	defb 0x6B			; SAMDOS error "File not found"
	
eoferror:
	rst 8
	defb 0x6C			; SAMDOS error "End of file"

getdatalengths:
	ld l,212
	push hl
	ld c,(hl)
	inc l
	ld b,(hl)					; BC = data length
	ld (length),bc				; save it
	pop hl						; HL = record @212
	ld l,216
	ld c,(hl)
	inc l
	ld b,(hl)					; BC = PROG-->VARS offset
	ld (param1),bc
	inc l						; HL = record @218
	ld e,(hl)
	inc l
	ld d,(hl)					; DE = auto start line
	ld (param2),de				; save it
	ld hl,(length)
	or a
	sbc hl,bc
	ld b,h
	ld c,l
	ld (varlen),bc
	ret

;; check the filename isn't null or spaces
checkname:
	xor a
	ld hl,filename
	cp (hl)
	jr z,checkname_no	; error if NULL
	ld a,0x20
	ld b,10
checkname_lp:
	cp (hl)
	jr nz,checkname_ok	; error if spaced
	djnz checkname_lp
checkname_no:	
	scf
	ret
checkname_ok:
	or a
	ret

printsummary:
	ld hl,m1
	ld b,9
	call print
	ld hl,(record)
	inc l
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

	ALIGN 256
dir: