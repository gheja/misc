	LIST p=16f877a ; Include file, change directory if needed
	INCLUDE "p16f877a.inc"

	COUNTER   EQU 0x20

     ORG 000H

     GOTO MAIN

     ORG 004H

     GOTO INT_SERV

MAIN:
     BSF STATUS, RP0     ; bank 1
     MOVLW 0xff
     MOVWF TRISB
     MOVLW 0x00
     MOVWF TRISA
     BCF STATUS, RP0     ; back to bank 0

	CLRF COUNTER        ; zero the counter
	
	MOVLW 0x01
	MOVWF PORTA

     BSF OPTION_REG, INTEDG   ; interrupt on positive
;     BCF INTCON, INTF    ; clear interrupt flag
     BCF INTCON, RBIF    ; clear interrupt flag
;     BSF INTCON, INTE    ; mask for external interrupts
     BSF INTCON, RBIE    ; mask for external interrupts
	BSF INTCON, GIE     ; enable interrupts

PT1: SLEEP
     GOTO PT1

INT_SERV:
	INCF COUNTER, F
	MOVF COUNTER
	MOVF PORTA
     
;	BCF INTCON, INTF    ; clear the appropriate flag
	BCF INTCON, RBIF    ; clear the appropriate flag
	RETFIE              ; this also set global interrupt enable

	END