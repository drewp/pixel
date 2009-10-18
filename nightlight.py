from __future__ import division
import xmlrpclib, time, math, sys
sys.path.append("shiftweb")
from multiclient import setColor

def main():
    while 1:
        for loop in range(200):
            x = (math.sin(time.time() * .5) / 2 + .5) * 1023
            print x
            setColor('deskLeft', (1023-x, 0, (1023 - x) * .5))
            setColor('deskRight', (0, x * .3, x))
            #setColor('bathroom', (0, x * .3, x))

            setColor('bathroom', (x, x, x))

            time.sleep(.01)
main()
