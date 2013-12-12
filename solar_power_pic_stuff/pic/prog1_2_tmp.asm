	LIST p=16f877a ; Include file, change directory if needed
	INCLUDE "p16f877a.inc"

	CBLOCK 0x20
	mac_dest_1
	mac_dest_2
	mac_dest_3
	mac_dest_4
	mac_dest_5
	mac_dest_6
	mac_src_1
	mac_src_2
	mac_src_3
	mac_src_4
	mac_src_5
	mac_src_6
	mac_type_1
	mac_type_2 ; 14 bytes

	ip_version_and_header_length
	ip_dummy
	ip_length_1
	ip_length_2
	ip_packet_id_1
	ip_packet_id_2
	ip_flags_1
	ip_flags_2
	ip_ttl
	ip_protocol
	ip_header_checksum_1
	ip_header_checksum_2
	ip_src_1
	ip_src_2
	ip_src_3
	ip_src_4
	ip_dest_1
	ip_dest_2
	ip_dest_3
	ip_dest_4 ; 20 bytes (34 bytes total)

	udp_src_port_1
	udp_src_port_2
	udp_dest_port_1
	udp_dest_port_2
	udp_length_1
	udp_length_2
	udp_checksum_1
	udp_checksum_2 ; 8 bytes (42 bytes total)

	magic ; always 0xAB
	version
	eee
	sleep_1
	sleep_2

	spi_device_id
	spi_out_length
	spi_out_pointer
	spi_out_1
	spi_out_2
	spi_out_3
	spi_out_4
	spi_out_5
	spi_out_6
	spi_out_7
	spi_out_8
	spi_memory_dump

	ENDC

	INCLUDE "spi.inc"
	INCLUDE "eth.inc"

;	ORG 0x000 ; start at the reset vector
	nop

	GOTO main ; start the program

wait
	MOVLW 0xFF
	MOVWF sleep_2
	MOVLW 0xFF
	MOVWF sleep_1
wloop
	DECFSZ sleep_1, F
	GOTO wloop
	DECFSZ sleep_2, F
	GOTO wloop
	RETURN

init_vars
	MOVLW 0xf4
	MOVWF mac_dest_1
	MOVLW 0x6d
	MOVWF mac_dest_2
	MOVLW 0x04
	MOVWF mac_dest_3
	MOVLW 0xe7
	MOVWF mac_dest_4
	MOVLW 0xb2
	MOVWF mac_dest_5
	MOVLW 0x34
	MOVWF mac_dest_6
	MOVLW 0xE0
	MOVWF mac_src_1
	MOVLW 0xCB
	MOVWF mac_src_2
	MOVLW 0x4E
	MOVWF mac_src_3
	MOVLW 0x5E
	MOVWF mac_src_4    ; <<<
	MOVLW 0x87
	MOVWF mac_src_5    ; <<<
	MOVLW 0x8E
	MOVWF mac_src_6    ; <<<
	MOVLW 0x08
	MOVWF mac_type_1
	MOVLW 0x00
	MOVWF mac_type_2

	MOVLW 0x45
	MOVWF ip_version_and_header_length
	MOVLW 0x00
	MOVWF ip_dummy
	MOVLW 0x00
	MOVWF ip_length_1    ; <<<
	MOVLW 0x52
	MOVWF ip_length_2    ; <<< (including IP and UDP header)
	MOVLW 0x00
	MOVWF ip_packet_id_1 ; <<<
	MOVLW 0x00
	MOVWF ip_packet_id_2 ; <<< increment this before transmit
	MOVLW 0x40
	MOVWF ip_flags_1
	MOVLW 0x00
	MOVWF ip_flags_2
	MOVLW 0x40
	MOVWF ip_ttl
	MOVLW 0x11
	MOVWF ip_protocol
	MOVLW 0xB8
	MOVWF ip_header_checksum_1    ; <<<
	MOVLW 0x75
	MOVWF ip_header_checksum_2    ; <<<
	MOVLW 0xC0
	MOVWF ip_src_1
	MOVLW 0xA8
	MOVWF ip_src_2
	MOVLW 0x00
	MOVWF ip_src_3
	MOVLW 0xC9
	MOVWF ip_src_4
	MOVLW 0xC0
	MOVWF ip_dest_1
	MOVLW 0xA8
	MOVWF ip_dest_2
	MOVLW 0x00
	MOVWF ip_dest_3
	MOVLW 0x0C
	MOVWF ip_dest_4

	MOVLW 0x18
	MOVWF udp_src_port_1
	MOVLW 0xF7
	MOVWF udp_src_port_2
	MOVLW 0x18
	MOVWF udp_dest_port_1
	MOVLW 0xF8
	MOVWF udp_dest_port_2
	MOVLW 0x00
	MOVWF udp_length_1    ; <<<
	MOVLW 0x09
	MOVWF udp_length_2    ; <<< (including UDP header)
	MOVLW 0x00           
	MOVWF udp_checksum_1  ; ignore
	MOVLW 0x00
	MOVWF udp_checksum_2  ; ignore

	MOVLW 0x65 ; "e"
	MOVWF magic

	MOVLW 0x01
	MOVWF version
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

	CALL led_red_on

	CALL init_vars
	CALL spi_init
	CALL eth_init
;	CALL eth_leds_on

	CALL led_red_off
	CALL led_green_on

	RETURN

measure_input_1
	RETURN

measure_input_2
	RETURN

led_red_on
	BANKSEL PORTA ; BANK0
	BSF PORTB, 0
	RETURN

led_red_off
	BANKSEL PORTA ; BANK0
	BCF PORTB, 0
	RETURN

led_green_on
	BANKSEL PORTA ; BANK0
	BSF PORTB, 2
	RETURN

led_green_off
	BANKSEL PORTA ; BANK0
	BCF PORTB, 2
	RETURN

led_blue_on
	BANKSEL PORTA ; BANK0
	BSF PORTB, 1
	RETURN

led_blue_off
	BANKSEL PORTA ; BANK0
	BCF PORTB, 1
	RETURN
	
main
	CALL init
	
loop

	CALL led_green_off
	CALL led_red_on
	CALL wait
	MOVLW 0x00
	BTFSC PORTD, 3
	MOVLW 0xFF
	MOVWF eee
	CALL eth_send_packet
	CALL led_red_off
	CALL led_green_on
	CALL wait
	CALL wait
	CALL wait
	CALL wait
	CALL wait
	CALL wait
	CALL wait
	CALL wait
	CALL wait
	CALL wait
	CALL wait
	GOTO loop
	END