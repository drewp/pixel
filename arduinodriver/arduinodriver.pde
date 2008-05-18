int datapin  = 10; // DI
int latchpin = 11; // LI
int enablepin = 12; // EI
int clockpin = 13; // CI

unsigned long SB_CommandPacket;
int SB_CommandMode;
int SB_BlueCommand;
int SB_RedCommand;
int SB_GreenCommand;

int vals[15];

void setCurrent(unsigned char r, unsigned char g, unsigned char b) { 
 /* 127 = max */ 
   SB_CommandMode = B01; // Write to current control registers
   SB_RedCommand = r; 
   SB_GreenCommand = g;
   SB_BlueCommand = b;
   SB_SendPacket();
   latch();
}
void SB_SendPacket() {
   SB_CommandPacket = SB_CommandMode & B11;
   SB_CommandPacket = (SB_CommandPacket << 10)  | (SB_BlueCommand & 1023);
   SB_CommandPacket = (SB_CommandPacket << 10)  | (SB_RedCommand & 1023);
   SB_CommandPacket = (SB_CommandPacket << 10)  | (SB_GreenCommand & 1023);

   shiftOut(datapin, clockpin, MSBFIRST, SB_CommandPacket >> 24);
   shiftOut(datapin, clockpin, MSBFIRST, SB_CommandPacket >> 16);
   shiftOut(datapin, clockpin, MSBFIRST, SB_CommandPacket >> 8);
   shiftOut(datapin, clockpin, MSBFIRST, SB_CommandPacket);

}
void latch() {
   delay(1); // adjustment may be necessary depending on chain length
   digitalWrite(latchpin,HIGH); // latch data into registers
   delay(1); // adjustment may be necessary depending on chain length
   digitalWrite(latchpin,LOW); 
}
void refresh() {
  /* send all pixels */
  SB_CommandMode = B00;
  for (int pixel=0; pixel < 5; pixel++) {
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

   setCurrent(127, 127, 127);
   setCurrent(127, 127, 127);
   setCurrent(127, 127, 127);
   setCurrent(127, 127, 127);
   setCurrent(127, 127, 127);

   PIXEL(0, F, 0, 0);
   PIXEL(1, 0, F, 0);
   PIXEL(2, 0, 0, F);
   PIXEL(3, F, F, 0);
   PIXEL(4, 0, F, F);
   refresh(); 
   Serial.begin(115200);
   Serial.flush();
}

int quiet = 0;
int addr = 0; // which vals element to set next

void loop() {
  int inb = Serial.read();
  if (inb != -1) {
    vals[addr] = inb * 4;
    addr ++; 
    if (addr >= 15) {
      refresh(); 
  
      addr = 0;
    }
  } else {
    delay(1);
    quiet += 1;
    if (quiet > 1000) {
      addr = 0;
    }
  }
  
}
