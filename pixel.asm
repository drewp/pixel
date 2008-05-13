
;;;  serial code adapted from code with this header
; FILE: rcv1_1.asm
; AUTH: P.Oh
; DATE: 04/27/02 18:00 1.0 - WORKS
;	04/27/02 18:35 1.1
; DESC: 1.0: PC-to-PIC serial communications.  LEDs display binary equivalent
;            of key typed on PC
;       1.1: Same as 1.0 but eliminates need for switch
; REFS: rcv4800.asm in PIC'n Techniques p. 219

	
       processor 10f200
       include  <p10f200.inc>
       __config _WDT_OFF & _CP_OFF & _MCLRE_OFF

	
rcvReg	equ	0x10	; serial input byte
getch_fail equ	0x11	; serial read failed
count	equ	0x12	; serial
temp	equ	0x13	; serial

addr_hi	equ	0x14
addr_lo equ	0x15

T	equ	H'16'		; pwm counter
BRIGHT_R equ	H'17'		;  low 03
BRIGHT_G equ	H'18'		; mid 30
BRIGHT_B equ	H'19'		; hi ff
	
PIN_R	equ	0		; output bits, on GPIO
PIN_G	equ	1
PIN_B	equ	2
	                        ;; GPIO[3] is the serial input

 
        org   0     ;Start program at address zero.
	
	movlw	b'11011000'	; set up timer/counter:	
	; no PORTB pullup
	; int on rising edge
	; TMR0 uses internal instruction cycle clock
	; tmr falling edge
	; NO prescale on tmr 
	; 1:2 tmr prescale (unused)
	option
	
	;; pwm setup
	clrf	T		; T = 0

	movlw H'30'
	movwf BRIGHT_R

	movlw H'30'
	movwf BRIGHT_G

	movlw H'30'
	movwf BRIGHT_B

	;; serial setup
	movlw	0x00
	movwf	addr_hi

	movlw	0xee
	movwf	addr_lo
	
	clrf	TMR0		; Clear timer/counter
	clrwdt			; Clear wdt prep prescaler assign


		
main

	
sbit0	call pwmstep
	btfsc	GPIO, 3	; Look for start bit
	goto 	sbit0		; For Mark

	call getch

	movf rcvReg, w
	subwf addr_hi,w		; if addr_hi - rcvReg != 0:
	btfss STATUS, Z
	goto main		;   goto main

sbit1	call pwmstep
	btfsc GPIO, 3		; wait for start bit
	goto sbit1

	call getch

	movf rcvReg, w
	subwf addr_lo,w		; if addr_lo - rcvReg != 0:	
	btfss STATUS, Z
	goto main		;   goto main
	

sbit2	call pwmstep
	btfsc GPIO, 3		
	goto sbit2
	call getch	
	movf rcvReg, w
	movwf BRIGHT_R		; BRIGHT_R = getch()

sbit3	call pwmstep
	btfsc GPIO, 3		
	goto sbit3
	call getch	
	movf rcvReg, w
	movwf BRIGHT_G		; BRIGHT_G = getch()

sbit4	call pwmstep
	btfsc GPIO, 3		
	goto sbit4
	call getch	
	movf rcvReg, w
	movwf BRIGHT_B		; BRIGHT_B = getch()

	goto main
;-----------------------------------------------------------------------
	;; get serial char, save in rcvReg, getch_fail is set if there was err
getch	
	movlw	0x08		; count = 8
	movwf	count
	
	movlw	0x98		; 
	movwf	TMR0		; TMR0 = 304us
	
	bcf	INTCON, T0IF	; Clear TMR0 overflow flag
time1	btfss	INTCON, T0IF	; Has the timer (bit 2) overflowed?  Skip next line if 1
	goto	time1		; No
	
	btfss	GPIO, 3	; if PORTA[0] == 0:	
	goto contin
	movlw   0x01
	movwf   getch_fail      ;   getch_fail = 1
	return			;   return
contin
	
	movlw	0x30		; 
	movwf	TMR0		; TMR0 = 96us
	bcf	INTCON, T0IF	; Clear TMR0 overflow flag
time2	btfss	INTCON, T0IF	; Timer overflow?
	goto	time2		; No
	
	movlw	0x30		; 
	movwf	TMR0		; TMR0 = 96us
	bcf	INTCON, T0IF;	; Clear TMR0 overflow flag
	movf	PORTA, w	; Read port A
	movwf	temp		; Store
	rrf	temp, f		; Rotate bit 0 into carry flag
	rrf	rcvReg, f	; Rotate carry into rcvReg bit 7
	decfsz	count, f	; Shifted 8?
	goto	time2		; No
	
time3	btfss	INTCON, T0IF	; Timer overflow?
	goto	time3		; No

	clrf	getch_fail	; getch_fail = 0
	return
	
;-----------------------------------------------------------------------
	;; update LEDs based on T, incr T
pwmstep
	movf	T,w		; W = T

	addwf	BRIGHT_R,W	; W = <brightness> + W
	btfss	STATUS,C	; PORTB[PIN_R] = Carry
	goto nored
	bsf	PORTB,PIN_R
	goto donered
nored	bcf	PORTB,PIN_R
donered
	
	movf	T,w		; W = T
	addwf	BRIGHT_G,W	; W = <brightness> + W
	btfss	STATUS,C	; PORTB[PIN_G] = Carry
	goto nogrn
	bsf	PORTB,PIN_G
	goto donegrn
nogrn	bcf	PORTB,PIN_G
donegrn
		
	movf	T,w		; W = T
	addwf	BRIGHT_B,W	; W = <brightness> + W
	btfss	STATUS,C	; PORTB[PIN_B] = Carry
	goto noblu
	bsf	PORTB,PIN_B
	goto doneblu
noblu	bcf	PORTB,PIN_B
doneblu	
	incf	T,f		; T = T + 1
	return


	
	end

