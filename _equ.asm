; Ports
HMPR:		equ 0xFB
VMPR:		equ 0xFC
	
; Character set
CTRL_PEN:	equ 0x10
CTRL_PAP:	equ 0x11
CTRL_BGT:	equ 0x13
CHR_RETN:	equ 0x0D
CHR_INVR:	equ 0x14
CHR_QUOT:	equ 0x22
CHR_DOLA:	equ 0x24
CHR_EQUA:	equ 0x3D
TOK_LINE:	equ 0x8C
TOK_TO:		equ 0x8E
TOK_STEP:	equ 0x8F

; Floating point calculator
MULT:		equ 0x00	; N1*N2
DIVN:		equ 0x05	; N1/N2
SWOP:		equ 0x06	; Swap V1,V2
DUP:		equ 0x25
ONELIT:		equ 0x26	;Stack next byte on FPCS (0–255)
EXIT:		equ 0x33
EXIT2:		equ 0x34
INT:		equ 0x44
HEX:		equ 0x59

; 0x0100 Jump table
JHEAPROOM:	equ 0x0106
JMKRBIG:	equ 0x010C
JSETSTRM:	equ 0x0112
JGETINT:	equ 0x0121	; Unstack number from calculator stack into HL. (BC=HL A=L)
JSTKFETCH:	equ 0x0124	; Unstack last value from calculator stack to AEDCB.
JSTKSTORE:	equ 0x0127	; Stack AEDCB registers on the calculator stack
JSBUFFET:	equ 0x012A	; Unstack a string. DE=start BC=length
JFARLDIR:	equ 0x012D	; Copies bytes from page A, offset HL to page C, offset DE
JCLSBL:		equ 0x014E	; Clear entire screen if A=0, else clear upper screen
JMODE:		equ 0x015A
JRECLAIM:	equ 0x0163	; Reclaim (close up) BC bytes at HL (8000H-BFFFH)
JLOAD:		equ 0x0175
JSTR:		equ 0x017E
STACKBC: 	equ 0x1CDD

JKBFLUSH:	equ 0x0166	; Flush keyboard buffer.
JREADKEY:	equ 0x0169	; Read keyboard, flush butter. Z/NC if no key pressed, else NZ/CY and A=key
JWAITKEY:	equ 0x016C	; Wait for a key to be pressed. Read next key into A from keyboard buffer


; System variables

CHARS:		equ 0x5190	; (2) Address 256 bytes below start of main character set
SLDEV:		equ 0x5A06	; Current device letter (T, D or N)
SELNUM:		equ 0x5A07	; Default drive number (or tape speed)
BGFLG:		equ 0x5A34	; Block graphics flag
CSIZEH:		equ 0x5A36	; Character height set by CSIZE command
ATTRP:		equ 0x5A45	; Attributes used by modes 1 and 2
DESTP:		equ 0x5AA5	; Used in variable assignments
;~~ BASIC system pointers ~~;
SAVARSP:	equ 0x5A81
SAVARS:		equ 0x5A82
NUMENDP:	equ 0x5A84
NUMEND:		equ 0x5A85
NVARSP:		equ 0x5A87
NVARS:		equ 0x5A88
DATADDP:	equ 0x5A8A
DATADD:		equ 0x5A8B	; (2) Data address used by READ command
WKENDP:		equ 0x5A8D
WKEND:		equ 0x5A8E
WORKSPP:	equ 0x5A90
WORKSP:		equ 0x5A91
ELINEP:		equ 0x5A93
ELINE:		equ 0x5A94
PROGP:		equ 0x5A9F
PROG:		equ 0x5AA0
INQUFG:		equ 0x5ABA	; "In quotes" flag. Bit 0=1 if character being printed is inside quotes.
;~~ BASIC system pointers ~~;
SLDEVT:		equ 0x5BB7
PAGCOUNT:	equ 0x5B83	; Page counter used by FARLDIR and FARLDDR.
MODCOUNT:	equ 0x5B84	; (2) MOD 16K counter used by FARLDIR and FARLDDR.
DOSFLG:		equ 0x5BC2	; Zero if no DOS loaded, else page number.
BSTKEND:	equ 0x5BC4	; (2) End of Basic's stack (used by DO, GOSUB, procedures).
BASSTK:		equ 0x5BC6	; (2)	Start of Basic's stack.
HEAPEND:	equ 0x5BC8	; (2)	End of system heap.
HPST:		equ 0x5BCA	; (2)	Start of system heap.
NEWPPC:		equ 0x5C42	; (2) New line to jump to.
NSPPC:		equ 0x5C44	; New statement to jump to, or 0xFF.
BORDCR:		equ 0x5C48	; Attributes for lower screen in MODEs 1 and 2
BORDCOL:	equ 0x5C4B	; Value to send to border port
RAMTOP:		equ 0x5CB2
;PPC:		equ 0x5C45	; (2) Current line number during program execution
;SUBPPC:	equ 0x5C47	; Current statement number

; SAMROM
FNDLNHL:	equ 0x1A35
FNDLINE:	equ 0x1A4D
ADDRNV:		equ 0x1F1F
ASNN:		equ 0x2B51
TLBYTE:		equ 0x513F
FIRLET:		equ 0x5140
COMDF:		equ 0x2FD2	; Compile DEF FNs

; SAMDOS2
dos.hrsad:  equ 0xa0    ; read a sector from disk
dos.pcat:	equ 0xA5	; Print directory listing
