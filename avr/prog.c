#include <avr/io.h> 

typedef enum {
  addr0,
  addr1,
  red,
  grn,
  blu,
  ignore1,
  ignore2,
  ignore3,
  ignore4
} protocol_state;


#define ADDR0 0x00
#define ADDR1 0xEE


void hello()
{
  unsigned long int x, y, ms;
  for (x = 0; x < 10; x++) {
    for (ms = 0; ms < 400; ms++) {
      for (y = 0; y < 4200; y++) 0;
    }
    PORTB = x & 1 ? 0xff : 0x00;
  }
  PORTB = 0;
}

int main(void)
{
  unsigned long int t;
  unsigned char newport;
  unsigned long int offset;
  unsigned char in_char;
  protocol_state state = addr0;
  unsigned char bright_r = 0, bright_g = 0, bright_b = 0;
  
  DDRB = 0xFF;        // set port B to output only

  PORTB = 0; // turn off all LEDs

  hello();

  // (datasheet page 136)
  UBRRH = 0;
  //  UBRRL = 103; // 4800 baud at 8MHz
  UBRRL = 51; // 9600 at 8MHz

  UCSRB = (1 << RXEN) | (0 << TXEN);
  UCSRC = (3 << UCSZ0); // 8-bit chars

  while(1) {
    if ( UCSRA & (1<<RXC)) {
      switch(state) {
      case addr0:
	in_char = UDR;
	if (in_char != ADDR0) {
	  state = ignore1;
	} else {
	  state = addr1;
	}
	break;
      case addr1:
	in_char = UDR;
	if (in_char != ADDR1) {
	  state = ignore2;
	} else {
	  state = red;
	}
	break;
      case red:
	bright_r = UDR;
	state = grn;
	break;
      case grn:
	bright_g = UDR;
	state = blu;
	break;
      case blu:
	bright_b = UDR;
	state = addr0;
	break;

      case ignore1: in_char = UDR; state = ignore2; break;
      case ignore2: in_char = UDR; state = ignore3; break;
      case ignore3: in_char = UDR; state = ignore4; break;
      case ignore4: in_char = UDR; state = addr0;   break;
      }
    }

    t = 0;
    while (t < 256) {
      newport = 0;
      if (t < bright_r) { newport |= 1 << 0; }
      if (t < bright_g) { newport |= 1 << 1; }
      if (t < bright_b) { newport |= 1 << 2; }
      PORTB = newport;
      t++;
    }
  }

}
