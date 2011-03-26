from __future__ import division
import time, math, sys, Image, os, logging
from datetime import datetime, timedelta
from twisted.internet import reactor, task
from txosc import osc, dispatch, async

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
        
class ReceiverApplication(object):
    """
    receive UDP OSC messages for light color settings
    """
    def __init__(self, port, lightState):
        self.port = port
        self.lightState = lightState
        self.receiver = dispatch.Receiver()
        self.receiver.addCallback("/pixel/*", self.pixel_handler)
        self._server_port = reactor.listenUDP(self.port, async.DatagramServerProtocol(self.receiver), interface='0.0.0.0')
        print("Listening on udp port %s" % (self.port))

    def pixel_handler(self, message, address):
        light = message.address.split('/')[2]
        rgb = [a.value * 1023 for a in message.arguments]
        print "OSC: set %s to %s" % (light, rgb)
        setColor(light, rgb)
        self.lightState.mute(light, 3)

lightYPos = {
    'deskLeft' : 125,
    'deskRight' : 175,
    'bathroom' : 75,
    'ari1' : 225,
    'ari2' : 275,
    'ari3' : 325,
}

class LightState(object):
    def __init__(self):
        self.img = Img("nightlight.png")
        self.autosetAfter = dict.fromkeys(lightYPos.keys(),
                                          datetime.fromtimestamp(0))

    def mute(self, name, secs):
        """don't autoset this light for a few seconds"""
        self.autosetAfter[name] = datetime.now() + timedelta(seconds=secs)

    def step(self):
        now = datetime.now()
        hr = now.hour + now.minute / 60 + now.second / 3600
        x = int(((hr - 12) % 24) * 50)
        log.info("x = %s", x)

        for name, ypos in lightYPos.items():
            if now > self.autosetAfter[name]:
                setColor(name, self.img.getColor(x, ypos))

lightState = LightState()
task.LoopingCall(lightState.step).start(1)
app = ReceiverApplication(9050, lightState)
reactor.run()
