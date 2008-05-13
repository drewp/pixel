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
#define ADDR1 0xcc


void hello()
{
  unsigned long int x, y, ms;
  for (x = 0; x < 10; x++) {
    for (ms = 0; ms < 400; ms++) {
      for (y = 0; y < 4200; y++) 0;
    }
    PORTB = 1 << (x % 3);
  }
  PORTB = 0;
}

void delay_ms10(long int ms) {
  unsigned long int timer;

  while (ms != 0) {
    // this number is dependant on the clock frequency
    for (timer=0; timer <= 420/3; timer++);
    ms--;
  }
}

void putchar(unsigned char c) {
  delay_ms10(10);
  
  while (!(UCSRA & (1<<UDRE))) {

  }
  UDR = c;
}

int main(void)
{
  unsigned long int t, y;
  unsigned char count, wait;
  unsigned char newport;
  unsigned long int offset;
  unsigned char in_char;
  unsigned char zero_run;
  protocol_state state = addr0;
  unsigned char bright_r = 12, bright_g = 0, bright_b = 0;
  
  DDRB = 0xFF;        // set port B to output only
  DDRD = 0xFC;

  PORTB = 0; // turn off all LEDs
  PORTD = 0;

  hello();
  //  PORTB = 1 << 1; // grn power light

  // (datasheet page 136)
  UBRRH = 0;
  //  UBRRL = 103; // 4800 baud at 8MHz
  UBRRL = 51; // 9600 at 8MHz

  UCSRB = (1 << RXEN) | (1 << TXEN);
  UCSRC = (3 << UCSZ0); // 8-bit chars


  putchar(1);
  putchar(2);

  PORTB = 0; // right led on

  while (1) {

    DDRB = 0xFF; // output
    PORTB = (0 << 4) | (1 << 5); // reverse
    delay_ms10(1000);

    DDRB = 0xFF & ~(1 << 5); // - is in
    PORTB = (0 << 4) | (0 << 5);

    y = 0;
    zero_run = 0;
    for (t = 0; t < 6500; t ++ ) {
      for (wait = 0; wait < 128; wait ++) {
	0;
      }
      if (PINB & (1 << 5)) {
	y++;
	zero_run = 0;
      } else {
	zero_run++;
	if (zero_run > 10) {
	  break;
	}
      }
    }

    putchar(y & 0xff);
    putchar(y >> 8);

  }

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

    //    PORTD = bright_r;


    
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
