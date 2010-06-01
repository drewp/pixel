from __future__ import division
import time, math, sys, Image, datetime, os, logging
sys.path.append("shiftweb")
from multiclient import setColor
logging.basicConfig()
log = logging.getLogger()
log.setLevel(logging.WARN)

class Img(object):
    def __init__(self, filename):
        self.filename = filename
        self.reread()

    def reread(self):
        try:
            self.img = Image.open(self.filename)
        except IOError: # probably mid-write
            time.sleep(.5)
            self.img = Image.open(self.filename)
        self.mtime = os.path.getmtime(self.filename)

    def getColor(self, x, y):
        """10-bit rgb"""
        if os.path.getmtime(self.filename) > self.mtime:
            self.reread()
        return [v * 4 for v in self.img.getpixel((x, y))[:3]]
        

def main():

    img = Img("nightlight.png")
    while 1:
        now = datetime.datetime.now()
        hr = now.hour + now.minute / 60 + now.second / 3600
        x = int(((hr - 12) % 24) * 50)
        log.info("x = %s", x)

        setColor('deskLeft', img.getColor(x, 125))
        setColor('deskRight', img.getColor(x, 175))
        setColor('bathroom', img.getColor(x, 75))
        setColor('ari1', img.getColor(x, 225))
        setColor('ari2', img.getColor(x, 275))
        setColor('ari3', img.getColor(x, 325))

        time.sleep(3)
main()
