"""
http interface to a ShiftBrite/MegaBrite
"""
import sys
from twisted.internet import reactor
from twisted.web import server, http
from twisted.python import log
from nevow import rend, inevow, loaders, appserver, static
from shiftpar import Shiftbrite

from webcolors import hex_to_rgb, rgb_to_hex

def rgbFromHex(h):
    """returns tuple of 0..1023"""
    norm = hex_to_rgb(h)
    return tuple([x * 4 for x in norm])

def hexFromRgb(rgb):
    return rgb_to_hex(tuple([x // 4 for x in rgb]))

class Root(rend.Page):
    docFactory = loaders.xmlfile("shiftweb.html")

    def __init__(self, colors, update):
        """this object will read and write (r,g,b) triplets from the
        colors list, and call update() when it has changed a
        channel"""
        self.colors = colors
        self.update = update

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
            self.update()
            return "updated %r" % self.colors
        elif request.method == 'GET':
            return hexFromRgb(self.colors[int(ctx.arg('channel'))])
        raise NotImplementedError
    
sb = Shiftbrite(dummyModeOk=True)
colors = [(0, 0, 0)] # length of this list controls how many channels we're addressing

def update():
    sb.setModes(len(colors))
    sb.sendColors(colors)

log.startLogging(sys.stdout)

# also make a looping task that calls update() to correct noise errors
# in the LED

root = Root(colors, update)
reactor.listenTCP(9014, appserver.NevowSite(root))
reactor.run()
