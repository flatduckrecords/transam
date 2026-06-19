KICKSTART:

	ld hl,(param2)
	ld a,h
	and l
	inc a
	jp nz,askautostart

	call ptak				; Press the Any Key
	call wait				; tum-te-tum	

autostart:
	call COMDF				; Compile any DEF FNs
	call speccyscreen
	ld a,0x01
	ld (NSPPC),a
	ld hl,(param2)
	ld (NEWPPC),HL
	ret
	  
noautostart:
	call speccyscreen
	RST 8
	DEFB 0                  ; Report code 0 (OK)
							  ; * * *   EXIT back to BASIC   * * *

; Autorun the program
; To return to the statement after your CALL, or anywhere else in the program for that matter, read the values from SUBPPC and PPC then INC the SUBPPC value and place it in NSPPC, and place the old PPC into NEWPPC. This will cause a GO TO of the specified line and statement when your machine code RETs.

speccyscreen:
	LD A,7
	OUT (254),A			; Set BORDER 7 (white)
	LD (BORDCOL),A		; BORDCOL: Value to send to border port
	LD A,56
	LD (BORDCR),A		; BORDCR: Attributes for lower screen
	LD (ATTRP),A		; ATTRP: Attributes for upper screen
	XOR A
	LD (BGFLG),A		; BGFLG: Block graphics flag
	CALL JMODE			; JMODE: Set screen MODE in A (and CLS)
	ret

ptak:				; press the any key
	ld a,0xFD
	call JSETSTRM   ; Open channel -3 (lower screen)
	ld hl,m4
	ld b,m4e-m4
	call print
	ret

askautostart:				; press the any key
	ld a,0xFD
	call JSETSTRM   ; Open channel -3 (lower screen)
	ld hl,m5
	ld b,m5e-m5
	call print
aaslp:
	call JWAITKEY
	cp "n"
	jp z,noautostart
	cp "y"
	jp z,autostart
	jr aaslp

m4:		defb 0x16,1,17,0x10,0x0F
		defm "Press any key "
		defb 0x12,1,">",0x12,0
m4e:
m5:		defb 0x16,1,14,0x10,0x0F
		defm "Autostart? [y/n] "
		defb 0x12,1,">",0x12,0
m5e:
