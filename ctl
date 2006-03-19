#!/usr/bin/python

import Tkinter as tk
import serial
ser = None
ports = ["/dev/ttyUSB0", "/dev/ttyUSB1"]
for port in ports:
    try:
        ser = serial.Serial(port=port,baudrate=4800)
        break
    except serial.serialutil.SerialException, e:
        print e,
	if port != ports[-1]:
            print ", trying next port"
        else:
            print
if ser is None:
    raise RuntimeError("can't open any ports")
print "opened port %s" % port

root = tk.Tk()

chans = dict(r=tk.IntVar(), g=tk.IntVar(), b=tk.IntVar())

def change():
    ser.write(chr(int(chans['r'].get())))
#    ser.write("\x00\xee%s%s%s" % tuple([chr(int(chans[c].get())) for c in 'rgb']))

for chan in 'rgb':
    s = tk.Scale(root, label=chan,from_=255, to=0, showval=1,
                 command=lambda v,chan=chan: (chans[chan].set(v),change()),
                 length=300,width=80,sliderlen=80)
    s.pack(side='left',fill='both',exp=1)

val = 0
def loop():
    global val
    if val > 255:
        x = 511-val
    else:
        x = val
    ser.write(chr(x))
    val += 3
    if val > 511: val = 0
    root.after(20,loop)
#loop()
tk.mainloop()
