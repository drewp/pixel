
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

	movlw b'00001000'	; GP0,GP1,GP2 output; GP3 input
	tris 6

	
	;; pwm setup
	clrf	T		; T = 0

	movlw H'30'
	movwf BRIGHT_R

	movlw H'30'
	movwf BRIGHT_G

	movlw H'30'
	movwf BRIGHT_B

	clrf	TMR0		; Clear timer/counter
	clrwdt			; Clear wdt prep prescaler assign

	movlw b'00000111'
	movf GPIO,w

	
;-----------------------------------------------------------------------
	;; update LEDs based on T, incr T
; pwmstep
; 	movf	T,w		; W = T

; 	addwf	BRIGHT_R,W	; W = <brightness> + W
; 	btfss	STATUS,C	; PORTB[PIN_R] = Carry
; 	goto nored
; 	bsf	PORTB,PIN_R
; 	goto donered
; nored	bcf	PORTB,PIN_R
; donered
	
; 	movf	T,w		; W = T
; 	addwf	BRIGHT_G,W	; W = <brightness> + W
; 	btfss	STATUS,C	; PORTB[PIN_G] = Carry
; 	goto nogrn
; 	bsf	PORTB,PIN_G
; 	goto donegrn
; nogrn	bcf	PORTB,PIN_G
; donegrn
		
; 	movf	T,w		; W = T
; 	addwf	BRIGHT_B,W	; W = <brightness> + W
; 	btfss	STATUS,C	; PORTB[PIN_B] = Carry
; 	goto noblu
; 	bsf	PORTB,PIN_B
; 	goto doneblu
; noblu	bcf	PORTB,PIN_B
; doneblu	
; 	incf	T,f		; T = T + 1
; 	goto pwmstep

	
	end

