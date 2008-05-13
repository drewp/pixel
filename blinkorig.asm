;File Demo.asm
;Assembly code for PIC 16F84 microcontroller.
 
;Blinks LEDs on PORTB outputs in a sequential pattern.
;With a 75 kHz oscillator, each LED stays on about 1/2 second.
 
;CPU configuration
;           PIC 16F84, RC oscillator, watchdog timer off, power-up timer enabled.
;            Note: two underscore characters before the config command.
 
            processor 16f84A
            include  <p16f84a.inc>
            __config _RC_OSC &_WDT_OFF &_PWRTE_ON
 
;Declare variables at two memory locations
 
J           equ       H'1F'     ;J stored at hex address 1F.
K          equ       H'1E'     ;K stored at hex address 1E.
 
;Program
 
            org        0          ;Start program at address zero.
 
            ;Set PORTB as output and initialize it.
            movlw   B'00000000'       ;Move 8 binary zeros to the W (working) register.
            tris        PORTB             ;Move Contents of W register to PORTB control register.
            movlw   B'00000001'       ;Move binary one to the W register.
            movwf   PORTB             ;Move binary one to PORTB.
 
mloop:  rlf          PORTB,f           ;Rotate PORTB bits left one space.
 
  
            ;Waste some time by executing nested loops.
 
            movlw   D'50'       ;Move decimal 5 to the W register.
            movwf   J           ;Copy the decimal 5 from the W register to J.
jloop:    movwf   K          ;Copy the decimal 5 from the W register to K.
kloop:   decfsz   K,f        ;K=K-1, skip next instruction if zero.
            goto      kloop
            decfsz   J,f         ;J=J-1, skip next instruction if zero.
            goto      jloop
 
            ;Do it all again.
 
            goto      mloop
 
            end
