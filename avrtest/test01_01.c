#define F_CPU 960000UL
#include <avr/io.h>

volatile int16_t d;

int main()
{
	int16_t a, b, c;
	
	for (a=1; a<255; a++)
	{
		for (b=1; b<255; b++)
		{
			c = (a - b) * 0.1;
			d = c;
		}
	}
	
	return 0;
}
