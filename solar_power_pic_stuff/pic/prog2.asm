	LIST p=16f877a ; Include file, change directory if needed
	INCLUDE "p16f877a.inc"

	CBLOCK 0x20
	length
	length2
	sleep_1
	sleep_2
	ENDC

	ORG 0x000 ; start at the reset vector
	nop

	GOTO main ; start the program

wait
wloop
	NOP
	NOP
	NOP
	DECFSZ sleep_2, F
	GOTO wloop
	RETURN

init
	BANKSEL TRISA  ; BANK1
	CLRF TRISA     ; set all bits on PORTA to output
	CLRF TRISB     ; set all bits on PORTB to output
	;;CLRF TRISC     ; set all bits on PORTC to output
	MOVLW b'00010000'
	MOVWF TRISC
	CLRF TRISD     ; set all bits on PORTD to output
	CLRF TRISE     ; set all bits on PORTE to output
	
	BANKSEL PORTA  ; BANK0
	CLRF PORTA
	CLRF PORTB
	CLRF PORTC
	CLRF PORTD
	CLRF PORTE
	RETURN
	
main
	CALL init

	BANKSEL PORTA  ; BANK0
	MOVLW 0x01
	MOVWF length
	MOVLW 0xFE
	MOVWF length2

loop1
	MOVF length, W
	MOVWF sleep_2
	MOVLW 0x01
	MOVWF PORTA
	CALL wait
	INCF length, F

	MOVF length2, W
	MOVWF sleep_2
	MOVLW 0x02
	MOVWF PORTA
	CALL wait

	DECFSZ length2, F
	GOTO loop1

	MOVLW 0x01
	MOVWF length
	MOVLW 0xFE
	MOVWF length2

loop2
	MOVF length, W
	MOVWF sleep_2
	MOVLW 0x04
	MOVWF PORTA
	CALL wait
	INCF length, F

	MOVF length2, W
	MOVWF sleep_2
	MOVLW 0x01
	MOVWF PORTA
	CALL wait

	DECFSZ length2, F
	GOTO loop2

	MOVLW 0x01
	MOVWF length
	MOVLW 0xFE
	MOVWF length2

loop3
	MOVF length, W
	MOVWF sleep_2
	MOVLW 0x02
	MOVWF PORTA
	CALL wait
	INCF length, F

	MOVF length2, W
	MOVWF sleep_2
	MOVLW 0x04
	MOVWF PORTA
	CALL wait

	DECFSZ length2, F
	GOTO loop3

	MOVLW 0x01
	MOVWF length
	MOVLW 0xFE
	MOVWF length2

	GOTO loop1

	END