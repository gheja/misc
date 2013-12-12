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

	magic ; always 0x65
	eth_packet_type ; memory dump: 0x01
	version
	sleep_1
	sleep_2
	sleep_3

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

	ow_pd_byte ; presence detect (do we have anything on the wire?)
	ow_bits_left
	ow_buffer
	ow_current_device_0
	ow_current_device_1
	ow_current_device_2
	ow_current_device_3
	ow_current_device_4
	ow_current_device_5
	ow_current_device_6
	ow_current_device_7

	thermo1_msb
	thermo1_lsb
	thermo2_msb
	thermo2_lsb
	thermo3_msb
	thermo3_lsb

	ENDC

	ORG 0x000 ; start at the reset vector
	nop

	GOTO main ; start the program
; ==================================================================== common =
wait_1sec
	MOVLW 0x05
	MOVWF sleep_3
wait_1sec_loop1
	MOVLW 0xFF
	MOVWF sleep_2
	MOVLW 0xFF
	MOVWF sleep_1
wait_1sec_loop2
	DECFSZ sleep_1, F
	GOTO wait_1sec_loop2
	DECFSZ sleep_2, F
	GOTO wait_1sec_loop2
	DECFSZ sleep_3, F
	GOTO wait_1sec_loop1
	RETURN

wait_5us
	NOP              ;1us
	NOP              ;1us
	DECFSZ sleep_1,F ;1us or 2us
	GOTO wait_5us    ;2us
	RETLW 0          ;2us

;d wait3
;d	CALL wait
;d	CALL wait
;d	CALL wait
;d	RETURN

;d wait4
;d	CALL wait3
;d	CALL wait3
;d	CALL wait3
;d	RETURN

; ====================================================================== spi ==
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
;d	MOVF FSR, W
;d	MOVWF PORTB
;d	CALL wait3
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
;d	CALL led_blue_on
	GOTO spi_send_loop

spi_no_dump
;d	CALL led_blue_off
;d	MOVLW 0x00
;d	MOVWF PORTB

	;; deselect device
	BSF PORTD, 0
;d	CALL wait4
	
	RETURN

; ================================================================= ethernet ==
eth_init
	MOVLW 0x01 ; = eth
	MOVWF spi_device_id

	;; eth: system reset (see doc 6.0)
	MOVLW 0xFF ; SC (reset)
	MOVWF spi_out_1

	MOVLW 0x01 ; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send

	CALL wait_1sec

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

; =================================================================== 1-wire ==
	constant OW_PORT=PORTC
	constant OW_TRIS=TRISC
	constant OW_BIT=7

OW_HIZ:MACRO
;Force the DQ line into a high impedance (HiZ) state.
	BSF    STATUS,RP0      ; BANK1
	BSF    OW_TRIS, OW_BIT ; make DQ pin an input (HiZ)
	BCF    STATUS,RP0      ; BANK0
	ENDM

OW_LO:MACRO
;Force the DQ line to a logic low.
	BCF STATUS,RP0      ; BANK0
	BCF OW_PORT, OW_BIT ; Clear the DQ bit
	BSF STATUS,RP0      ; BANK1
	BCF OW_PORT, OW_BIT ; Make DQ pin an output
	BCF STATUS,RP0      ; BANK0
	ENDM

OW_WAIT:MACRO TIME ; wait for TIME us (microseconds), must be in multiples of 5
	MOVLW (TIME/5)-1 ; 1us
	MOVWF sleep_1    ; 1us
	CALL wait_5us    ; 2us
	ENDM

ow_strong_pullup_start
	BANKSEL PORTA  ; BANK0
	OW_HIZ         ; bring it up
	CALL wait_1sec
	OW_LO          ; bring down DQ
	RETURN

ow_reset
	BANKSEL PORTA         ; BANK0
	OW_HIZ                ; Start with the line high
	MOVLW 0x00
	MOVWF ow_pd_byte      ; Clear the PD byte
	OW_LO                 ; bring down DQ
	OW_WAIT .500          ; ... for 500 us
	OW_HIZ                ; bring it back up
	OW_WAIT .70           ; ... for 70 us to wait for PD pulse
	BTFSS OW_PORT, OW_BIT ; read for a PD Pulse
	INCF ow_pd_byte, F    ; set PDBYTE to 1 if get a PD pulse
	OW_WAIT .400          ; wait 400us after PD pulse (kill the line)
	RETURN

ow_receive_byte
	BANKSEL PORTA              ; BANK0
	MOVLW .8
	MOVWF ow_bits_left         ; we are waiting for 8 bits
ow_receive_byte_loop
    OW_LO                      ; bring down DQ
    NOP                        ; ... and wait 6us
    NOP
    NOP
    NOP
    NOP
    NOP
    OW_HIZ                     ; change to HiZ 
	NOP                        ; wait 4µs
	NOP
	NOP
	NOP                        
	MOVF OW_PORT, W            ; read DQ
	ANDLW 1<<OW_BIT            ; mask off the DQ bit
	ADDLW 0xFF                 ; C=1 if DQ=1: C=0 if DQ=0
	RRF ow_buffer, F           ; shift C into IOBYTE
	OW_WAIT .50                ; wait 50µs to end of time slot
	DECFSZ ow_bits_left, F     ; decrement the bit counter
	GOTO ow_receive_byte_loop
	MOVF ow_buffer, W
	RETURN

ow_send_byte
	BANKSEL PORTA          ; BANK0
	MOVWF ow_buffer        ; send the byte from W to ow_buffer
	MOVLW .8
	MOVWF ow_bits_left     ; we are sending 8 bits
ow_send_byte_loop
	OW_LO                  ; bring down DQ
	NOP                    ; ... and wait 3us
	RRF ow_buffer,F        ; get the first bit by shifting the buffer rightwise (EXPLAIN!)
	BSF STATUS,RP0         ; BANK1
	BTFSC STATUS,C         ; if the first bit (LSB) is 1 ...
	BSF OW_TRIS,OW_BIT     ; ... then HiZ the output
	BCF STATUS,RP0         ; BANK0
	OW_WAIT .60            ; keep the output this way for 60us
	OW_HIZ                 ; HiZ the output (even if it was HiZ'd before)
	NOP                    ; recovery time (2us total)
	NOP
	DECFSZ ow_bits_left, F ; one less bits left
	GOTO ow_send_byte_loop
	RETURN

; ===================================================================== main ==
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
	MOVLW 0x01 ; memory dump
	MOVWF eth_packet_type

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

	CALL wait_1sec
	
	CALL init_vars
	CALL spi_init
	CALL eth_init
;	CALL eth_leds_on

	CALL led_red_off
	CALL led_green_on

	RETURN
	
main
	CALL init

loop
	CALL wait_1sec

	CALL led_green_off
	CALL led_red_on

;	CALL ow_reset
;	MOVLW 0x33 ; find one device
;	CALL ow_send_byte
;	CALL ow_receive_byte
;	MOVWF ow_current_device_0
;	CALL ow_receive_byte
;	MOVWF ow_current_device_1
;	CALL ow_receive_byte
;	MOVWF ow_current_device_2
;	CALL ow_receive_byte
;	MOVWF ow_current_device_3
;	CALL ow_receive_byte
;	MOVWF ow_current_device_4
;	CALL ow_receive_byte
;	MOVWF ow_current_device_5
;	CALL ow_receive_byte
;	MOVWF ow_current_device_6
;	CALL ow_receive_byte
;	MOVWF ow_current_device_7

;	temperature sensors:
;	1: 1013 c1f5 0108 003b
;	2: 1033 9df5 0108 0039
;	3: 1079 94f5 0108 0070
;	4: 10f7 97f5 0108 00c7


	CALL ow_reset
	MOVLW 0x55 ; select device
	CALL ow_send_byte
	MOVLW 0x10
	CALL ow_send_byte
	MOVLW 0x13
	CALL ow_send_byte
	MOVLW 0xC1
	CALL ow_send_byte
	MOVLW 0xF5
	CALL ow_send_byte
	MOVLW 0x01
	CALL ow_send_byte
	MOVLW 0x08
	CALL ow_send_byte
	MOVLW 0x00
	CALL ow_send_byte
	MOVLW 0x3B
	CALL ow_send_byte
	MOVLW 0x44 ; convert T
	CALL ow_send_byte
	CALL ow_strong_pullup

	CALL ow_reset
	MOVLW 0x55 ; select device
	CALL ow_send_byte
	MOVLW 0x10
	CALL ow_send_byte
	MOVLW 0x13
	CALL ow_send_byte
	MOVLW 0xC1
	CALL ow_send_byte
	MOVLW 0xF5
	CALL ow_send_byte
	MOVLW 0x01
	CALL ow_send_byte
	MOVLW 0x08
	CALL ow_send_byte
	MOVLW 0x00
	CALL ow_send_byte
	MOVLW 0x3B
	CALL ow_send_byte
	MOVLW 0xBE ; read scratchpad
	CALL ow_send_byte
	CALL ow_receive_byte
	MOVWF thermo1_lsb
	CALL ow_receive_byte
	MOVWF thermo1_msb


	CALL ow_reset
	MOVLW 0x55 ; select device
	CALL ow_send_byte
	MOVLW 0x10
	CALL ow_send_byte
	MOVLW 0x33
	CALL ow_send_byte
	MOVLW 0x9D
	CALL ow_send_byte
	MOVLW 0xF5
	CALL ow_send_byte
	MOVLW 0x01
	CALL ow_send_byte
	MOVLW 0x08
	CALL ow_send_byte
	MOVLW 0x00
	CALL ow_send_byte
	MOVLW 0x39
	CALL ow_send_byte
	MOVLW 0x44 ; convert T
	CALL ow_send_byte
	CALL ow_strong_pullup

	CALL ow_reset
	MOVLW 0x55 ; select device
	CALL ow_send_byte
	MOVLW 0x10
	CALL ow_send_byte
	MOVLW 0x33
	CALL ow_send_byte
	MOVLW 0x9D
	CALL ow_send_byte
	MOVLW 0xF5
	CALL ow_send_byte
	MOVLW 0x01
	CALL ow_send_byte
	MOVLW 0x08
	CALL ow_send_byte
	MOVLW 0x00
	CALL ow_send_byte
	MOVLW 0x39
	CALL ow_send_byte
	MOVLW 0xBE ; read scratchpad
	CALL ow_send_byte
	CALL ow_receive_byte
	MOVWF thermo2_lsb
	CALL ow_receive_byte
	MOVWF thermo2_msb


	CALL ow_reset
	MOVLW 0x55 ; select device
	CALL ow_send_byte
	MOVLW 0x10
	CALL ow_send_byte
	MOVLW 0xf7
	CALL ow_send_byte
	MOVLW 0x97
	CALL ow_send_byte
	MOVLW 0xF5
	CALL ow_send_byte
	MOVLW 0x01
	CALL ow_send_byte
	MOVLW 0x08
	CALL ow_send_byte
	MOVLW 0x00
	CALL ow_send_byte
	MOVLW 0xC7
	CALL ow_send_byte
	MOVLW 0x44 ; convert T
	CALL ow_send_byte
	CALL ow_strong_pullup

	CALL ow_reset
	MOVLW 0x55 ; select device
	CALL ow_send_byte
	MOVLW 0x10
	CALL ow_send_byte
	MOVLW 0xf7
	CALL ow_send_byte
	MOVLW 0x97
	CALL ow_send_byte
	MOVLW 0xF5
	CALL ow_send_byte
	MOVLW 0x01
	CALL ow_send_byte
	MOVLW 0x08
	CALL ow_send_byte
	MOVLW 0x00
	CALL ow_send_byte
	MOVLW 0xC7
	CALL ow_send_byte
	MOVLW 0xBE ; read scratchpad
	CALL ow_send_byte
	CALL ow_receive_byte
	MOVWF thermo3_lsb
	CALL ow_receive_byte
	MOVWF thermo3_msb


	CALL eth_send_packet
	CALL led_red_off
	CALL led_green_on
	GOTO loop
	END
