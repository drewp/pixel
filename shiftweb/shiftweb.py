"""
http interface to a ShiftBrite/MegaBrite
"""
import sys, logging
from optparse import OptionParser
from twisted.internet import reactor
from twisted.python import log
from nevow import rend, inevow, loaders, appserver, static
from drvparallel import ShiftbriteParallel
from drvarduino import ShiftbriteArduino
logging.basicConfig(level=logging.INFO)
log = logging.getLogger()

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

    def child_otherBit(self, ctx):
        request = inevow.IRequest(ctx)
        if request.method == 'POST':
            bit = int(ctx.arg('bit'))
            self.shiftbrite.pulseOtherBit(bit)
            return "ok"

    def child_videoInput(self, ctx):
        """POST input={0..3}"""
        request = inevow.IRequest(ctx)
        if request.method == 'POST':
            i = int(ctx.arg('input'))
            self.shiftbrite.setOtherBit(4, i % 2)
            self.shiftbrite.setOtherBit(5, i // 2)
            return "ok"       


def main():

    parser = OptionParser()
    parser.add_option("--parallel", action="store_true",
                      help="use parallel port")
    parser.add_option("--arduino", action="store_true",
                      help="talk to an arduino over usb")
    parser.add_option("--failok", action="store_true",
                      help="if the parport can't be opened, start anyway")
    opts, args = parser.parse_args()

    #log.startLogging(sys.stdout)

    if opts.parallel:
        sb = ShiftbriteParallel(dummyModeOk=opts.failok, numChannels=1)
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
