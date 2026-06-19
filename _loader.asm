	ld hl,1
	ld (sector),hl				; Reset trck/sec counter
	
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
	call makeroom				; open up LENGTH bytes at PROG

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