


; skip 9-byte PlusD/DiSCIPLE header
;	ld hl,(PROG)
;	ld bc,9
;	xor a
;	call JRECLAIM
; FARLDIR or XOINTERS is confused by something, so
; lets just LDIR instead! (Paging bug? Or misaligned Sysvars? Dunno.)

DRAWSAM:
	call tokens_off
	ld hl,samudgsprite    ; "PRINT AT" string
	ld b,samudgspritelen
	call print
	call tokens_restore

	ld a,1
	call SETHMPRA

	ld a,(flags)
	bit 1,a
	jr z,RECLAIM9B
	
	ld hl,(PROG)
	ld bc,(length)
	res 7,h
	set 6,h			; HL=5CD5
	add hl,bc
	jr add_markers


;; reclaim the 9-byte PlusD/DiSCIPLE header
;; from the top of the program
RECLAIM9B:
	ld bc,(length)
	ld de,(PROG)	; DE=9CD5
	res 7,d
	set 6,d			; DE=5CD5
	ld h,d
	ld a,e
	add 9
	ld l,a			; HL=5CDE
	ldir
	
	ex de,hl

add_markers:
	ld (hl),0x80
	push hl
		or a
		ld hl,(length)
		ld bc,(param1)
		sbc hl,bc
		ld b,h
		ld c,l
		inc bc
	pop hl	; HL=end marker
	ld d,h
	ld e,l
	inc de	; DE=end+1
	lddr	; shuffle BC bytes up by one

	inc hl
	
	ld (hl),0xFF			; BASIC end-marker needed by SAM
	inc hl
	ld (zxvars),hl			; loc'n of ZX BASIC vars
		
	ld a,(PROGP)
	call SETHMPRA
	; Update SAM BASIC system variables again
	; now that things have moved slightly
	ld bc,(length)
	inc bc
	inc bc
	call huffle
	call setnvars			; Assign NVARS=HL NVARSP=A
	call SETBASICVARS
	
;;;; Translate Spectrum BASIC to SAM BASIC ;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Most of this code comes directly from ;
; my disassembly of MGT's BTRANS.       ;
; Errors and (poor) label names are mine;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Translation routine
TRANSLATE:
  LD A,(PROGP)            ; Get PROGP
  CALL SETHMPRA           ; Make sure PROG is paged-in
  LD HL,(PROG)            ; Get PROG
  JR TRANSLATE_1
TRANSLATE_0:
  CALL TRANS
	xor a
	call activity_lamp_a
  INC HL
  BIT 6,H
  CALL NZ,SETHMPR
; Check first byte of PROG and end if top bits set.
TRANSLATE_1:
  LD A,(HL)
  AND %11000000
  JR Z,TRANSLATE_0
  LD (HL),255
  RET

; Main translation routine
TRANS:
  INC HL
  INC HL
  LD (POINTER),HL       ; Length of BASIC line (+ enter)
  INC HL
TRANS_0:
  INC HL
  call activity_lamp
TRANS_1:
  LD A,(HL)
  CP 14
  JR NZ,TRANS_2
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  LD A,(HL)
TRANS_2:
  CP 13                   ; Carriage return (End of Line)
  RET Z
  CP 0xA3
  jp z,TRANS_SPEC         ; If a==0xA3 then SPECTRUM token (or UDG "T")
  CP 0xA4
  jp z,TRANS_PLAY         ; If a==0xA4 then PLAY token (or UDG "U")
TRANS_2_48k:
  CP 0xA5                 ; Compare with $A5 ZX BASIC token RND (the first token)
  JP C,CHKCTRL            ; If A < $A5 then it's not a token. Jump to CHKCTRL
  PUSH HL                 ; Calculate offset into token lookup table
  LD HL,TOKENTABLE-0xA5   ;
  LD E,A                  ;
  LD D,0                  ;
  ADD HL,DE               ;
  LD E,(HL)               ; E = SAM token code
  POP HL
  LD (HL),E               ; Replace token in the program
  CP 202                  ; Spectrum token LINE
  LD A,E
  JR C,TRANS_5            ; If A < 202, then token may be a FUNCTION.
  SUB 162
  ADC A,D
  JR NZ,TRANS_4
  CALL SKIPCTRLCHARS
  CP 0x30                   ; ASCII "0"
  JR C,TRANS_1              ; If A < N, then C flag is set
  CP 0x3A                   ; ASCII ":" (just after "9")
  JR NC,TRANS_1				; If A >= N, then C flag is reset
  PUSH HL
TRANS_3:
  INC HL
  LD A,(HL)
  CP 14                   ; CHR$ 14, BASIC numeral marker
  JR NZ,TRANS_3
  INC HL
  INC HL
  CALL CHKBSPLF
  POP HL
  JR NZ,TRANS_0
  DEC (HL)
  DEC (HL)
  CALL INSVAR1
  LD (HL),49				; "1"
  JR TRANS_0
TRANS_4:
  LD A,E
  SUB 153
  ADC A,D
  JR NZ,TRANS_0
  INC HL
  CALL INSVAR1
  LD (HL),35				; "#"
  JR TRANS_0
TRANS_5:					; *** F U N C T I O N S *** ;
  SUB 136					; SAM Codes from 85H to FEH do not need a preceding FFH 
  ADC A,D
  JR Z,TRANS_0
  CALL INSVAR1
  LD (HL),255             ; Functions are stored with a preceding FF
  INC HL
  LD A,(HL)
  CP 95                   ; USR token
  JR Z,ASCII
  CP 66                   ; FN token
  JR NZ,TRANS_0
  CALL SKIPCTRLCHARS
  CALL SKIPCTRLCHARS
  CP 36                   ; ASCII "$"
  JR NZ,TRANS_6
  INC HL
TRANS_6:
  CALL INSVAR6
  PUSH HL
  LD HL,(POINTER)
  LD A,(HL)
  ADD A,6
  LD (HL),A
  JR NC,TRANS_7
  INC HL
  INC (HL)
TRANS_7:
  POP HL
  JP TRANS_0

; ASCII text handling
ASCII:
  PUSH HL
  CALL SKIPCTRLCHARS
  CP 34                   ; "
  JR Z,ASCII_1
  CP 194                  ; CHR$
  JR Z,ASCII_2
  CP 65                   ; A
  JR C,ASCII_3
  CP 91                   ; [
  JR C,ASCII_0
  CP 97                   ; a
  JR C,ASCII_3
  CP 123                  ; {
  JR NC,ASCII_3
ASCII_0:
  INC HL
  LD A,(HL)
  CP 36					; $
  JR Z,ASCII_2
  JR ASCII_3
ASCII_1:
  INC HL
  LD A,(HL)
  CP 128				; 0x80 (blocks and UDGs)
  JR NC,ASCII_2			; If A >= N, then C flag is reset.	
  AND 223				; 1101 1111
  ADD A,79
  LD (HL),A
ASCII_2:
  POP HL
  LD (HL),105			; "UDG"
  PUSH HL
ASCII_3:
  POP HL
  JP TRANS_0

; Check control characters
CHKCTRL:
  SUB 17				; 16 or 17 ignore (?)
  ADC A,0
  JP NZ,TRANS_0			; 
  CALL CHKBSPLF
  JP TRANS_0

; Check backspace and linefeed
CHKBSPLF:
  INC HL
  LD A,(HL)
  CP 8					; "Left" (backspace)
  RET C					; A < N, then C flag is set		
  CP 10					; Linefeed (?)
  RET NC				; A >= N, then C flag is reset
  ADD A,8				; 
  LD (HL),A
  CP A
  RET

; Add 1 byte at HL and move NVARS up
INSVAR1:
  PUSH HL
  LD BC,1
  CALL MVNVARS
  LD HL,(POINTER)
  INC (HL)
  JR NZ,INSVAR1_0
  INC HL
  INC (HL)
INSVAR1_0:
  POP HL
  RET

;; Added to account for Spectrum 128
;; tokens "PLAY" and "SPECTRUM",
;; which BTRANS would mistranslate as
;; e.g. token "BRIGHT"
TRANS_PLAY:
	ld a,(udgortok)
	or a
	ld a,(hl)
	jp z,TRANS_2_48k
	ld (hl),0xB7	;REM
	inc hl
	ld bc,5
	call MVNVARS
	ld (hl),"P"
	inc hl
	ld (hl),"L"
	inc hl
	ld (hl),"A"
	inc hl
	ld (hl),"Y"
	inc hl
	ld (hl)," "

	push hl
	ld hl,(POINTER)
	ld a,(hl)
	add a,5
	ld (hl),a
	jr nc,TRANS_PLAY_1
	inc hl;
	inc (hl)
TRANS_PLAY_1:
	pop hl
	jp TRANS_0

TRANS_SPEC:
	ld a,(udgortok)
	or a
	ld a,(hl)
	jp z,TRANS_2_48k
	ld bc,9
	call MVNVARS
	ld (hl),0xB7	;REM
	inc hl
	ld (hl),"S"
	inc hl
	ld (hl),"P"
	inc hl
	ld (hl),"E"
	inc hl
	ld (hl),"C"
	inc hl
	ld (hl),"T"
	inc hl
	ld (hl),"R"
	inc hl
	ld (hl),"U"
	inc hl
	ld (hl),"M"
	inc hl
	ld (hl)," "

	push hl
	ld hl,(POINTER)
	ld a,(hl)
	add a,9
	ld (hl),a
	jr nc,TRANS_SPEC_1
	inc hl;
	inc (hl)
TRANS_SPEC_1:
	pop hl
	jp TRANS_0


; High memory paging
;
; Used by the routine at TRANSLATE_0.
;
; Increase HMPR by one
SETHMPR:
  RES 6,H
  IN A,(251)              ; Get HMPR
  INC A

; Set HMPR to A
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

; Add 6 bytes by moving NVARS up
INSVAR6:
  LD BC,6
  CALL MVNVARS
  LD (HL),14
  INC HL
  LD A,254
  LD (HL),A
  INC HL
  LD (HL),A
  INC HL
  LD (HL),A
  INC HL
  INC HL
  RET

; Insert BC bytes at HL and Move NVARS up
MVNVARS:
  LD DE,(NVARS)           ; Get NVARS
  PUSH DE
  LD A,(NVARSP)           ; Get NVARSP
  PUSH AF
  XOR A
  LD (NVARSP),A           ; NVARSP = 0
  LD D,A
  LD E,A
  LD (NVARS),DE           ; NVARS = 0
  PUSH BC
  CALL JMKRBIG            ; JMKRBIG Open A pages and BC bytes at HL
  POP BC
  POP AF                  ; A = old NVARSP
  POP DE
  EX DE,HL                ; HL = old NVARS
  ADD HL,BC
  LD (NVARS),HL           ; NVARS += BC
  LD (NVARSP),A           ; NVARSP = old NVARSP
  EX DE,HL
  push hl
    ld hl,(zxvars)
    add hl,bc
    ld (zxvars),hl
  pop hl
  RET

; Step over sequences of control characters and spaces
SKIPCTRLCHARS:
	INC HL				; step fwd a char
	LD A,(HL)			; A=char
	CP 33				; 0x21 = ASCII "!"
	RET NC				; RET if A >= "!"
	JR SKIPCTRLCHARS	; repeat until something printable

;; pointer to the line-length bytes at
;; the start of the BASIC line being
;; processed so it can be updated as
;; extra bytes are added.
POINTER:
	DEFW 0x0000

;; Show some on-screen activity while the 
;; translation is taking place (as it may
;; take some time!)
activity_lamp:
	ld a,r			; a number that varies
	and %01000111
    jr nz,activity_lamp_a
	or 1			; not black (bg colour)
activity_lamp_a: 
    ld c,a			; backup colour value in C
	in a,(HMPR)		; get current HMPR
	ld b,a			; backup HMPR in B
	in a,(VMPR)		; get VMPR in A
	and %00011111	; …just the page number
	out (HMPR),a    ; page-in the screen RAM
    ld a,c			; retrieve the colour
    ; update screen attributes:
	ld (0x981C),a
	ld (0x981D),a
	ld (0x981E),a
	ld (0x983C),a
	ld (0x983D),a
	ld (0x983E),a
	ld (0x985C),a
	ld (0x985D),a
	ld (0x985E),a
	ld (0x987C),a
	ld (0x987D),a
	ld (0x987E),a
	ld a,b			; retrieve the HMPR
	out (HMPR),a	; page-out screen RAM
	ret

samudgsprite:
    ; PRINT AT 0,28; CHR$ etc etc
    defb 0x16,0,28,0x93,0x94,0x95
    defb 0x16,1,28,0x96,0x97,0x98
    defb 0x16,2,28,0x99,0x9A,0x9B
    defb 0x16,3,28,0x9C,0x9D,0x9E
samudgspritelen: equ $-samudgsprite