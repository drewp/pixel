#!/usr/bin/python
from __future__ import division
import time
import getserial

ser = getserial.getSerial(115200)

## delay = .1
## while True:
##     for i in range(5):
##         writeColor(150, 50, 0)
##     time.sleep(delay)
    
##     for i in range(5):
##         writeColor(0, 0, 200)
##     time.sleep(delay)    

import Tkinter as tk
root = tk.Tk()
chans = dict(r=tk.IntVar(), g=tk.IntVar(), b=tk.IntVar())
def update():
    msg = ""
    for i in range(5):
        msg += chr(chans['r'].get()) + chr(chans['g'].get()) + chr(chans['b'].get())
    ser.write(msg)
    print "write"
                   
for chan in 'rgb':
    s = tk.Scale(root, label=chan,from_=255, to=0, showval=1,
                 command=lambda v,chan=chan: (chans[chan].set(v),update()),
                 length=300,width=80,sliderlen=80)
    s.pack(side='left',fill='both',exp=1)

tk.mainloop()
