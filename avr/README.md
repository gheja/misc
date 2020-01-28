# AVR USART test

Testing USART output (no input) serial communication from an AVR microcontroller, using only one I/O pin (marked `TXD` in the datasheet) and GND.

Baud rate is set in `BAUD` to 9600 bps.

The code sets the `USART0` port and based on the documentation of ATmega328P.

I used it with a simple USB-to-TTL converter and minicom on my PC.

For the correct pin to use see the datasheet of your microcontroller.

## Files

### serial1.c

Simple character output. With AVR-GCC it compiled to 220 bytes.

### serial2.c

With string support. With AVR-GCC it compiled to 274 bytes.

### serial3.c

With string and `sprintf()` support. With AVR-GCC it compiled to 1798 bytes.

### build.sh

The script i used to build the .c file to .o and .hex, then program the microcontroller.
