
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

STKPTR	EQU	020C8h

DLPRD	EQU	0FA18h

CNTVAR  EQU     01406h ; Use D as 'r' constatnt and init E loop counter


; Pseudo Code
; B = Hours (BCD Format)
; C = Minutes (BCD Format)
; D = Seconds (BCD Format)
;
	ORG 2800h
	

START:  LXI SP,STKPTR	; Initialize stack pointer

	MVI A, 08H	; Set keyboard interrupt mask
	SIM
; Get user input into buffer

; Starting with the high order digit of hours
	LXI H, BUFFER   ; Set pointer
	LXI D, CNTVAR	; Use D as 'r' constatnt and init E loop counter
INLOOP:	MOV M, D        ; store 'r' at location
	PUSH H          ; Put HL on the stack
	PUSH D          ; Put DE on the stack
	LXI H, BUFFER   ; Set pointer to start of buffer
	CALL PR_BUF	; Output Display
	CALL RDKBD
	POP D		; Get DE off stack
	POP H		; Get current char pointer off the stack
	MOV M, A	; Put the new number in the buffer
	INX H		; Increment the pointer
	DCR E		; Decrement Loop Counter
	JNZ INLOOP
	
	MVI A, 00H	; Clear keyboard interrupt mask
	SIM
	NOP
;
; Read the buffer into B and D
;
	LXI H, BUFFER   ; Set pointer
	CALL RD_BUF	; Read Hours
	MOV B, A	; Store Hours
	CALL RD_BUF	; Read Minutes
	MOV C, A	; Store Minutes
	CALL RD_BUF	; Read Second
	MOV D, A	; Store Seconds


	
LOOP:	CALL ADJUST	; Adjust all the times
	LXI H, BUFFER+6 ; 1 past end
	MOV E,D		; Move Seconds into E
	CALL WR_BUF	; Write to buffer, takes E and HL
	MOV E,C		; Move Minutes into E
	CALL WR_BUF	; Write to buffer, takes E and HL
	MOV E,B		; Move Hours into E
	CALL WR_BUF	; Write to buffer, takes E and HL

; Write the output
	PUSH B		; Push time
	PUSH D
	CALL PR_BUF     ; Print the output to the display
	LXI D, DLPRD	; Delay
	PUSH D		; Put D up on the stack
	CALL DELAY	; Delay first half
	POP D
	CALL DELAY
	POP D		; Pop time
	POP B
	JMP LOOP



; ---------
; Subroutine
; PR_BUF: Print Buffer
; Arguments:
;   HL - Buffer pointer
; Clobbers:
;   A, B, C, D, E, H, L
; Retunrs:
;   none
; ---------
PR_BUF:	XRA A		; Clear A - Use Address Field
	MVI B, 1	; B - Turn Decimal On
	PUSH H
	CALL OUTPUT	; Write it
	POP H
	INX H
	INX H
	INX H
	INX H
	MVI A, 1	; A - Use Data Field
	MVI B, 1	; B - Turn Decimal On
	LXI H, BUFFER+4 ; Point to Spot
	CALL OUTPUT	; Write it
	RET		; Return

; ---------
; Subroutine
; ADJUST: Incremnets seconds and adjusts all counts
; Arguments:
;   B = Hours (BCD Format)
;   C = Minutes (BCD Format)
;   D = Seconds (BCD Format)
; Clobbers:
;   A, E
; Retunrs:
;   B, C, D - Updated H, M, S
; ---------
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

; ---------
; Subroutine
; WR_BUF: Writes the value in E to a character buffer pointed to by H
;         Note the highest order nibble is written to H-1 and lowest order nibble H-2
; Arguments:
;   E - BCD value
;   HL - Pointer
; Clobbers:
;   A
; Retunrs:
;   HL - Pointer decremented by 2
; ---------
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

; ---------
; Subroutine
; RD_BUF: Read byte from the string pointed to by HL
; Arguments:
;   HL - Pointer
; Clobbers:
;   A,E
; Retunrs:
;   A  - Byte read
;   HL - Pointer incremented by 2
; ---------
; Subroutine
RD_BUF:	MOV A, M        ; Get first byte
	RLC 		; Rotate left 4 bits
	RLC 
	RLC 
	RLC 
	INX H		; Incement pointer - Next byte
	MOV E, M        ; Get second byte
	ADD E		; No we have the byte
	INX H		; Incement pointer - Next byte
	RET


	

	
	


BUFFER:	DB 0,0,0,0,0,0


