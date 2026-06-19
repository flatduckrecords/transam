 	include "_equ.asm"
start:	equ 0x4000

	dump 0,0
	org start
	
	ld b,a				; save A (no. of params)
	ld a,(SLDEV)		; get default device
	cp "T"				; ASCII "T"
	jr nz,disk_loader	; else assume "D"

tape_loader:
	ld a,b
	or a
	jr z,tape_loader_1	; no params
	call JGETINT
	add a,a				; test it
	jp p,PARAM_ERR		; jp error if string
	call JGETINT		; get the number
	ld (udgortok),a		; set it as the "use tokens" flag
tape_loader_1:	
	call init_screen
	ld a,2
	ld (flags),a
	ld a,1
	ld hl,pack_tape
	call call_module
	jr begin_translating

disk_loader:
	; Expect at least one parameter
	; on the FPC stack	
	ld a,b
	or a				; number of params
	jp z,PARAM_ERR		; jp if no params
	dec a
	push af				; save in case more
	
	; reset the filename buffer
	ld hl,filename
	ld de,filename+1
	ld bc,9
	ld (hl)," "
	ldir

	; get the type-byte for the 1st parameter
	call JGETINT
	add a,a				; test it
	jp m,PARAM_ERR		; jp if not a string (jp p if is string)	

	; String parameter
	call JSBUFFET		; DE=start BC=length
	ex de,hl			; HL=start
	ld de,filename		
	ldir				; copy to filename buffer

	pop af				; get remaining params
	jr z,checkdos		; skip ahead if none

	call JGETINT		; get type-byte
	add a,a				; test it
	jp p,PARAM_ERR		; error if string (not a number)
	
numeric:
	call JGETINT		; get the number
	ld (udgortok),a	; set it as the "use tokens" flag

; make sure SAMDOS is loaded
checkdos:
	ld a,(DOSFLG)
	or a
	jp z,DOS_ERR

	call init_screen

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;; DISK LOADER
	ld a,1
	ld hl,pack_loader
	call call_module

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

begin_translating:

	;; BTRANS
	ld a,0
	ld hl,pack_BTRANS
	call call_module

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;; VTRANS
	ld a,(NVARSP)
	ld hl,pack_VTRANS
	call call_module

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;; Debugging
	ld a,0
	ld hl,pack_debug
	call call_module

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;; Kickstart into BASIC
	ld a,1
	ld hl,pack_kick
	call call_module
	
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; fetch (and unpack) a module from
; RAM page #04
call_module:
	push af
	push hl
	ld a,4
	call SETHMPRA
	pop hl
	ld de,module
	call dzx0_standard
	pop af
	call SETHMPRA
	call module
	ret

;; borowed from BTRANS
;; set HMPR to page in A 
SETHMPRA:
	PUSH HL
	LD H,A
	IN A,(251)
	XOR H
	AND 224
	XOR H
	OUT (251),A
	POP HL
	RET

	; set up the screen colours
init_screen:
	ld a,%00000111
	ld (ATTRP),a
	ld (BORDCR),a
	xor a
	ld (BORDCOL),a
	call JMODE			; A=0 gives MODE1 (Spectrum)
	ret

DOS_ERR:
	rst 0x08
	defb 0x35	; "No DOS"
	
PARAM_ERR:
	rst 0x08
	defb 0x1B	; "Invalid argument"

page:		defb 0x00		; temp store for HMPR
sector:		defb 0x01		; sector address lo (sector)
track:		defb 0x00		; sector address hi (track)
numsec:		defw 0x0000		; total sectors in file
record:		defw 0x0000		; current record
length:		defw 0x0000		; length of file in bytes
param1:		defw 0x0000		; PROG-->VARS offset
param2:		defw 0x0000		; Autostart line
zxvarsp:	defb 0x00		; ZX variables page
zxvarso:	defw 0x0000		; ZX variables offset
zxvars:		defw 0x0000		; ZX variables 64K address
varlen:		defw 0x0000		; ZX variables length
myqflg:		defb 0x00		; Quotes-flag backup
udgortok:	defb 0x00		; (0)UDGs T,U or (1)tokens SPECTRUM,PLAY
flags:		defb %00000000

	include "_print.asm"
	include "_strings.asm"
	include "src/dzx0_standard.asm"

filename:	defs 0x0A		; can safely overflow into extra space
module:		equ $
offset:		equ module-start