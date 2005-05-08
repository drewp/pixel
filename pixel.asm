
;;;  serial code adapted from code with this header
; FILE: rcv1_1.asm
; AUTH: P.Oh
; DATE: 04/27/02 18:00 1.0 - WORKS
;	04/27/02 18:35 1.1
; DESC: 1.0: PC-to-PIC serial communications.  LEDs display binary equivalent
;            of key typed on PC
;       1.1: Same as 1.0 but eliminates need for switch
; REFS: rcv4800.asm in PIC'n Techniques p. 219

	
       processor 16f84A
       include  <p16f84a.inc>
       __config _XT_OSC & _WDT_OFF & _PWRTE_ON

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
	
	
	;; hardware setup
        bsf 	STATUS, RP0	
        movlw	b'00000001'	; A0 is input and the rest are output
	movwf	TRISA

        bsf STATUS, RP0 	; tris bank
	movlw   B'00000000'  ; PORTB to output
	movwf TRISB		

	bcf STATUS, RP0		;  portb bank
	clrf	PORTB		; PORTB = 0

	;; pwm setup
	clrf	T		; T = 0

	movlw H'00'
	movwf BRIGHT_R

	movlw H'30'
	movwf BRIGHT_G

	movlw H'FF'
	movwf BRIGHT_B

	;; serial setup
	bcf	INTCON, 5	; Disable TMR0 interrupts
	bcf	INTCON,	7	; Disable global interrupts
	clrf	TMR0		; Clear timer/counter
	clrwdt			; Clear wdt prep prescaler assign

	bsf	STATUS, RP0	; 	
	movlw	b'11011000'	; set up timer/counter
	movwf	OPTION_REG

		
main
	bcf	STATUS, RP0	; 
	movlw	0x08		; count = 8
	movwf	count
	
sbit	call pwmstep
	btfsc	PORTA, 0	; Look for start bit
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



	movf rcvReg, w
	movwf BRIGHT_R
	movwf BRIGHT_B
	movwf BRIGHT_G
	comf BRIGHT_G,f

	
	goto main
	
;-----------------------------------------------------------------------


pwmstep
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
	incf	T,f		; T = T + 1
	return


	
	end


	;; import serial; ser = serial.Serial(port="/dev/ttyS0")
	;; ser.write("\xc1")