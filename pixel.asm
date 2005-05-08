;File Demo.asm
;Assembly code for PIC 16F84 microcontroller.


;Blinks LEDs on PORTB outputs in a sequential pattern.
;With a 75 kHz oscillator, each LED stays on about 1/2 second.


;CPU configuration
;   PIC 16F84, oscillator, watchdog timer off, power-up timer enabled.
;   Note: two underscore characters before the config command.


       processor 16f84A
       include  <p16f84a.inc>
       __config _XT_OSC & _WDT_OFF & _PWRTE_ON
 
 
J	equ  H'1F'    
K	equ  H'1E'     
T	equ	H'20'
BRIGHT_R equ H'21' 	;  low 03
BRIGHT_G equ H'22'		; mid 30
BRIGHT_B equ H'23'		; hi ff
rcvReg	equ	0x0c	; serial input byte
count	equ	0x0d	; serial
temp	equ	0x0e	; serial
	
PIN_R	equ	0
PIN_G	equ	1
PIN_B	equ	2

 
        org   0     ;Start program at address zero.
	
        bsf 	STATUS, RP0	
        movlw	b'00000001'	; A0 is input and the rest are output
	movwf	TRISA

	
       ;Set PORTB as output and initialize it.
        bsf STATUS, RP0 	; tris bank
	movlw   B'00000000'  ;Move 8 binary zeros to the W (working) register.
	movwf TRISB		

	bcf STATUS, RP0		;  portb bank
	clrf	PORTB		; PORTB = 0

	clrf	T		; T = 0

	movlw H'FF'
	movwf BRIGHT_R

	movlw H'30'
	movwf BRIGHT_G

	movlw H'FF'
	movwf BRIGHT_B
	
	
mloop:

	call rcv4800
	movf rcvReg, w
	movwf BRIGHT_R
	
	movf	T,w		; W = T

	addwf	BRIGHT_R,W	; W = <brightness> + W
	btfss	STATUS,C	; 
	goto nored
	bsf	PORTB,PIN_R
	goto donered
nored	bcf	PORTB,PIN_R
donered
	
	addwf	BRIGHT_G,W		; W = <brightness> + W
	btfss	STATUS,C
	goto nogrn
	bsf	PORTB,PIN_G
	goto donegrn
nogrn	bcf	PORTB,PIN_G
donegrn
		
	addwf	BRIGHT_B,W		; W = <brightness> + W
	btfss	STATUS,C
	goto noblu
	bsf	PORTB,PIN_B
	goto doneblu
noblu	bcf	PORTB,PIN_B
doneblu	

	
       ;Waste some time by executing nested loops.
 
        movlw   D'2'
        movwf   J		; J = W = <sqrt(loops)>
jloop   movwf   K		; K = W
kloop   decfsz   K,f		; K = K - 1, if K:	
        goto      kloop		;               goto kloop
        decfsz   J,f		; J = J - 1, if J:	
        goto      jloop		;               goto jloop
 
	incf	T,f		; T = T + 1
	 
	goto      mloop


	
	;; --------------------------------------------------------------

rcv4800	bcf	INTCON, 5	; Disable TMR0 interrupts
	bcf	INTCON,	7	; Disable global interrupts
	clrf	TMR0		; Clear timer/counter
	clrwdt			; Clear wdt prep prescaler assign

	bsf	STATUS, RP0	; 	
	movlw	b'11011000'	; set up timer/counter
	movwf	OPTION_REG

	bcf	STATUS, RP0	; 
	movlw	0x08		; Init shift counter
	movwf	count
	
sbit	btfsc	PORTA, 0	; Look for start bit
	goto 	sbit		; For Mark
	
	movlw	0x98		; 
	movwf	TMR0		; Load and start timer/counter
	
	bcf	INTCON, 2	; Clear TMR0 overflow flag
time1	btfss	INTCON, 2	; Has the timer (bit 2) overflowed?  Skip next line if 1
	goto	time1		; No
	
	btfsc	PORTA, 0	; Start bit still low?
	goto 	sbit		; False start, go back
	movlw	0x30		; real, define N for timer
	movwf	TMR0		; start timer/counter - bit time
	bcf	INTCON, 2	; Clear TMR0 overflow flag
time2	btfss	INTCON, 2	; Timer overflow?
	goto	time2		; No
	movlw	0x30		; Yes, define N for timer
	movwf	TMR0		; Start timer/counter
	bcf	INTCON, 2;	; Clear TMR0 overflow flah
	movf	PORTA, w	; Read port A
	movwf	temp		; Store
	rrf	temp, f		; Rotate bit 0 into carry flag
	rrf	rcvReg, f	; Rotate carry into rcvReg bit 7
	decfsz	count, f	; Shifted 8?
	goto	time2		; No
time3	btfss	INTCON, 2	; Timer overflow?
	goto	time3		; No
	return			; Yes, byte received
;-----------------------------------------------------------------------




	
	end


	;; import serial; ser = serial.Serial(port="/dev/ttyS0")
	;; ser.write("\xc1")