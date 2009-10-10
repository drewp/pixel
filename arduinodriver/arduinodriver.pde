int datapin  = 10; // DI
int latchpin = 11; // LI
int enablepin = 12; // EI
int clockpin = 13; // CI

unsigned long SB_CommandPacket;
int SB_CommandMode;
int SB_BlueCommand;
int SB_RedCommand;
int SB_GreenCommand;

#define MAXCHANS 16
int vals[MAXCHANS * 3];

int addr = 0; // which vals element to set next
int currentChans = MAXCHANS;


void setCurrent(unsigned char r, unsigned char g, unsigned char b) { 
 /* 127 = max */ 
   SB_CommandMode = B01; // Write to current control registers
   SB_RedCommand = r; 
   SB_GreenCommand = g;
   SB_BlueCommand = b;
   SB_SendPacket();
   latch();
}

void shiftOutLocal(uint8_t dataPin, uint8_t clockPin, byte val)
{
  int i;
  
  for (i = 0; i < 8; i++)  {
    digitalWrite(dataPin, !!(val & (1 << (7 - i))));
    
    digitalWrite(clockPin, HIGH);
    digitalWrite(clockPin, LOW);            
  }
}

void SB_SendPacket() {
   SB_CommandPacket = SB_CommandMode & B11;
   SB_CommandPacket = (SB_CommandPacket << 10)  | (SB_BlueCommand & 1023);
   SB_CommandPacket = (SB_CommandPacket << 10)  | (SB_RedCommand & 1023);
   SB_CommandPacket = (SB_CommandPacket << 10)  | (SB_GreenCommand & 1023);

   shiftOutLocal(datapin, clockpin, SB_CommandPacket >> 24);
   shiftOutLocal(datapin, clockpin, SB_CommandPacket >> 16);
   shiftOutLocal(datapin, clockpin, SB_CommandPacket >> 8);
   shiftOutLocal(datapin, clockpin, SB_CommandPacket);

}
void latch() {
   delayMicroseconds(100);
   digitalWrite(latchpin,HIGH); // latch data into registers
   delayMicroseconds(100);
   digitalWrite(latchpin,LOW); 
}
void refresh() {
  /* send all pixels */
  SB_CommandMode = B00;
  for (int pixel=0; pixel < currentChans; pixel++) {
    SB_RedCommand = vals[pixel * 3 + 0];
    SB_GreenCommand = vals[pixel * 3 + 1];
    SB_BlueCommand = vals[pixel * 3 + 2];
    SB_SendPacket();
  } 
  latch();
}
#define F 1023
#define PIXEL(i, r, g, b) { vals[i*3+0] = r; vals[i*3+1] = g; vals[i*3+2] = b; }

void setup() {
   pinMode(datapin, OUTPUT);
   pinMode(latchpin, OUTPUT);
   pinMode(enablepin, OUTPUT);
   pinMode(clockpin, OUTPUT);

   digitalWrite(latchpin, LOW);
   digitalWrite(enablepin, LOW);

   for (int i=0; i < MAXCHANS; i++) {
     setCurrent(127, 127, 127);
   }

   PIXEL(0, F, 0, 0);
   PIXEL(1, 0, F, 0);
   PIXEL(2, 0, 0, F);
   PIXEL(3, F, F, 0);
   PIXEL(4, 0, F, F);
   refresh(); 

   Serial.begin(9600);
   Serial.flush();
}


void loop() {
  /*
    send 0xff, 
    then a byte for the number of channels you're going to send,
    then nchans*3 bytes of r-g-b levels from 0x00-0xfe.
   */
  int inb = Serial.read();
  if (inb == -1) {
    return;
  }

  if (inb == 0xff) {
    addr = -1;
    return;
  }
  if (addr == -1) {
    currentChans = inb;
    addr = 0;
    return; 
  }
  
  vals[addr] = inb * 4; // SB levels are 10-bit. log scale might be better
  addr ++; 
  if (addr >= currentChans * 3) {
    refresh();  
    addr = 0;
  }
  
}
