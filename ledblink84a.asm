;
; Generated by pyastra 0.0.5-prerelease
; infile: led_blink.py
;

	processor	16f84a
	#include	p16f84a.inc

_lshift_left	equ	0xc	;bank 0
_lshift_right	equ	0xd	;bank 0
_rshift_left	equ	0xe	;bank 0
_rshift_right	equ	0xf	;bank 0
_mul_left	equ	0x10	;bank 0
_mul_right	equ	0x11	;bank 0
mul_res	equ	0x12	;bank 0
mul_cntr	equ	0x13	;bank 0
_div_left	equ	0x14	;bank 0
_div_right	equ	0x15	;bank 0
div_buf	equ	0x16	;bank 0
div_cntr	equ	0x17	;bank 0
div_res	equ	0x18	;bank 0
_mod_left	equ	0x19	;bank 0
_mod_right	equ	0x1a	;bank 0
mod_buf	equ	0x1b	;bank 0
mod_cntr	equ	0x1c	;bank 0
_pow_left	equ	0x1d	;bank 0
_pow_right	equ	0x1e	;bank 0
pow_res	equ	0x1f	;bank 0
pow_buf	equ	0x20	;bank 0
pow_cntr	equ	0x21	;bank 0
var_test	equ	0x22	;bank 0
_i	equ	0x23	;bank 0
stack0	equ	0x24	;bank 0
stack1	equ	0x25	;bank 0

	errorlevel	-302
	errorlevel	-306

	org	0x0

	goto	main

	org	0x5
main

label0
	movlw	0x1
	bcf	STATUS,	RP0
	bcf	STATUS,	RP1
	movwf	var_test
	movf	var_test,	f
	btfsc	STATUS,	Z
	goto	label1

	bsf	PORTA,	0
	clrf	_i
	movlw	0xff
	movwf	stack0

label2
	bcf	STATUS,	RP0
	bcf	STATUS,	RP1
	movf	stack0,	w
	subwf	_i,	w
	btfsc	STATUS,	Z
	goto	label3
	btfsc	STATUS,	C
	goto	label3

label4
	bcf	STATUS,	RP0
	bcf	STATUS,	RP1
	incf	_i,	f
	goto	label2

label3
	bcf	STATUS,	RP0
	bcf	STATUS,	RP1
	bcf	PORTA,	0
	clrf	_i
	movlw	0xff
	movwf	stack1

label5
	bcf	STATUS,	RP0
	bcf	STATUS,	RP1
	movf	stack1,	w
	subwf	_i,	w
	btfsc	STATUS,	Z
	goto	label6
	btfsc	STATUS,	C
	goto	label6

label7
	bcf	STATUS,	RP0
	bcf	STATUS,	RP1
	incf	_i,	f
	goto	label5

label6
	goto	label0

label1

	goto	$

	end