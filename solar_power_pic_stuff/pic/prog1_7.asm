	LIST p=16f877a ; Include file, change directory if needed
	INCLUDE "p16f877a.inc"

	CBLOCK 0x20
	mac_dest_0
	mac_dest_1
	mac_dest_2
	mac_dest_3
	mac_dest_4
	mac_dest_5
	mac_src_0
	mac_src_1
	mac_src_2
	mac_src_3
	mac_src_4
	mac_src_5
	mac_type_0
	mac_type_1 ; 14 bytes

	ip_version_and_header_length
	ip_dummy
	ip_length_0
	ip_length_1
	ip_packet_id_0
	ip_packet_id_1
	ip_flags_0
	ip_flags_1
	ip_ttl
	ip_protocol
	ip_header_checksum_0
	ip_header_checksum_1
	ip_src_0
	ip_src_1
	ip_src_2
	ip_src_3
	ip_dest_0
	ip_dest_1
	ip_dest_2
	ip_dest_3 ; 20 bytes (34 bytes total)

	udp_src_port_0
	udp_src_port_1
	udp_dest_port_0
	udp_dest_port_1
	udp_length_0
	udp_length_1
	udp_checksum_0
	udp_checksum_1 ; 8 bytes (42 bytes total)

	magic ; always 0x65
	eth_packet_type ; memory dump: 0x01
	version
	eee
	sleep_0
	sleep_1
	sleep_2
	interrupts
	wfi_loops_left

	timer_time_0
	timer_time_1
	timer_time_2
	timer_time_3
	timer_interrupts
;	timer_interval_passed ; xxxxDHMS (day passed, hour passed, ...)

	spi_device_id
	spi_out_length
	spi_out_0
	spi_out_1
	spi_out_2
	spi_out_3
	spi_out_4
	spi_out_5
	spi_out_6
	spi_out_7
	spi_in
	spi_memory_start
	spi_checksum_0
	spi_checksum_1
	spi_options ; xxxxxx10, 0: checksum calculation, 1: spi checksum byte selector

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

	thermo_in_msb
	thermo_in_lsb
	thermo_in_xsb

	thermo1_value
	thermo1_value_fract
	thermo2_value
	thermo2_value_fract
	thermo3_value
	thermo3_value_fract
	thermo4_value
	thermo4_value_fract

	an4_0
	an4_1

	panic_bits ; xxxxxxx0 0=temperature_check

	ENDC

	CBLOCK 0x7F ; fixed bytes (from 0x70..7F)
	spi_memory_bank
	ENDC

; config: 0x3F3A

	ORG 0x0000 ; start at the reset vector
	GOTO main ; start the program

; ==================================================================== common =
SETF:MACRO TARGET, VALUE
	MOVLW VALUE
	MOVWF TARGET
	ENDM

MOVFF:MACRO TARGET, SOURCE
	MOVF SOURCE, W
	MOVWF TARGET
	ENDM

wait_long
	SETF sleep_1, 0x20
wait_long_loop1
	SETF sleep_0, 0xFF
wait_long_loop2
	DECFSZ sleep_0, F
	GOTO wait_long_loop2
	DECFSZ sleep_1, F
	GOTO wait_long_loop1
	RETURN

wait_longer
	SETF sleep_2, 0x10
wait_longer_loop1
	SETF sleep_1, 0xFF
wait_longer_loop2
	SETF sleep_0, 0xFF
wait_longer_loop3
	DECFSZ sleep_0, F
	GOTO wait_longer_loop3
	DECFSZ sleep_1, F
	GOTO wait_longer_loop2
	DECFSZ sleep_2, F
	GOTO wait_longer_loop1
	RETURN

wait_5us
	NOP              ;1us
	NOP              ;1us
	DECFSZ sleep_2,F ;1us or 2us
	GOTO wait_5us    ;2us
	RETLW 0          ;2us

; ====================================================================== spi ==
	constant SPI_PORT=PORTC
	constant SPI_TRIS=TRISC
	constant SPI_BIT=1

spi_init
	BANKSEL SPI_PORT ; BANK0
	MOVLW b'11000111'
	IORWF SPI_PORT, F

	BANKSEL TRISA ; BANK1
	MOVLW 0x40
	MOVWF SSPSTAT
	BANKSEL PORTA ; BANK0
	MOVLW 0x20
	MOVWF SSPCON
	
	SETF spi_checksum_0, 0x00
	SETF spi_checksum_1, 0x00
	SETF spi_options, 0x00
	RETURN

_spi_send_begin
	;; select device
	BANKSEL SPI_PORT ; BANK0
	MOVF spi_device_id, W
	XORWF SPI_PORT, F
	RETURN

_spi_send_memory
	BANKSEL PORTA             ; BANK0

	;; send the bytes
	MOVF spi_memory_start, W  ; seek to the first byte
	MOVWF FSR                 ; our pointer is "file select register"
_spi_send_loop
	BCF SSPCON, 7             ; WCOL
	
	BCF STATUS, RB0           ; clear memory bank selection bits
	BCF STATUS, RB1           ;
	BTFSC spi_memory_bank, 0
	BSF STATUS, RB0
	BTFSC spi_memory_bank, 1
	BSF STATUS, RB1

	MOVF INDF, W              ; load the byte

	BANKSEL PORTA ; BANK0
	MOVWF SSPBUF              ; send the byte
	BANKSEL TRISA ; BANK1
_spi_send_wait
	BTFSS SSPSTAT, BF
	GOTO _spi_send_wait
	BANKSEL PORTA ; BANK0
	MOVF SSPBUF, W
	MOVWF spi_in
	INCF FSR, F               ; increase the pointer
	DECFSZ spi_out_length, F  ; decrease the remaining byte counter
	GOTO _spi_send_loop        ; go back if we have more bytes
	RETURN

_spi_send_end
	BANKSEL SPI_PORT ; BANK0

	;; deselect device
	MOVF spi_device_id, W
	IORWF SPI_PORT, F
	RETURN

spi_send
	CALL _spi_send_begin

	SETF spi_memory_bank, 0x00
	SETF spi_memory_start, spi_out_0
	CALL _spi_send_memory
	CALL _spi_send_end
	RETURN

spi_send_and_dump
	CALL _spi_send_begin

	SETF spi_memory_start, spi_out_0
	; spi_out_length already set
	CALL _spi_send_memory

	SETF spi_checksum_0, 0x00
	SETF spi_checksum_1, 0x00
	BSF spi_options, 0 ; checksum calculation
	BCF spi_options, 1 ; first checksum byte selected

	SETF spi_memory_bank, 0x00
	SETF spi_memory_start, 0x20
	SETF spi_out_length, 0x2A
	CALL _spi_send_memory

	SETF spi_memory_bank, 0x00
	SETF spi_memory_start, 0x00
	SETF spi_out_length, 0x80
	CALL _spi_send_memory

	SETF spi_memory_bank, 0x01
	SETF spi_memory_start, 0x00
	SETF spi_out_length, 0x80
	CALL _spi_send_memory

	SETF spi_memory_bank, 0x02
	SETF spi_memory_start, 0x00
	SETF spi_out_length, 0x80
	CALL _spi_send_memory

	SETF spi_memory_bank, 0x03
	SETF spi_memory_start, 0x00
	SETF spi_out_length, 0x80
	CALL _spi_send_memory

	CALL _spi_send_end
	RETURN

; ================================================================= ethernet ==
eth_init
	MOVLW 0x02 ; = eth
	MOVWF spi_device_id

	;; eth: system reset (see doc 6.0)
	MOVLW 0xFF ; SC (reset)
	MOVWF spi_out_0

	MOVLW 0x01 ; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send

	CALL wait_long

	;; eth: select BANK0
	MOVLW 0xA0 ; BFC
	IORLW 0x1F ; ECON1 (1F)
	MOVWF spi_out_0
	MOVLW 0x03 ; xxxxxx00
	MOVWF spi_out_1

	MOVLW 0x02 ; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: set receive buffer start and end pointers (see doc 6.1)
	MOVLW 0x40 ; WCR
	IORLW 0x08 ; ERXSTL
	MOVWF spi_out_0
	MOVLW 0x00 ; ... ERXSTL
	MOVWF spi_out_1
	MOVLW 0x00 ; ... ERXSTH
	MOVWF spi_out_2
	MOVLW 0xFF ; ... ERXNDL
	MOVWF spi_out_3
	MOVLW 0x0F ; ... ERXNDH
	MOVWF spi_out_4
	
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
	MOVWF spi_out_0
	MOVLW 0x02 ; xxxxxx1x => xxxxxx10
	MOVWF spi_out_1

	MOVLW 0x02 ; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; init MAC parameters (see doc 6.5)
	MOVLW 0x40 ; WCR
	IORLW 0x00 ; MACON1 (00)
	MOVWF spi_out_0
	MOVLW 0x0D ; ... MACON1
	MOVWF spi_out_1
	MOVLW 0x00 ; ... MACON2
	MOVWF spi_out_2
	MOVLW 0x77 ; ... MACON3
	MOVWF spi_out_3
	MOVLW 0x03 ; ... MACON4
	MOVWF spi_out_4
	MOVLW 0x0F ; ... MABBIPG
	MOVWF spi_out_5
	
	MOVLW 0x06 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send

	
	;; init LEDs by writing the PHLCON register indirectly (see doc 2.6 and 3.3.2)
	MOVLW 0x40 ; WCR
	IORLW 0x14 ; MIREGADR (14)
	MOVWF spi_out_0
	MOVLW 0x14 ; ... MIREGADR (14 = eth PHLCON)
	MOVWF spi_out_1
	MOVLW 0x00 ; ... -
	MOVWF spi_out_2
	MOVLW 0x72 ; ... MIWRL
	MOVWF spi_out_3
	MOVLW 0x04 ; ... MIWRH
	MOVWF spi_out_4
	
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
	MOVLW 0x02 ; = eth
	MOVWF spi_device_id

	;; eth: select BANK0
	MOVLW 0xA0 ; BFC
	IORLW 0x1F ; ECON1 (1F)
	MOVWF spi_out_0
	MOVLW 0x03 ; xxxxxx00
	MOVWF spi_out_1

	MOVLW 0x02 ; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: set up ETXST (see doc 7.1.1)
	MOVLW 0x40 ; WCR
	IORLW 0x04 ; ETXSTL
	MOVWF spi_out_0
	MOVLW 0x00 ; ... ETXSTL
	MOVWF spi_out_1
	MOVLW 0x10 ; ... ETXSTH
	MOVWF spi_out_2
	
	MOVLW 0x03 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: set up EWRPT (see doc 7.1.1)
	MOVLW 0x40 ; WCR
	IORLW 0x02 ; EWRPTL
	MOVWF spi_out_0
	MOVLW 0x00 ; ... EWRPTL
	MOVWF spi_out_1
	MOVLW 0x10 ; ... EWRPTH
	MOVWF spi_out_2
	
	MOVLW 0x03 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: send the "per packet control byte" and the data payload (see doc 7.1.2)
	;;      the payload is actually the whole memory :)
	MOVLW 0x60 ; WBM
	IORLW 0x1A ; required argument
	MOVWF spi_out_0
	MOVLW 0x00 ; the "per packet control byte"
	MOVWF spi_out_1
	
;	BSF spi_memory_dump, 0 ; enable memory dump with next spi_send

	MOVLW 0x02 ;; spi: how many byte outputs follow (before the memory dump)
	MOVWF spi_out_length
;	CALL spi_send
	CALL spi_send_and_dump
	

	;; eth: set up ETXND (see doc 7.1.3)
	MOVLW 0x40 ; WCR
	IORLW 0x06 ; ETXNDL
	MOVWF spi_out_0
;	MOVLW 0x60 ; ... ETXNDL
	MOVLW 0x2A ; ... ETXNDL
	MOVWF spi_out_1
;	MOVLW 0x10 ; ... ETXNDH
	MOVLW 0x12 ; ... ETXNDH
	MOVWF spi_out_2
	
	MOVLW 0x03 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: clear EIR.TXIF (see doc 7.1.4)
	MOVLW 0xA0 ; BFC
	IORLW 0x1C ; EIR
	MOVWF spi_out_0
	MOVLW 0x08 ; .TXIF => 0
	MOVWF spi_out_1
	
	MOVLW 0x02 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: set EIE.TXIE (see doc 7.1.4)
	MOVLW 0x80 ; BFS
	IORLW 0x1B ; EIE
	MOVWF spi_out_0
	MOVLW 0x80 ; .TXIF => 0
	MOVWF spi_out_1
	
	MOVLW 0x02 ;; spi: how many byte outputs follow
	MOVWF spi_out_length
	CALL spi_send


	;; eth: set ECON1.TXRTS (see doc 7.1.5)
	MOVLW 0x80 ; BFS
	IORLW 0x1F ; ECON1
	MOVWF spi_out_0
	MOVLW 0x08 ; .TXRTS => 1
	MOVWF spi_out_1
	
	MOVLW 0x02 ;; spi: how many outputs follow
	MOVWF spi_out_length
	CALL spi_send

	
	RETURN

; 0x00 zero
; 0x01 send dhcpdiscover
; 0x02 waiting for dhcpoffer
; 0x03 send dhcprequest
; 0x04 waiting for dhcpack -> 0x06, 0x08, 0x0A
; 0x06 send "whohas <gw>" arp request
; 0x07 wait for arp result
; 0x08 send ntp request
; 0x09 wait for ntp response
; 0x0A wait for TCP SYN on port 80 (save target IP and MAC)
; 0x0B send TCP SYN/ACK
; 0x0C wait for ACK (and data?)
; 0x0D wait for data
; 0x0E send TCP ACK and data 

; ====================================================================== mem ==
mem_read
	BANKSEL PORTA        ; BANK0
	MOVLW 0x01           ; = mem
	MOVWF spi_device_id

	SETF spi_out_0, 0x05 ; RDSR (read status register)
	SETF spi_out_1, 0x00 ; dummy
	SETF spi_out_length, 0x02
	CALL spi_send

	RETURN

mem_init
	BANKSEL PORTA        ; BANK0
	MOVLW 0x01           ; = mem
	MOVWF spi_device_id

	SETF spi_out_0, 0x01  ; WRSR (write status register)
	SETF spi_out_1, 0x80 ; 
	SETF spi_out_length, 0x02
	CALL spi_send

	SETF spi_out_0, 0x06  ; WREN
	SETF spi_out_length, 0x01
	CALL spi_send

	RETURN

; ============================================================== ow (1-wire) ==
	constant OW_PORT=PORTD
	constant OW_TRIS=TRISD
	constant OW_BIT=3

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
	MOVWF sleep_2    ; 1us
	CALL wait_5us    ; 2us
	ENDM

ow_strong_pullup_begin
	BANKSEL PORTA  ; BANK0
	OW_HIZ         ; bring it up
	RETURN

ow_strong_pullup_end
	BANKSEL PORTA  ; BANK0
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
	NOP                        ; wait 4�s
	NOP
	NOP
	NOP                        
	MOVF OW_PORT, W            ; read DQ
	ANDLW 1<<OW_BIT            ; mask off the DQ bit
	ADDLW 0xFF                 ; C=1 if DQ=1: C=0 if DQ=0
	RRF ow_buffer, F           ; shift C into IOBYTE
	OW_WAIT .50                ; wait 50�s to end of time slot
	DECFSZ ow_bits_left, F     ; decrement the bit counter
	GOTO ow_receive_byte_loop
	MOVF ow_buffer, W
	RETURN

ow_reset_and_select
	CALL ow_reset
	MOVLW 0x55 ; select device
	CALL ow_send_byte
	MOVF ow_current_device_0, W
	CALL ow_send_byte
	MOVF ow_current_device_1, W
	CALL ow_send_byte
	MOVF ow_current_device_2, W
	CALL ow_send_byte
	MOVF ow_current_device_3, W
	CALL ow_send_byte
	MOVF ow_current_device_4, W
	CALL ow_send_byte
	MOVF ow_current_device_5, W
	CALL ow_send_byte
	MOVF ow_current_device_6, W
	CALL ow_send_byte
	MOVF ow_current_device_7, W
	CALL ow_send_byte
	RETURN

; ============================================================ thermo(meter) ==
;	1: 1013 c1f5 0108 003b
;	2: 1033 9df5 0108 0039
;	3: 1079 94f5 0108 0070
;	4: 10f7 97f5 0108 00c7

thermo_detect_one_device
	CALL ow_reset
	MOVLW 0x33 ; find one device
	CALL ow_send_byte
	CALL ow_receive_byte
	MOVWF ow_current_device_0
	CALL ow_receive_byte
	MOVWF ow_current_device_1
	CALL ow_receive_byte
	MOVWF ow_current_device_2
	CALL ow_receive_byte
	MOVWF ow_current_device_3
	CALL ow_receive_byte
	MOVWF ow_current_device_4
	CALL ow_receive_byte
	MOVWF ow_current_device_5
	CALL ow_receive_byte
	MOVWF ow_current_device_6
	CALL ow_receive_byte
	MOVWF ow_current_device_7
	RETURN

thermo_measure_begin
	CALL ow_reset_and_select
	MOVLW 0x44 ; convert T
	CALL ow_send_byte
	CALL ow_strong_pullup_begin
	RETURN

thermo_measure_end
	CALL ow_strong_pullup_end
	RETURN

thermo_read
	CALL ow_reset_and_select
	MOVLW 0xBE ; read scratchpad
	CALL ow_send_byte
	CALL ow_receive_byte ; LSB
	MOVWF thermo_in_lsb
	CALL ow_receive_byte ; MSB
	MOVWF thermo_in_msb
	CALL ow_receive_byte ; (TH register - ignore)
	CALL ow_receive_byte ; (TL register - ignore)
	CALL ow_receive_byte ; (reserved - ignore)
	CALL ow_receive_byte ; (reserved - ignore)
	CALL ow_receive_byte ; count remain
	MOVWF thermo_in_xsb
	CALL ow_receive_byte ; (count per celsius, always 0x10 - ignore)
	CALL ow_receive_byte ; (crc - ignore)

; input:
;      MSB      LSB
; 00000000 10101010 = 0x00AA =  85.0 'C
; 00000000 00110010 = 0x0032 =  25.0 'C
; 00000000 00000001 = 0x0001 =   0.5 'C
; 00000000 00000000 = 0x0000 =   0.0 'C
; 11111111 11111111 = 0xFFFF =  -0.5 'C
; 11111111 11111110 = 0xFFFE =  -1.0 'C
; 11111111 11001110 = 0xFFCE = -25.0 'C
; 11111111 10010010 = 0xFF92 = -55.0 'C
;
; output:
;   LSB[7]   positive(0) or negative (1)
;   LSB[6-0] value in Celsius (integer)
;   XSB[7-5] always 0
;   XSB[4-0] value in Celsius/32

	RRF thermo_in_lsb, F
	BTFSC STATUS,C
	BSF thermo_in_xsb, 4
	BTFSS thermo_in_msb, 0 ; if negative result
	GOTO thermo_read_1
	MOVLW 0xFF
	XORWF thermo_in_lsb, F
thermo_read_1
	RETURN

; ==================================================================== timer ==
	constant TIMER_BANK=PORTA

timer_init
	BANKSEL TIMER_BANK
	CLRF timer_time_3
	CLRF timer_time_2
	CLRF timer_time_1
	CLRF timer_time_0
	CLRF timer_interrupts
	RETURN

timer_increase_second
	BANKSEL TIMER_BANK
	INCF timer_time_3, F
	BTFSC STATUS,Z
	INCF timer_time_2, F
	BTFSC STATUS,Z
	INCF timer_time_1, F
	BTFSC STATUS,Z
	INCF timer_time_0, F
	RETURN

timer_interrupt_caught
	INCF timer_interrupts, F
	BTFSS timer_interrupts, 2 ; 4 interrupts have not been caught yet (4x250ms = 1s)
	RETURN
	CALL timer_increase_second
	CLRF timer_interrupts
	RETURN

; ================================================================ voltmeter ==
; current flowing through ports at 3.12 V: 0.0602 A
measure_init
	BANKSEL ADCON0 ; BANK0
	SETF ADCON0, b'10000001' ; FOSC/64, AN4, !GO, ADON
	BANKSEL ADCON1 ; BANK1
	SETF ADCON1, b'11001011' ; right justified, FOSC/64, 0, [D, D, A, A, V+, V-, A, A]
	BANKSEL PORTA ; BANK0
	RETURN

measure_wait
	BANKSEL ADCON0 ; BANK0
	BTFSC ADCON0, 2
	GOTO measure_wait
	RETURN

measure_an4
	BANKSEL ADCON0 ; BANK0
	MOVLW b'11000111' ; clear channel bits
	ANDWF ADCON0, F   ; ADCON0 => xx000xxx
	MOVLW b'00100000' ; set channel bits
	IORWF ADCON0, F   ; ADCON0 => xx100xxx	
	BSF ADCON0, 2     ; start conversion: set GO/!DONE bit
	CALL measure_wait
;	BANKSEL ADRESH ; BANK0
	MOVF ADRESH, W
	MOVWF an4_0
	BANKSEL ADRESL ; BANK0
	MOVF ADRESL, W
	BANKSEL PORTA ; BANK0
	MOVWF an4_1
	RETURN

; ===================================================================== main ==
WFI_MACRO:MACRO DURATION
	MOVLW DURATION
	CALL wfi_loop
	ENDM

led_off
	BANKSEL PORTD ; BANK0
	BCF PORTD, 0
	BCF PORTD, 1
	RETURN

led_red
	BANKSEL PORTD ; BANK0
	BSF PORTD, 0
	BCF PORTD, 1
	RETURN

led_green
	BANKSEL PORTD ; BANK0
	BCF PORTD, 0
	BSF PORTD, 1
	RETURN

led_yellow
	BANKSEL PORTD ; BANK0
	BSF PORTD, 0
	BSF PORTD, 1
	RETURN

init_vars
	SETF mac_dest_0, 0xF4
	SETF mac_dest_1, 0x6D
	SETF mac_dest_2, 0x04
	SETF mac_dest_3, 0xE7
	SETF mac_dest_4, 0xB2
	SETF mac_dest_5, 0x34
	SETF mac_src_0, 0xE0
	SETF mac_src_1, 0xCB 
	SETF mac_src_2, 0x4E 
	SETF mac_src_3, 0x5E   ; <<<
	SETF mac_src_4, 0x87   ; <<<
	SETF mac_src_5, 0x8E   ; <<<
	SETF mac_type_0, 0x08
	SETF mac_type_1, 0x00

	SETF ip_version_and_header_length, 0x45
	SETF ip_dummy, 0x00
	SETF ip_length_0, 0x02                   ; <<<
	SETF ip_length_1, 0x1C                   ; <<< including IP and UDP header
	SETF ip_packet_id_0, 0x00
	SETF ip_packet_id_1, 0x00
	SETF ip_flags_0, 0x40
	SETF ip_flags_1, 0x00
	SETF ip_ttl, 0x40
	SETF ip_protocol, 0x11
	SETF ip_header_checksum_0, 0xB6          ; <<<
	SETF ip_header_checksum_1, 0xAB          ; <<< recalculate when changing headers!
	SETF ip_src_0, 0xC0
	SETF ip_src_1, 0xA8
	SETF ip_src_2, 0x00
	SETF ip_src_3, 0xC9
	SETF ip_dest_0, 0xC0
	SETF ip_dest_1, 0xA8
	SETF ip_dest_2, 0x00
	SETF ip_dest_3, 0x0C

	SETF udp_src_port_0, 0x18
	SETF udp_src_port_1, 0xF7
	SETF udp_dest_port_0, 0x18
	SETF udp_dest_port_1, 0xF8
	SETF udp_length_0, 0x02    ; <<<
	SETF udp_length_1, 0x08    ; <<< including UDP header
	SETF udp_checksum_0, 0x00  ; (ignored)
	SETF udp_checksum_1, 0x00  ; (ignored)

	SETF magic, 0x65           ; "e"
	SETF eth_packet_type, 0x01 ; memory dump

	SETF version, 0x01
	SETF panic_bits, 0x00
	RETURN

;init_interrupts
;	BANKSEL PORTA ; BANK0
;
;	BSF INTCON, INTE ; RB0 interrupt
;	BSF INTCON, RBIE ; PORTB change
;	BSF INTCON, GIE
;
;	RETURN

init
	BANKSEL TRISA  ; BANK1
	SETF ADCON1, b'10001011'
	SETF TRISA, b'11111111'
	SETF TRISB, b'00000000'
	SETF TRISC, b'00010000'
	SETF TRISD, b'00000100'
	SETF TRISE, b'00000000'

	BANKSEL PORTA  ; BANK0
	SETF ADCON0, b'00000001'
	CLRF PORTA
	CLRF PORTB
	CLRF PORTC
	CLRF PORTD
	CLRF PORTE

	CALL led_red

	CALL wait_long
	
	CALL init_vars
	CALL spi_init
	CALL eth_init
	CALL timer_init
;	CALL init_interrupts

;	CALL eth_leds_on
	RETURN

select_thermo_1
	SETF ow_current_device_0, 0x10
	SETF ow_current_device_1, 0x13
	SETF ow_current_device_2, 0xC1
	SETF ow_current_device_3, 0xF5
	SETF ow_current_device_4, 0x01
	SETF ow_current_device_5, 0x08
	SETF ow_current_device_6, 0x00
	SETF ow_current_device_7, 0x3B
	RETURN

select_thermo_2
	SETF ow_current_device_0, 0x10
	SETF ow_current_device_1, 0x33
	SETF ow_current_device_2, 0x9D
	SETF ow_current_device_3, 0xF5
	SETF ow_current_device_4, 0x01
	SETF ow_current_device_5, 0x08
	SETF ow_current_device_6, 0x00
	SETF ow_current_device_7, 0x39
	RETURN

select_thermo_3
	SETF ow_current_device_0, 0x10
	SETF ow_current_device_1, 0x79
	SETF ow_current_device_2, 0x94
	SETF ow_current_device_3, 0xF5
	SETF ow_current_device_4, 0x01
	SETF ow_current_device_5, 0x08
	SETF ow_current_device_6, 0x00
	SETF ow_current_device_7, 0x70
	RETURN

select_thermo_4
	SETF ow_current_device_0, 0x10
	SETF ow_current_device_1, 0xF7
	SETF ow_current_device_2, 0x97
	SETF ow_current_device_3, 0xF5
	SETF ow_current_device_4, 0x01
	SETF ow_current_device_5, 0x08
	SETF ow_current_device_6, 0x00
	SETF ow_current_device_7, 0xC7
	RETURN

store_thermo_1
	MOVFF thermo2_value, thermo_in_lsb
	MOVFF thermo2_value_fract, thermo_in_xsb
	RETURN

store_thermo_2
	MOVFF thermo2_value, thermo_in_lsb
	MOVFF thermo2_value_fract, thermo_in_xsb
	RETURN

store_thermo_3
	MOVFF thermo3_value, thermo_in_lsb
	MOVFF thermo3_value_fract, thermo_in_xsb
	RETURN

store_thermo_4
	MOVFF thermo4_value, thermo_in_lsb
	MOVFF thermo4_value_fract, thermo_in_xsb
	RETURN

show_charge_led_0
	CALL led_green
	RETURN

show_charge_led_1
	CALL led_green
	RETURN

show_charge_led_2
	CALL led_green
	RETURN

show_charge_led_3
	CALL led_green
	RETURN

show_charge_led_4
	CALL led_yellow
	RETURN

panic
panic_loop
	BANKSEL PORTA ; BANK0
	BCF PORTD, 4
	BSF PORTD, 5
	BCF PORTD, 6
	BSF PORTD, 7
	CALL wait_long
	BSF PORTD, 4
	BCF PORTD, 5
	BSF PORTD, 6
	BCF PORTD, 7
	CALL wait_long
	GOTO panic_loop

panic_check
;	MOVLW 0xFF
;	ADDWF panic_bits, W
;	BTFSC STATUS, C
;	CALL panic
	RETURN

do_temperature_check
	MOVLW 0x1F ; 27 'C
	SUBWF thermo2_value, W
	MOVWF eee
	BCF panic_bits, 0 ; temperature
;	BTFSC STATUS, C
;	BSF panic_bits, 0 ; temperature
	RETURN

wfi_main
	RETURN

; WFI = wait for interrupt
wfi_loop
 	MOVWF wfi_loops_left

wfi_loop_1
	CALL wfi_main
	BANKSEL PORTD ; BANK0
	BTFSC PORTD, 2
	GOTO wfi_loop_1

wfi_loop_2
	CALL wfi_main
	BANKSEL PORTD ; BANK0
	BTFSS PORTD, 2
	GOTO wfi_loop_2

	CALL timer_interrupt_caught
	DECFSZ wfi_loops_left, F
	GOTO wfi_loop_1
	RETURN

main
	CALL init

	CALL wait_longer
;
;	CALL select_thermo_1
;	CALL thermo_measure_begin
;	WFI_MACRO 0x04             ; 1.00 seconds passed in total
;
;	CALL select_thermo_2
;	CALL thermo_measure_begin
;	WFI_MACRO 0x04             ; 2.00 seconds passed in total
;
;	CALL select_thermo_3
;	CALL thermo_measure_begin
;	WFI_MACRO 0x04             ; 3.00 seconds passed in total

	CALL show_charge_led_0

loop1
	CALL led_green
	CALL eth_send_packet
	WFI_MACRO 0x08

	CALL led_yellow
	CALL mem_read
	CALL eth_send_packet
	WFI_MACRO 0x08

	CALL led_red
	CALL mem_init
	CALL eth_send_packet
	WFI_MACRO 0x08


	GOTO loop1

main_loop
	WFI_MACRO 0x04             ; 1.00 seconds passed in total

	CALL select_thermo_1
	CALL thermo_measure_begin
	WFI_MACRO 0x04             ; 2.00 seconds passed in total

	CALL thermo_measure_end
	CALL thermo_read
	CALL store_thermo_1
	WFI_MACRO 0x04             ; 3.00 seconds passed in total

	CALL select_thermo_2
	CALL thermo_measure_begin
	WFI_MACRO 0x04             ; 4.00 seconds passed in total

	CALL thermo_measure_end
	CALL thermo_read
	CALL store_thermo_2
	WFI_MACRO 0x04             ; 5.00 seconds passed in total

	CALL select_thermo_3
	CALL thermo_measure_begin
	WFI_MACRO 0x04             ; 6.00 seconds passed in total

	CALL thermo_measure_end
	CALL thermo_read
	CALL store_thermo_3
	WFI_MACRO 0x02             ; 6.50 seconds passed in total

	CALL thermo_detect_one_device
	WFI_MACRO 0x02             ; 7.00 seconds passed in total

	CALL measure_an4
	WFI_MACRO 0x02             ; 7.50 seconds passed in total

	CALL do_temperature_check
	WFI_MACRO 0x02             ; 8.00 seconds passed in total


	WFI_MACRO 0x08             ; 10.00 seconds passed in total


	CALL led_off
	WFI_MACRO 0x02             ; 10.50 seconds passed in total

	CALL show_charge_led_1
	WFI_MACRO 0x01             ; 10.75 seconds passed in total

	CALL led_off
	WFI_MACRO 0x01             ; 11.00 seconds passed in total

	CALL show_charge_led_2
	WFI_MACRO 0x01             ; 11.25 seconds passed in total

	CALL led_off
	WFI_MACRO 0x01             ; 11.50 seconds passed in total

	CALL show_charge_led_3
	WFI_MACRO 0x01             ; 11.75 seconds passed in total

	CALL led_off
	WFI_MACRO 0x01             ; 12.00 seconds passed in total

	CALL show_charge_led_4
	WFI_MACRO 0x01             ; 12.25 seconds passed in total

	CALL led_off
	WFI_MACRO 0x01             ; 12.50 seconds passed in total

	CALL show_charge_led_0
	WFI_MACRO 0x01             ; 12.75 seconds passed in total


	WFI_MACRO 0x05             ; 14.00 seconds passed in total


	CALL eth_send_packet
	WFI_MACRO 0x02             ; 14.50 seconds passed in total

	CALL panic_check
	WFI_MACRO 0x02             ; 15.00 seconds passed in total

	GOTO main_loop

	END
