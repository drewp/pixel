"""
http interface to a ShiftBrite/MegaBrite
"""
from twisted.internet import reactor
from twisted.web import xmlrpc, server, http
from twisted.web.resource import Resource

from shiftpar import Shiftbrite

class Root(rend.Page):
    docFactory = loaders.xmlfile("shiftweb.html")

    def __init__(self, colors, update):
        """this object will read and write (r,g,b) triplets from the
        colors list, and call update() when it has changed a
        channel"""
        self.colors = colors
        self.update = upadte

    def child_color(self, ctx):
        """support for
              GET /color?channel=0
           and
              POST /color?channel=0&value=#ffe060"""
        request = inevow.IRequest(ctx)
        if request.method == 'post':
            channel = int(ctx.arg('channel'))
            value = ctx.arg('value')
            self.colors[channel] = value
            self.update()
        if



sb = Shiftbrite()
colors = [(0, 0, 0)]

def update():
    sb.setModes(1)
    sb.setColors(colors)

root = Root(colors, update)
reactor.listenTCP(9014, appserver.NevowSite(root))
reactor.run()
