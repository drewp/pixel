from __future__ import division
import time, sys, Image, os, logging, json, traceback
from datetime import datetime, timedelta
from twisted.internet import reactor, task
from txosc import dispatch, async
import cyclone.web
from dateutil.tz import tzlocal

sys.path.append("shiftweb")
from multiclient import setColorAsync
logging.basicConfig(level=logging.DEBUG)
log = logging.getLogger()
logging.getLogger('restkit.client').setLevel(logging.WARN)
#log.setLevel(logging.DEBUG)

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
        log.info("Listening OSC on udp port %s" % (self.port))

    def pixel_handler(self, message, address):
        light = message.address.split('/')[2]
        rgb = [a.value * 1023 for a in message.arguments]
        print "OSC: set %s to %s" % (light, rgb)
        setColorAsync(light, rgb)
        self.lightState.mute(light, 3)

lightYPos = {
    'deskLeft' : 125,
    'deskRight' : 175,
    'bathroom' : 75,
    'ari1' : 225,
    'ari2' : 275,
    'ari3' : 325,
    'bedroom' : 375,
    'bedroomBall' : 422,
    'bedroomWall0' : 450,
    'bedroomWall1' : 478,
    'bedroomWall2' : 511,
    'bedroomWall3' : 541,
}

class LightState(object):
    def __init__(self):
        self.lastUpdateTime = 0
        self.lastErrorTime = 0
        self.lastError = ""
        self.img = Img("nightlight.png")
        self.autosetAfter = dict.fromkeys(lightYPos.keys(),
                                          datetime.fromtimestamp(0, tzlocal()))

    def mute(self, name, secs):
        """don't autoset this light for a few seconds"""
        self.autosetAfter[name] = datetime.now(tzlocal()) + timedelta(seconds=secs)

    def step(self):
        try:
            now = datetime.now(tzlocal())
            hr = now.hour + now.minute / 60 + now.second / 3600
            x = int(((hr - 12) % 24) * 50)
            log.debug("x = %s", x)

            for name, ypos in lightYPos.items():
                if now > self.autosetAfter[name]:
                    c = self.img.getColor(x, ypos)
                    setColorAsync(name, c)
            self.lastUpdateTime = time.time()
        except Exception:
            self.lastError = traceback.format_exc()
            self.lastErrorTime = time.time()
            
            
class IndexHandler(cyclone.web.RequestHandler):
    def get(self):
        ls = self.settings.lightState
        now = time.time()
        self.set_header("content-type", "application/json")
        self.set_status(200 if ls.lastUpdateTime > ls.lastErrorTime else 500)
        self.write(json.dumps(dict(
            secsSinceLastUpdate=now - ls.lastUpdateTime,
            secsSinceLastError=now - ls.lastErrorTime,
            lastError=ls.lastError,
            ), indent=4))

lightState = LightState()
task.LoopingCall(lightState.step).start(2)
app = ReceiverApplication(9050, lightState)
log.info("listening http on 9051")
reactor.listenTCP(9051, cyclone.web.Application([
    (r'/', IndexHandler),
    ], lightState=lightState))
reactor.run()
