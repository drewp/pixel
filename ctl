#!/usr/bin/python

import Tkinter as tk
import serial
ser = serial.Serial(port="/dev/ttyS1",baudrate=4800)


def change(val):
    ser.write(chr(int(val)))

root = tk.Tk()
s = tk.Scale(root, from_=255, to=0, showval=1, command=change,
             length=300,width=80,sliderlen=80)
s.pack(fill='both',exp=1)

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
loop()
tk.mainloop()
