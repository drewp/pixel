# based on Makefile in minipov

go: program-prog

MCU = attiny2313
F_CPU = 8000000 # 8 MHz
CFLAGS = -g -Os \
-funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums \
-Wall -Wstrict-prototypes \
-DF_CPU=$(F_CPU) -Wa,-adhlns=$(<:.c=.lst) \
-mmcu=$(MCU) -std=gnu99

program-%: %.elf
	avr-objcopy -O ihex -R .eeprom $< _program.hex
	avrdude -p $(MCU) -P /dev/parport0 -c dt006 -U flash:w:_program.hex

%.o: %.c
	avr-gcc -c -I. $(CFLAGS) $< -o $@

%.elf: %.o
	avr-gcc -I. $(CFLAGS) $< --output $@ -Wl,-Map=.map,--cref


