/*
 GE Christmas light control for Arduino/teensy

 Adjusted for multiple strings attached to teensy by
 Drew Perttula <drewp@bigasterisk.com> 2011-01.

 Ported by Scott Harris <scottrharris@gmail.com>  
 scottrharris.blogspot.com  
   
 Based on this code:  
   
     Christmas Light Control  
     By Robert Quattlebaum <darco@deepdarc.com>  
     Released November 27th, 2010  
  
     For more information,  
     see <http://www.deepdarc.com/2010/11/27/hacking-christmas-lights/>.
  
     Originally intended for the ATTiny13, but should  
     be easily portable to other microcontrollers.  
  
 */

/*
USB Serial protocol:

Messages start with 601ED5 ("go LEDS!"). There are two kinds of
requests: asking for all the LEDs on a string to be addressed (which
they need once after they power on), and submitting some color change
messages.

At startup, we send addresses to pin 21 (F0) and 20 (F1), run a test
pattern on both of those, and quickly blink the status LED. Upon your
first incoming bytes, the test pattern and blinking stops and we go
into command mode.

In command mode, the status LED turns on at the start of an incoming
command and off at the end. After a message is understood, we send
back 'ok' (2 chars, no newline) over serial.

Assign command-- Assign sequential addresses to all the LEDs on a string
  601ED5      21      0                      50
  header{24}  pin{8}  0 = do addressing{8}   # leds in string{8}

Set colors command-- Set some colors on a string
  601ED5      21      3         [ 3        204           1234      ]     [...]
  header{24}  pin{8}  count{8}    addr{8}  intensity{8}  color{16}

The longest message is 3+1+1+4*50 = 205 bytes, so you have to send
more than that to reset.

Todo: if the teensy is going to be on before the strings turn on, we
ought to *sense their power* on some IO pins and handle the enumeration
quickly and automatically.

Todo: collect multiple string commands and run them in parallel

 */
#define xmas_color_t uint16_t // typedefs can cause trouble in the Arduino environment  
   
#define XMAS_LIGHT_COUNT          (50) //I only have a 36 light strand. Should be 50 or 36  
#define XMAS_CHANNEL_MAX          (0xF)  
#define XMAS_DEFAULT_INTENSITY     (0xCC)  
#define XMAS_HUE_MAX               ((XMAS_CHANNEL_MAX+1)*6-1)  
#define XMAS_COLOR(r,g,b)     ((r)+((g)<<4)+((b)<<8))  
#define XMAS_COLOR_WHITE     XMAS_COLOR(XMAS_CHANNEL_MAX,XMAS_CHANNEL_MAX,XMAS_CHANNEL_MAX)  
#define XMAS_COLOR_BLACK     XMAS_COLOR(0,0,0)  
#define XMAS_COLOR_RED          XMAS_COLOR(XMAS_CHANNEL_MAX,0,0)  
#define XMAS_COLOR_GREEN     XMAS_COLOR(0,XMAS_CHANNEL_MAX,0)  
#define XMAS_COLOR_BLUE          XMAS_COLOR(0,0,XMAS_CHANNEL_MAX)  
#define XMAS_COLOR_CYAN          XMAS_COLOR(0,XMAS_CHANNEL_MAX,XMAS_CHANNEL_MAX)  
#define XMAS_COLOR_MAGENTA     XMAS_COLOR(XMAS_CHANNEL_MAX,0,XMAS_CHANNEL_MAX)  
#define XMAS_COLOR_YELLOW     XMAS_COLOR(XMAS_CHANNEL_MAX,XMAS_CHANNEL_MAX,0)  

#define STATUSPIN PIN_D6 // The LED  
   
// The delays in the begin, one, and zero functions look funny, but they give the correct  
// pulse durations when checked with a logic analyzer. Tested on an Arduino Uno.  
   
void xmas_begin(uint8_t pin) {  
  digitalWrite(pin,1);  
  delayMicroseconds(12+1); // from 10
  digitalWrite(pin,0);   
}  
   
void xmas_one(uint8_t pin) {  
  digitalWrite(pin,0);  
  delayMicroseconds(25); //This results in a 20 uS long low  
  digitalWrite(pin,1);  
  delayMicroseconds(13);   
  digitalWrite(pin,0);  
}  
   
void xmas_zero(uint8_t pin) {  
  digitalWrite(pin,0);  
  delayMicroseconds(10);   
  digitalWrite(pin,1);  
  delayMicroseconds(25);   
  digitalWrite(pin,0);  
}  
   
void xmas_end(uint8_t pin) {  
  digitalWrite(pin,0);  
  delayMicroseconds(40); // Can be made shorter  
}  
   
void xmas_fill_color(uint8_t pin, uint8_t begin,uint8_t count,uint8_t intensity,xmas_color_t color) {  
  while(count--)  
    {  
      xmas_set_color(pin, begin++,intensity,color);  
    }  
}  
   
void xmas_set_color(uint8_t pin, uint8_t led,uint8_t intensity,xmas_color_t color) {  
  uint8_t i;  
  xmas_begin(pin);  
  for(i=6;i;i--,(led<<=1))  
    if(led&(1<<5))  
      xmas_one(pin);  
    else  
      xmas_zero(pin);  
  for(i=8;i;i--,(intensity<<=1))  
    if(intensity&(1<<7))  
      xmas_one(pin);  
    else  
      xmas_zero(pin);  
  for(i=12;i;i--,(color<<=1))  
    if(color&(1<<11))  
      xmas_one(pin);  
    else  
      xmas_zero(pin);  
  xmas_end(pin);  
}  
   
xmas_color_t  
xmas_color(uint8_t r,uint8_t g,uint8_t b) {  
  return XMAS_COLOR(r,g,b);  
}  
   
xmas_color_t  
xmas_color_hue(uint8_t h) {  
  switch(h>>4) {  
  case 0:     h-=0; return xmas_color(h,XMAS_CHANNEL_MAX,0);  
  case 1:     h-=16; return xmas_color(XMAS_CHANNEL_MAX,(XMAS_CHANNEL_MAX-h),0);  
  case 2:     h-=32; return xmas_color(XMAS_CHANNEL_MAX,0,h);  
  case 3:     h-=48; return xmas_color((XMAS_CHANNEL_MAX-h),0,XMAS_CHANNEL_MAX);  
  case 4:     h-=64; return xmas_color(0,h,XMAS_CHANNEL_MAX);  
  case 5:     h-=80; return xmas_color(0,XMAS_CHANNEL_MAX,(XMAS_CHANNEL_MAX-h));  
  }  
}  
   
void setup() {  
  Serial.begin(9600);

  pinMode(PIN_F0, OUTPUT);  
  pinMode(PIN_F1, OUTPUT);  

  pinMode(STATUSPIN, OUTPUT);  

  doAssignCommand(PIN_F1, 50);
  delay(10);
  doAssignCommand(PIN_F0, 50);
  delay(10);

  xmas_fill_color(PIN_F1, 0,XMAS_LIGHT_COUNT,XMAS_DEFAULT_INTENSITY,XMAS_COLOR_RED);
  xmas_fill_color(PIN_F0, 0,XMAS_LIGHT_COUNT,XMAS_DEFAULT_INTENSITY,XMAS_COLOR_BLUE);
  digitalWrite(STATUSPIN, 1);  
  delay(500);
  digitalWrite(STATUSPIN, 0);  

  int i;
  int t;
  while (1) {
    t++;
    for (i=0; i<50; i++) {
      xmas_set_color(PIN_F0, i, i*2, xmas_color_hue((t/2)%XMAS_HUE_MAX));
      xmas_set_color(PIN_F1, i, i*2, xmas_color_hue((t/2+120)%XMAS_HUE_MAX));
    }
    delay(20);
    digitalWrite(STATUSPIN, t % 2);
    if (Serial.available()) {
      break;
    }
  }
}  

void doAssignCommand(uint8_t pin, uint8_t numLeds) {
  xmas_fill_color(pin, 0, numLeds, XMAS_DEFAULT_INTENSITY, XMAS_COLOR_BLACK);
}

void doSetColorsCommand(uint8_t pin, uint8_t count, uint8_t *buf) {
  /*
    buf is 'count' color settings, each of which is 
      1 byte of address
      1 byte of intensity
      2 bytes of color
   */
  for (int i=0; i < count; i++) {
    xmas_set_color(pin, buf[0], buf[1], buf[2] << 8 | buf[3]);
    buf += 4;
  }  

}   
#define debugSerial(msg)
//#define debugSerial(msg) Serial.print(msg)
 
void loop() {  
  uint8_t cmd[210];
  uint8_t pos=0, byte, pin, count;
  
  while (1) {
    while (!Serial.available()) NULL;
    digitalWrite(STATUSPIN, 1);
    byte = Serial.read();
    switch (pos) {
    case 0:
      if (byte == 0x60) { pos ++; } else { return; }
      break;
    case 1:    
      if (byte == 0x1E) { pos ++; } else { debugSerial("err1"); return; }
      break;
    case 2:
      if (byte == 0xD5) { pos ++; } else { debugSerial("err2"); return; }
      break;
    case 3:
	pin = byte;
	pos ++;
	debugSerial("P");
      break;
    case 4:
      count = byte;
      pos ++;
      debugSerial("C");
      debugSerial(count);
      break;
    case 209:
      /* reset */
      return;
    default:
      cmd[pos] = byte;
      pos++;
      debugSerial(".");
      if (count == 0) {
	if (pos > 5) {
	  digitalWrite(STATUSPIN, 0);
	  Serial.print("ok");
	  doAssignCommand(pin, cmd[5]);
	  return;
	}
	debugSerial("a");
      } else {
	if (pos >= (5 + count * 4)) {
	  digitalWrite(STATUSPIN, 0);
	  Serial.print("ok");
	  doSetColorsCommand(pin, count, cmd + 6);
	  return;
	}
	debugSerial("s");
	debugSerial(pos);
	debugSerial(count);
      }
    }  
  }
} 
 
