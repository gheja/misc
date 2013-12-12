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

	ORG 0x000 ; start at the reset vector
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

wait3
	RETURN
	CALL wait
	CALL wait
	CALL wait


wait4
	CALL wait3
	CALL wait3
	CALL wait3
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

spi_init
	BANKSEL PORTA ; BANK0
	BSF PORTD, 0

	BANKSEL TRISA ; BANK1
	MOVLW 0x40
	MOVWF SSPSTAT
	BANKSEL PORTA ; BANK0
	MOVLW 0x20
	MOVWF SSPCON

	MOVLW 0x00
	MOVWF spi_memory_dump ; disable memory dump on next packet

	RETURN

spi_send
	;; select device
	BANKSEL PORTA ; BANK0
	BCF PORTD, 0

	;; send the bytes
	MOVLW spi_out_1           ; seek to the first byte
	MOVWF FSR                 ; our pointer is "file select register"
spi_send_loop
	BCF SSPCON, 7             ; WCOL
	MOVF INDF, W              ; load the byte
	MOVWF SSPBUF              ; send the byte
	MOVF FSR, W
	MOVWF PORTB
	CALL wait3
	BANKSEL TRISA ; BANK1
spi_send_wait
	BTFSS SSPSTAT, BF
	GOTO spi_send_wait
	BANKSEL PORTA ; BANK0
	INCF FSR, F               ; increase the pointer
	DECFSZ spi_out_length, F  ; decrease the remaining byte counter
	GOTO spi_send_loop        ; go back if we have more bytes

	; ;;;; memory dump option!
	BTFSS spi_memory_dump, 0
	GOTO spi_no_dump
	BCF spi_memory_dump, 0     ; disable further memory dumps (endless loop)
	MOVLW 0x20                 ; set the pointer to the first byte
	MOVWF FSR
	MOVLW 0x60                 ; whole BANK0 "General Purpose Registry" memory
	MOVWF spi_out_length
	CALL led_blue_on
	GOTO spi_send_loop

spi_no_dump
	CALL led_blue_off
	MOVLW 0x00
	MOVWF PORTB

	;; deselect device
	BSF PORTD, 0
	CALL wait4
	
	RETURN


eth_init
	MOVLW 0x01 ; = eth
	MOVWF spi_device_id
	
	CALL wait
	CALL wait
	CALL wait
	;; eth: system reset (see doc 6.0)
	MOVLW 0xFF ; SC (reset)
	MOVWF spi_out_1

	MOVLW 0x01 ; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send

	CALL wait
	CALL wait
	CALL wait


	;; eth: select BANK0
	MOVLW 0xA0 ; BFC
	IORLW 0x1F ; ECON1 (1F)
	MOVWF spi_out_1
	MOVLW 0x03 ; xxxxxx00
	MOVWF spi_out_2

	MOVLW 0x02 ; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: set receive buffer start and end pointers (see doc 6.1)
	MOVLW 0x40 ; WCR
	IORLW 0x08 ; ERXSTL
	MOVWF spi_out_1
	MOVLW 0x00 ; ... ERXSTL
	MOVWF spi_out_2
	MOVLW 0x00 ; ... ERXSTH
	MOVWF spi_out_3
	MOVLW 0xFF ; ... ERXNDL
	MOVWF spi_out_4
	MOVLW 0x0F ; ... ERXNDH
	MOVWF spi_out_5
	
	MOVLW 0x05 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send

;optimization...
;	;; eth: select BANK2
;	MOVLW 0xA0 ; BFC
;	IORLW 0x1F ; ECON1 (1F)
;	MOVWF spi_out_1
;	MOVLW 0x03 ; xxxxxx00
;	MOVWF spi_out_2
;
;	MOVLW 0x02 ; spi: how many byte outputs follow
;	MOVWF spi_out_length
;	CALL spi_send

	MOVLW 0x80 ; BFS
	IORLW 0x1F ; ECON1
	MOVWF spi_out_1
	MOVLW 0x02 ; xxxxxx1x => xxxxxx10
	MOVWF spi_out_2

	MOVLW 0x02 ; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; init MAC parameters (see doc 6.5)
	MOVLW 0x40 ; WCR
	IORLW 0x00 ; MACON1 (00)
	MOVWF spi_out_1
	MOVLW 0x0D ; ... MACON1
	MOVWF spi_out_2
	MOVLW 0x00 ; ... MACON2
	MOVWF spi_out_3
	MOVLW 0x77 ; ... MACON3
	MOVWF spi_out_4
	MOVLW 0x03 ; ... MACON4
	MOVWF spi_out_5
	MOVLW 0x0F ; ... MABBIPG
	MOVWF spi_out_6
	
	MOVLW 0x06 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send

	
	;; init LEDs by writing the PHLCON register indirectly (see doc 2.6 and 3.3.2)
	MOVLW 0x40 ; WCR
	IORLW 0x14 ; MIREGADR (14)
	MOVWF spi_out_1
	MOVLW 0x14 ; ... MIREGADR (14 = eth PHLCON)
	MOVWF spi_out_2
	MOVLW 0x00 ; ... -
	MOVWF spi_out_3
	MOVLW 0x72 ; ... MIWRL
	MOVWF spi_out_4
	MOVLW 0x04 ; ... MIWRH
	MOVWF spi_out_5
	
	MOVLW 0x05 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send

	RETURN

;;; test function to turn on both LEDs on eth
;eth_leds_on
;	BANKSEL PORTA ; BANK0
;
;	MOVLW 0x01 ; = eth
;	MOVWF spi_device_id
;
;	;; eth select BANK2
;	MOVLW 0xA0 ; BFC
;	IORLW 0x1F ; ECON1 (1F)
;	MOVWF spi_out_1
;	MOVLW 0x03
;	MOVWF spi_out_2
;
;	MOVLW 0x02 ; spi: how many byte outputs follow
;	MOVWF spi_out_length
;	CALL spi_send
;
;	MOVLW 0x80 ; BFS
;	IORLW 0x1F ; ECON1 (1F)
;	MOVWF spi_out_1
;	MOVLW 0x02
;	MOVWF spi_out_2
;
;	MOVLW 0x02 ; spi: how many byte outputs follow
;	MOVWF spi_out_length
;	CALL spi_send
;
;
;	MOVLW 0x40 ; WCR
;	IORLW 0x14 ; MIREGADR (14)
;	MOVWF spi_out_1
;	MOVLW 0x14 ; ... MIREGADR (14 = eth PHLCON)
;	MOVWF spi_out_2
;	MOVLW 0x00 ; ... -
;	MOVWF spi_out_3
;	MOVLW 0x82 ; ... MIWRL
;	MOVWF spi_out_4
;	MOVLW 0x08 ; ... MIWRH
;	MOVWF spi_out_5
;	
;	MOVLW 0x05 ;; spi: how many byte outputs follow
;	MOVWF spi_out_length
;	CALL spi_send
;
;	RETURN

eth_send_packet
	BANKSEL PORTA ; BANK0

	;; eth: select BANK0
	MOVLW 0xA0 ; BFC
	IORLW 0x1F ; ECON1 (1F)
	MOVWF spi_out_1
	MOVLW 0x03 ; xxxxxx00
	MOVWF spi_out_2

	MOVLW 0x02 ; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: set up ETXST (see doc 7.1.1)
	MOVLW 0x40 ; WCR
	IORLW 0x04 ; ETXSTL
	MOVWF spi_out_1
	MOVLW 0x00 ; ... ETXSTL
	MOVWF spi_out_2
	MOVLW 0x10 ; ... ETXSTH
	MOVWF spi_out_3
	
	MOVLW 0x03 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: set up EWRPT (see doc 7.1.1)
	MOVLW 0x40 ; WCR
	IORLW 0x02 ; EWRPTL
	MOVWF spi_out_1
	MOVLW 0x00 ; ... EWRPTL
	MOVWF spi_out_2
	MOVLW 0x10 ; ... EWRPTH
	MOVWF spi_out_3
	
	MOVLW 0x03 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: send the "per packet control byte" and the data payload (see doc 7.1.2)
	;;      the payload is actually the whole memory :)
	MOVLW 0x60 ; WBM
	IORLW 0x1A ; required argument
	MOVWF spi_out_1
	MOVLW 0x00 ; the "per packet control byte"
	MOVWF spi_out_2
	
	BSF spi_memory_dump, 0 ; enable memory dump with next spi_send

	MOVLW 0x02 ;; spi: how many byte outputs follow (before the memory dump)
	MOVWF spi_out_length
	CALL spi_send
	

	;; eth: set up ETXND (see doc 7.1.3)
	MOVLW 0x40 ; WCR
	IORLW 0x06 ; ETXNDL
	MOVWF spi_out_1
	MOVLW 0x60 ; ... ETXNDL
	MOVWF spi_out_2
	MOVLW 0x10 ; ... ETXNDH
	MOVWF spi_out_3
	
	MOVLW 0x03 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: clear EIR.TXIF (see doc 7.1.4)
	MOVLW 0xA0 ; BFC
	IORLW 0x1C ; EIR
	MOVWF spi_out_1
	MOVLW 0x08 ; .TXIF => 0
	MOVWF spi_out_2
	
	MOVLW 0x02 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: set EIE.TXIE (see doc 7.1.4)
	MOVLW 0x80 ; BFS
	IORLW 0x1B ; EIE
	MOVWF spi_out_1
	MOVLW 0x80 ; .TXIF => 0
	MOVWF spi_out_2
	
	MOVLW 0x02 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: set ECON1.TXRTS (see doc 7.1.5)
	MOVLW 0x80 ; BFS
	IORLW 0x1F ; ECON1
	MOVWF spi_out_1
	MOVLW 0x08 ; .TXRTS => 1
	MOVWF spi_out_2
	
	MOVLW 0x02 ;; spi: how many outputs follow
	MOVWF spi_out_length
	CALL spi_send

	
	RETURN


init
	BANKSEL TRISA  ; BANK1
	CLRF TRISA     ; set all bits on PORTA to output
	CLRF TRISB     ; set all bits on PORTB to output
	;;CLRF TRISC     ; set all bits on PORTC to output
	MOVLW b'00010000'
	MOVWF TRISC
	;; CLRF TRISD     ; set all bits on PORTD to output
	MOVLW b'11111110'
	MOVWF TRISD
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
	BSF PORTA, 0
	RETURN

led_red_off
	BANKSEL PORTA ; BANK0
	BCF PORTA, 0
	RETURN

led_green_on
	BANKSEL PORTA ; BANK0
	BSF PORTA, 2
	RETURN

led_green_off
	BANKSEL PORTA ; BANK0
	BCF PORTA, 2
	RETURN

led_blue_on
	BANKSEL PORTA ; BANK0
	BSF PORTA, 1
	RETURN

led_blue_off
	BANKSEL PORTA ; BANK0
	BCF PORTA, 1
	RETURN
	
main
	CALL init
	
loop
	MOVLW 0x00
	BTFSC PORTD, 3
	MOVLW 0xFF
	MOVWF eee
	CALL led_green_off
	CALL led_red_on
	CALL eth_send_packet
	CALL led_red_off
	CALL led_green_on
	CALL wait
	CALL wait
	CALL wait
	CALL wait
	GOTO loop
	END