#!/usr/bin/python
"""
launch with no args for GUI

launch with "-port xxxx" to serve xmlrpc

import from python to use ShiftBriteOutput class
"""

from __future__ import division
import sys
sys.path.append(".")
import getserial

class ShiftbriteArduino(object):
    def __init__(self, numChannels=1):
        self.ser = getserial.getSerial(9600)
        self.profile = None
        self.numChannels = numChannels

    def setProfile(self, name):
        """apply some named transfer function on levels before they're
        output"""
        self.profile = getattr(Profile, name)

    def update(self, colors):
        """list of 10-bit (r,g,b) values for all lights"""
        msg = ""
        for r, g, b in colors:
            r,g,b = r/4, g/4, b/4
            if self.profile is not None:
                r, g, b = self.profile(r, g, b)
            msg += chr(int(r)) + chr(int(g)) + chr(int(b))
        self.ser.write("\xff" + chr(self.numChannels) +
                       msg.replace("\xff", "\xfe"))

class Profile(object):
    @staticmethod
    def eyeball(r, g, b):
        """I guessed a whitepoint"""
        return r, int(g * 183 / 255), int(b * 45 / 255)
    # gamma up
    # something that's mostly accurate, but lets blues go really bright



def tkSliders(nleds=5):
    """Present r/g/b sliders that set the color of all leds. runs a tk
    mainloop"""
    import Tkinter as tk
    root = tk.Tk()
    chans = dict(r=tk.IntVar(), g=tk.IntVar(), b=tk.IntVar())

    out = ShiftbriteArduino()
    def update():
        out.send([(chans['r'].get(), chans['g'].get(), chans['b'].get())
                  for loop in range(nleds)])

    for chan in 'rgb':
        s = tk.Scale(root, label=chan,from_=254, to=0, showval=1,
                     command=lambda v,chan=chan: (chans[chan].set(v),update()),
                     length=300,width=80,sliderlen=80)
        s.pack(side='left',fill='both',exp=1)

    tk.mainloop()

if __name__ == "__main__":
    tkSliders()
