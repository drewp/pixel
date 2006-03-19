#include <avr/io.h> 

int main(void)
{
  unsigned long int t;
  unsigned char newport;
  unsigned long int offset;
  unsigned char in_char;
  DDRB = 0xFF;        // set port B to output only

  PORTB = 0; // turn off all LEDs

  // (datasheet page 136)
  UBRRH = 0;
  UBRRL = 103; // 4800 baud at 8MHz

  UCSRB = (1 << RXEN) | (0 << TXEN);
  UCSRC = (3 << UCSZ0); // 8-bit chars

  while(1) {
    if ( UCSRA & (1<<RXC)) {
      in_char = UDR;
    }

    t = 0;
    while (t < 256) {
      newport = 0;
      if (t > 1) { 	newport |= 1 << 0;      }
      if (t > 2) { 	newport |= 1 << 1;      }
      if (t > 4) { 	newport |= 1 << 2;      }
      if (t > 210) { 	newport |= 1 << 3;      }
      if (t > 251) { 	newport |= 1 << 4;      }
      if (t > 252) { 	newport |= 1 << 5;      }
      if (t > 253) { 	newport |= 1 << 6;      }
      if (t > in_char) { 	newport |= 1 << 7;      }

      PORTB = newport;
      t++;
    }
  }

}
