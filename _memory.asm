;; Memory-management routines
;; Taken from BTRANS

setnvars:
	ld (NVARSP),a           ; NVARSP
	ld (NVARS),hl           ; NVARS
	ret

; in BC=prog offset, out A=PAGE HL=logical offset address
huffle:
	LD A,(PROGP)            ; PROGP
	LD HL,(PROG)            ; PROG  // 9CD5
shuffle:
	RLC H					; 39D5		;8-bit rotation left. <-- The bit on the left copied to carry and bit 0.
	RLC H					; 72D5
	RRA						; 0			; 9-bit rotation right. --> carry is moved to bit 7, bit on the right is moved to carry.
	RR H					; 39D5
	RRA						; 0
	RR H					; 1CD5 
	AND 7					; 0
	ADD HL,BC				; 9E4D
	ADC A,0					; 0
	RL H					; 3C4D
	RLA						; 1
	RL H					; 784D
	RLA						; 2
	RR H					; 3C4D
	SCF						;
	RR H					; 9E4D
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Set up BASIC system vars
SETBASICVARS:
	LD A,(NVARSP)           ; Get NVARSP
	AND 31
	LD (NUMENDP),A          ; Set NUMENDP
	LD (SAVARSP),A          ; Set SAVARSP
	LD (WKENDP),A           ; Set WKENDP
	LD (WORKSPP),A          ; Set WORKSPP
	LD (ELINEP),A           ; Set ELINEP
	CALL SETHMPRA
	LD A,255                ; $FF = unset
	LD HL,(NVARS)           ; Get NVARS
	LD B,46                 ; 46 values
RESETNVARS:
	LD (HL),A
	INC HL
	DJNZ RESETNVARS
	EX DE,HL
	LD HL,XYVARS
	LD C,26
	LDIR                    ; Copy 26 bytes from 4300h to DE
	LD HL,XYVARS + 6
	LD C,20
	LDIR                    ; Copy 20 bytes from 4306h to DE
	EX DE,HL
	LD (NUMEND),HL          ; Set NUMEND
	DEC HL
	DEC HL
	LD (HL),1
	DEC HL
	LD (HL),B
	INC HL
	INC HL
	INC HL
	INC H
	INC H
	LD (SAVARS),HL          ; Set SAVARS
	LD (HL),A
	INC HL
	LD (ELINE),HL           ; Set ELINE
	LD (HL),13
	INC HL
	LD (HL),A
	INC HL
	LD (WORKSP),HL          ; Set WORKSP
	LD (WKEND),HL           ; Set WKEND
	ld hl,(PROG)
	dec hl				; DATADD normally points to PROG-1
	ld (DATADD),hl		; "RESTORE" READ/DATA pointer
	ld a,(PROGP)
	ld (DATADDP),a
	RET
  
; Default numerical variables
; XOS, XRG, YOS, YRG
XYVARS:
	DEFB 25,0,3,0,255,255,2,8
	DEFB 0,111,115,0,0,0,0,0
	DEFB 2,255,255,114,103,0,0,192
	DEFB 0,0