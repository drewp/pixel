"""
http interface to a ShiftBrite/MegaBrite
"""
import sys
from optparse import OptionParser
from twisted.internet import reactor
from twisted.python import log
from nevow import rend, inevow, loaders, appserver, static
from drvparallel import ShiftbriteParallel
from drvarduino import ShiftbriteArduino

from webcolors import hex_to_rgb, rgb_to_hex

def rgbFromHex(h):
    """returns tuple of 0..1023"""
    norm = hex_to_rgb(h)
    return tuple([x * 4 for x in norm])

def hexFromRgb(rgb):
    return rgb_to_hex(tuple([x // 4 for x in rgb]))

class Root(rend.Page):
    docFactory = loaders.xmlfile("shiftweb.html")

    def __init__(self, shiftbrite):
        """this object will read and write (r,g,b) triplets from the
        colors list, and call update() when it has changed a
        channel"""
        self.colors = [(0,0,0)] * shiftbrite.numChannels
        self.shiftbrite = shiftbrite

    def child_static(self, ctx):
        return static.File("static")

    def child_color(self, ctx):
        """support for
              GET /color?channel=0
           and
              POST /color?channel=0&color=#ffe060"""
        request = inevow.IRequest(ctx)
        if request.method == 'POST':
            channel = int(ctx.arg('channel'))
            self.colors[channel] = rgbFromHex(ctx.arg('color'))
            self.shiftbrite.update(self.colors)
            return "updated %r" % self.colors
        elif request.method == 'GET':
            return hexFromRgb(self.colors[int(ctx.arg('channel'))])
        raise NotImplementedError


def main():

    parser = OptionParser()
    parser.add_option("--parallel", action="store_true",
                      help="use parallel port")
    parser.add_option("--arduino", action="store_true",
                      help="talk to an arduino over usb")
    opts, args = parser.parse_args()

    #log.startLogging(sys.stdout)

    if opts.parallel:
        sb = ShiftbriteParallel(dummyModeOk=True, numChannels=1)
    elif opts.arduino:
        sb = ShiftbriteArduino(numChannels=2)
    else:
        raise ValueError("pick an output mode")

    # also make a looping task that calls update() to correct noise errors
    # in the LED

    root = Root(sb)
    reactor.listenTCP(9014, appserver.NevowSite(root))
    reactor.run()

if __name__ == '__main__':
    main()
