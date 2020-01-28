#ifndef F_CPU
#define F_CPU 8000000UL // 8 MHz clock speed
#endif

#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

#define BAUD 9600
#define MYUBRR F_CPU/16/BAUD-1

void USART_Init(unsigned int ubrr)
{
	/* Set baud rate */
	UBRR0H = (unsigned char) (ubrr >> 8);
	UBRR0L = (unsigned char) ubrr;
	
	/* Enable receiver and transmitter */
	UCSR0B = (1 << RXEN0) | (1 << TXEN0);
	
	/* Set frame format: 8data, 2stop bit */
	UCSR0C = (1 << USBS0) | (3 << UCSZ00);
}

void USART_Transmit(unsigned char data)
{
	/* Wait for empty transmit buffer */
	while (!(UCSR0A & (1<<UDRE0)));
	
	/* Put data into buffer, sends the data */
	UDR0 = data;
}

void USART_TransmitString(unsigned char a[])
{
	unsigned char i;
	
	for (i=0; a[i] != '\0'; i++)
	{
		USART_Transmit(a[i]);
	}
}

void main(void)
{
	unsigned char s[40];
	unsigned char a;
	
	USART_Init(MYUBRR);
	
	a = 0;
	
	while (1)
	{
		USART_TransmitString("Hello!\r\n");
		
		sprintf(s, "a = %02x\r\n", a);
		USART_TransmitString(s);
		
		a++;
		
		_delay_ms(500);
	}
}
