#!/usr/bin/python

from __future__ import division
import random, itertools
import Tkinter as tk
import getserial

ser = getserial.getSerial()

root = tk.Tk()

chans = dict(r=tk.IntVar(), g=tk.IntVar(), b=tk.IntVar())

def change():
#    ser.write(chr(int(chans['r'].get())))
    ser.write("\x00\xee%s%s%s" % tuple([chr(int(chans[c].get())) for c in 'rgb']))
#    print "readback", repr(ser.read(1))

for chan in 'rgb':
    s = tk.Scale(root, label=chan,from_=255, to=0, showval=1,
                 command=lambda v,chan=chan: (chans[chan].set(v),change()),
                 length=300,width=80,sliderlen=80)
    s.pack(side='left',fill='both',exp=1)

randvar = tk.IntVar()
rand = tk.Checkbutton(root, text="random color every second", variable=randvar)
rand.pack()

def random_loop():
    if randvar.get():
        old = dict([(c, chans[c].get()) for c in 'rgb'])
        new = dict(r=random.randrange(0,255), g=random.randrange(0,255),
                   b=random.randrange(0,255))
        for step in range(20):
            t = step / 20
            for c in 'rgb':
                col = int((1 - t) * old[c] + t * new[c])
                chans[c].set(col)
            change()
    root.after(1000, random_loop)
random_loop()


val = 0
def loop():
    global val
    if val > 255:
        x = 511-val
    else:
        x = val
#    ser.write(chr(x))
    val += 3
    if val > 511: val = 0
    root.after(20,loop)
#loop()




for key, bit in [("1", 2), ("2", 3), ("3", 4), ("4", 5)]:
    root.bind("<KeyPress-%s>" % key,
              lambda ev, bit=bit: ser.write(chr(1 << bit)))
    root.bind("<KeyRelease-%s>" % key,
              lambda ev: ser.write("\x00"))


_cmds = []
def push_cmd(byte):
    _cmds.append(byte)

def send_cmds():
    if _cmds:
        c = _cmds.pop(0)
        print "push %r (%d left)" % (c, len(_cmds))
        ser.write(c)
        #print "write %d" % (len(_cmds))
        #ser.write("".join(_cmds))
        #_cmds[:] = []
    root.after(10, send_cmds)
#send_cmds()
        

seq = [
    4,
    4,
    4 + 16,
    16,
    16,
    16 + 8,
    8,
    8,
    8 + 32,
    32,
    32,
    32 + 4,
    
       ] # portd bit


## for c in itertools.cycle(seq):
##     push_cmd(chr(c))
##     if len(_cmds) > 1000:
##         break


s = tk.Scale(root, label="stepper", from_=0, to=100, showval=1,
             command=lambda v: push_cmd(chr(seq[int(v) % len(seq)])))
s.pack(side='left', fill='both', exp=1)


tk.mainloop()
