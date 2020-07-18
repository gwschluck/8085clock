
UPDDT	EQU	036Eh	; A register to data display
RDKBD	EQU	02E7h	; Read hex character into A
			; Be sure to unmask RST 5.5 using SIM - 08h
			; And enable interrupts using EI
DELAY	EQU	05F1h	; Counts down 16-bit DE register pair
OUTPUT	EQU	02B7h	; Send char to display
			; Reg A = 0 - Use Addr field
			;       = 1 - Use Data field
			; Reg B = 0 - Decimal point off
			;       = 1 - Decimal point on
			; REG HL- starting address of chars to be sent
			;  chars 0-F as expected
			;        10 - H
			;        11 - L
			;        12 - P
			;        13 - I
			;        14 - r
			;        15 - (blank)

SEED	EQU	08CH
POLY	EQU	00DH
PERIOD	EQU	050H

STKPTR	EQU	02080h

	ORG	STKPTR-4
STKBUF:	DB	0,0,0,0	; Starting values for clock: NA, seconds, minutes, hours


; Pseudo Code
; B = Hours (BCD Format)
; C = Minutes (BCD Format)
; D = Seconds (BCD Format)
;
	ORG 2800h
	

START:  LXI SP,STKBUF	; Initialize stack pointer

	
LOOP:	POP D		; Pop min/sec
	POP B		; Pop Hours
	CALL ADJUST	; Adjust all the times
	LXI H, BUFFER+6 ; 1 past end
	MOV E,D		; Move Seconds into E
	CALL WR_BUF	; Write to buffer, takes E and HL
	MOV E,C		; Move Minutes into E
	CALL WR_BUF	; Write to buffer, takes E and HL
	MOV E,B		; Move Hours into E
	CALL WR_BUF	; Write to buffer, takes E and HL

; Write the output
	PUSH B
	PUSH D
	XRA A		; Clear A - Use Address Field
	MVI B, 1	; B - Turn Decimal On
	CALL OUTPUT	; Write it
	MVI A, 1	; A - Use Data Field
	MVI B, 1	; B - Turn Decimal On
	LXI H, BUFFER+4 ; Point to Spot
	CALL OUTPUT	; Write it
	LXI D, 0CB94H	; Delay
	CALL D2
	JMP LOOP

; Adjust: Incremnets seconds and adjusts all counts
ADJUST: MVI E, 060h	; Set for Comparison 60 (BCD)
	MOV A, D	; Increment seconds
	INR A
	DAA
	MOV D, A
	CMP E		; If seconds >= 60, Seconds = 0, Increment Minutes
	RNZ		; No adjustments needed
	MVI D, 0	; Set seconds to 0
	MOV A, C	; Increment Minutes
	INR A
	DAA
	MOV C, A
	CMP E		; Compare Minutes to 60
	RNZ		; No adjustement needed
	MVI C, 0	; Set minutes to 0
	MOV A, B	; Increment Hours
	INR A
	DAA
	MOV B, A
	MVI E, 024h	; Set E to 24 (BCD)
	CMP E		; Compare Hours to 24
	RNZ		; No adjustement needed
	MVI B, 0	; Reset Hours
	RET



WR_BUF:	DCX H		; Decrement pointer
	MOV A,E		; Get Number
	ANI 00FH	; Mask low nibble
	MOV M,A		; Put in Buf
	DCX H		; Decrement Pointer
	MOV A,E		; Get Number
	RRC		; Shift 4 right
	RRC
	RRC
	RRC
	ANI 00FH	; Mask low nibble
	MOV M,A		; Put in Buf
	RET

D2:	PUSH D		; Put D up on the stack
	CALL DELAY	; Delay first half
	POP D
	CALL DELAY
	RET
	

	
	


BUFFER:	DB 0,0,0,0,0,0


