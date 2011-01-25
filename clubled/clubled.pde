// GE Christmas light control for Arduino  
 // Ported by Scott Harris <scottrharris@gmail.com>  
 // scottrharris.blogspot.com  
   
 // Based on this code:  
   
 /*!     Christmas Light Control  
 **     By Robert Quattlebaum <darco@deepdarc.com>  
 **     Released November 27th, 2010  
 **  
 **     For more information,  
 **     see <http://www.deepdarc.com/2010/11/27/hacking-christmas-lights/>.
 **  
 **     Originally intended for the ATTiny13, but should  
 **     be easily portable to other microcontrollers.  
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
   
 void xmas_begin(uint8_t pin)  
 {  
  digitalWrite(pin,1);  
  delayMicroseconds(7); //The pulse should be 10 uS long, but I had to hand tune the delays. They work for me  
  digitalWrite(pin,0);   
 }  
   
 void xmas_one(uint8_t pin)  
 {  
  digitalWrite(pin,0);  
  delayMicroseconds(11); //This results in a 20 uS long low  
  digitalWrite(pin,1);  
  delayMicroseconds(7);   
  digitalWrite(pin,0);  
 }  
   
 void xmas_zero(uint8_t pin)  
 {  
  digitalWrite(pin,0);  
  delayMicroseconds(2);   
  digitalWrite(pin,1);  
  delayMicroseconds(20-3);   
  digitalWrite(pin,0);  
 }  
   
 void xmas_end(uint8_t pin)  
 {  
  digitalWrite(pin,0);  
  delayMicroseconds(40); // Can be made shorter  
 }  
   
   
 // The rest of Robert's code is basically unchanged  
   
void xmas_fill_color(uint8_t pin, uint8_t begin,uint8_t count,uint8_t intensity,xmas_color_t color)  
 {  
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
   
   
   
 void setup()  
 {  
  pinMode(PIN_F0, OUTPUT);  
  pinMode(PIN_F1, OUTPUT);  
  pinMode(STATUSPIN, OUTPUT);  
  xmas_fill_color(PIN_F0, 0,XMAS_LIGHT_COUNT,XMAS_DEFAULT_INTENSITY,XMAS_COLOR_BLACK); //Enumerate all the lights  
  xmas_fill_color(PIN_F1, 0,XMAS_LIGHT_COUNT,XMAS_DEFAULT_INTENSITY,XMAS_COLOR_BLACK); //Enumerate all the lights  

  xmas_fill_color(PIN_F0, 0,XMAS_LIGHT_COUNT,XMAS_DEFAULT_INTENSITY,XMAS_COLOR_BLUE);
  xmas_fill_color(PIN_F1, 0,XMAS_LIGHT_COUNT,XMAS_DEFAULT_INTENSITY,XMAS_COLOR_RED);
 }  
 
   
 void loop()  
 {  
  digitalWrite(STATUSPIN,1);  
  xmas_fill_color(PIN_F0, 0,XMAS_LIGHT_COUNT,XMAS_DEFAULT_INTENSITY,XMAS_COLOR_RED);  
  delay(100);  
  digitalWrite(STATUSPIN,0);  
  xmas_fill_color(PIN_F0, 0,XMAS_LIGHT_COUNT,XMAS_DEFAULT_INTENSITY,XMAS_COLOR_BLUE);  
  delay(100);  
 }   
   
