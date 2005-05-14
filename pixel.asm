
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


	
rcvReg	equ	0x0c	; serial input byte
getch_fail equ	0x0d	; serial read failed
count	equ	0x0e	; serial
temp	equ	0x0f	; serial

addr_hi	equ	0x10
addr_lo equ	0x11

T	equ	H'20'		; pwm counter
BRIGHT_R equ	H'21'		;  low 03
BRIGHT_G equ	H'22'		; mid 30
BRIGHT_B equ	H'23'		; hi ff
	
PIN_R	equ	0		; output pins, on PORTB
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
	
	bcf	INTCON, 5	; Disable TMR0 interrupts
	bcf	INTCON,	7	; Disable global interrupts
	clrf	TMR0		; Clear timer/counter
	clrwdt			; Clear wdt prep prescaler assign

	bsf	STATUS, RP0	; 	
	movlw	b'11011000'	; set up timer/counter
	movwf	OPTION_REG

		
main
	bcf	STATUS, RP0
	
sbit0	call pwmstep
	btfsc	PORTA, 0	; Look for start bit
	goto 	sbit0		; For Mark

	call getch

	movf rcvReg, w
	subwf addr_hi,w		; if addr_hi - rcvReg != 0:
	btfss STATUS, Z
	goto main		;   goto main

sbit1	call pwmstep
	btfsc PORTA, 0		; wait for start bit
	goto sbit1

	call getch

	movf rcvReg, w
	subwf addr_lo,w		; if addr_lo - rcvReg != 0:	
	btfss STATUS, Z
	goto main		;   goto main
	

sbit2	call pwmstep
	btfsc PORTA, 0		
	goto sbit2
	call getch	
	movf rcvReg, w
	movwf BRIGHT_R		; BRIGHT_R = getch()

sbit3	call pwmstep
	btfsc PORTA, 0		
	goto sbit3
	call getch	
	movf rcvReg, w
	movwf BRIGHT_G		; BRIGHT_G = getch()

sbit4	call pwmstep
	btfsc PORTA, 0		
	goto sbit4
	call getch	
	movf rcvReg, w
	movwf BRIGHT_B		; BRIGHT_B = getch()

	goto main
;-----------------------------------------------------------------------
	;; get serial char, save in rcvReg, getch_fail is set if there was err
getch	
	bcf	STATUS, RP0	; 
	movlw	0x08		; count = 8
	movwf	count
	
	movlw	0x98		; 
	movwf	TMR0		; Load and start timer/counter
	
	bcf	INTCON, 2	; Clear TMR0 overflow flag
time1	btfss	INTCON, 2	; Has the timer (bit 2) overflowed?  Skip next line if 1
	goto	time1		; No
	
	btfss	PORTA, 0	; if PORTA[0] == 0:	
	goto contin
	movlw   0x01
	movwf   getch_fail      ;   getch_fail = 1
	return			;   return
contin
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

	clrf	getch_fail	; getch_fail = 0
	return
	
;-----------------------------------------------------------------------
	;; update LEDs based on T, incr T
pwmstep
	bcf	STATUS, RP0
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

