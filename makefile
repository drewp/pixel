
prog: pixel.hex
	/my/dl/modified/kitsrus_pic_programmer/micropro.py -p /dev/ttyS0 --pic_type 16F84AICSP -i $<

pixel.hex: pixel.asm
	gpasm $<
