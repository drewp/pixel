"""
http interface to a ShiftBrite/MegaBrite
"""
import sys, logging, json
from optparse import OptionParser
from twisted.internet import reactor, task
from twisted.python import log
from nevow import rend, inevow, loaders, appserver, static
from twisted.web import http
try:
    from drvparallel import ShiftbriteParallel
except ImportError:
    pass
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

class Brite(rend.Page):
    def __init__(self, shiftbrite, colors):
        self.shiftbrite, self.colors = shiftbrite, colors
        
    def locateChild(self, ctx, segments):
        request = inevow.IRequest(ctx)
        if request.method == 'PUT':
            channel = int(segments[0])
            self.colors[channel] = rgbFromHex(request.content.read())
            self.shiftbrite.update(self.colors)
            return str("updated %r" % self.colors), []
        elif request.method == 'GET':
            return str(hexFromRgb(self.colors[int(segments[0])])), []
        raise NotImplementedError
        

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

    def child_brite(self, ctx):
        """support for
              GET /brite/0
           and
              PUT /brite/0 <- #ffe060"""
        return Brite(self.shiftbrite, self.colors)

    def child_otherBit(self, ctx):
        request = inevow.IRequest(ctx)
        if request.method == 'PUT':
            bit = int(ctx.arg('bit'))
            if ctx.arg('pulse') == '1':
                self.shiftbrite.pulseOtherBit(bit)
            else:
                try:
                    body = int(request.content.read().strip())
                except ValueError:
                    request.setResponseCode(http.BAD_REQUEST)
                    return "pass pulse=1 param, or a body of '0' or '1'"
                    
                self.shiftbrite.setOtherBit(bit, body)

            return "ok"
        elif request.method == 'GET':
            bit = int(ctx.arg('bit'))
            return str(int(self.shiftbrite.getOtherBit(bit)))
        else:
            request.setResponseCode(http.NOT_ALLOWED)
            request.setHeader('Allow', 'PUT,GET')
            return ""

    def child_videoInput(self, ctx):
        """POST input={0..3}"""
        request = inevow.IRequest(ctx)
        if request.method == 'POST':
            i = int(ctx.arg('input'))
            self.shiftbrite.setOtherBit(4, i % 2)
            self.shiftbrite.setOtherBit(5, i // 2)
            return "ok"

    def child_temperature(self, ctx):
        inevow.IRequest(ctx).setHeader("Content-type", "application/json")
        return json.dumps({"temp" : self.shiftbrite.getTemperature()})


def main():

    parser = OptionParser()
    parser.add_option("--parallel", action="store_true",
                      help="use parallel port")
    parser.add_option("--arduino", action="store_true",
                      help="talk to an arduino over usb")
    parser.add_option("--failok", action="store_true",
                      help="if the parport can't be opened, start anyway")
    parser.add_option("--channels", type="int", help="number of shiftbrites connected", default=2)
    parser.add_option("--pollbuttons", action="store_true",
         help="watch for remote control buttons and send them via OSC to udp localhost:10050")
    opts, args = parser.parse_args()

    import twisted.python
    #twisted.python.log.startLogging(sys.stdout)

    if opts.parallel:
        sb = ShiftbriteParallel(dummyModeOk=opts.failok, numChannels=1)
    elif opts.arduino:
        sb = ShiftbriteArduino(numChannels=opts.channels)
    else:
        raise ValueError("pick an output mode")

    # also make a looping task that calls update() to correct noise errors
    # in the LED

    if opts.pollbuttons:
        sys.path.append("../../ariremote")
        from oscserver import ArduinoWatcher
        aw = ArduinoWatcher(sb)
        task.LoopingCall(aw.poll).start(1.0/20)

    root = Root(sb)
    reactor.listenTCP(9014, appserver.NevowSite(root))
    reactor.run()

if __name__ == '__main__':
    main()
