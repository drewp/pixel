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

class ShiftBriteOutput(object):
    def __init__(self):
        self.ser = getserial.getSerial(9600)
        self.profile = None

    def setProfile(self, name):
        """apply some named transfer function on levels before they're
        output"""
        self.profile = getattr(Profile, name)

    def send(self, levels):
        """list of (r,g,b) values for all lights"""
        msg = ""
        for r, g, b in levels:
            if self.profile is not None:
                r, g, b = self.profile(r, g, b)
            msg += chr(int(r)) + chr(int(g)) + chr(int(b))
        self.ser.write("\xff" + msg.replace("\xff", "\xfe"))

class Profile(object):
    @staticmethod
    def eyeball(r, g, b):
        """I guessed a whitepoint"""
        return r, int(g * 183 / 255), int(b * 45 / 255)
    # gamma up
    # something that's mostly accurate, but lets blues go really bright


def xmlrpcServer(port=9002):
    """expose the ShiftBriteOutput.send method via xmlrpc. Example
    client:

    import xmlrpclib
    serv = xmlrpclib.Server('http://localhost:9002/')
    g = (0, 254, 0)
    serv.send([g, g, g, g, g])
    """
    from twisted.internet import reactor
    from twisted.web import xmlrpc, server, http
    from twisted.web.resource import Resource

    #from twisted.python import log
    #log.startLogging(sys.stdout)
    out = ShiftBriteOutput()

    class Root(Resource):

        def render_POST(self, request):
            # see http://twistedmatrix.com/projects/web/documentation/howto/using-twistedweb.html#rendering
            if request.path == '/':
                if 'query' not in request.args:
                    return self.stats.statusPage()
                return self.getQuery(request)

            if request.path == '/save':
                return self.getSave(request)

            request.setResponseCode(http.BAD_REQUEST)
            return "<html>Invalid request: this is a sparql query server</html>"

    class XMLRPCServe(xmlrpc.XMLRPC):
        def xmlrpc_send(self, levels):
            out.send(levels)
            return "ok"

    root = Root()
    root.putChild('/RPC2', XMLRPCServe)
        
    reactor.listenTCP(port, server.Site(root))
    reactor.run()


def tkSliders(nleds=5):
    """Present r/g/b sliders that set the color of all leds. runs a tk
    mainloop"""
    import Tkinter as tk
    root = tk.Tk()
    chans = dict(r=tk.IntVar(), g=tk.IntVar(), b=tk.IntVar())

    out = ShiftBriteOutput()
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
    if len(sys.argv) == 3 and sys.argv[1] == '-port':
        xmlrpcServer(port=int(sys.argv[2]))
    else:
        tkSliders()
