"""
send updates to shiftweb servers across multiple machines
"""
from __future__ import division
import logging, socket
from restkit import Resource, RequestError, RequestFailed
from shiftweb import hexFromRgb
log = logging.getLogger()

def setColor8(lightName, rgb):
    """takes 8-bit r,g,b"""
    return setColor(lightName, [x * 4 for x in rgb])

server = {
    'dash' : Resource('http://dash:9014/', timeout=2),
    'slash' : Resource('http://slash:9014/', timeout=2),
    'star' : Resource('http://star:9014/', timeout=2),
    'bang0' : Resource('http://bang:9060/brite/0', timeout=2),
    'bang1' : Resource('http://bang:9060/brite/1', timeout=2),
    'bang2' : Resource('http://bang:9060/brite/2', timeout=2),
    'bang3' : Resource('http://bang:9060/brite/3', timeout=2),
    'bang4' : Resource('http://bang:9060/brite/4', timeout=2),
    'dash-zwave' : Resource('http://dash:9082', timeout=2),
    }
def setColor(lightName, rgb):
    """takes 10-bit r,g,b

    returns even if the server is down
    """
    if lightName == 'bedroomBall':
        try:
            server['dash-zwave'].put("/nodes/2/level", payload="%g" % (rgb[0]/1024))
        except Exception, e:
            log.warn(e) 
        return
    serv, chan = {
        'deskLeft' : (server['dash'], 1),
        'deskRight' : (server['dash'], 0),
        'bathroom' : (server['slash'], 0),
        'ari1' : (server['star'], 0),
        'ari2' : (server['star'], 1),
        'ari3' : (server['star'], 2),
        'bedroom' : (server['bang0'], 0),
        'bedroomWall0' : (server['bang1'], 0),
        'bedroomWall1' : (server['bang2'], 0),
        'bedroomWall2' : (server['bang3'], 0),
        'bedroomWall3' : (server['bang4'], 0),
        }[lightName]
    try:
        h = hexFromRgb(rgb)
        if lightName.startswith('bed'):
            serv.put(payload=h, headers={"content-type":"text/plain"})
        else:
            serv.post("color", channel=chan, color=h)
    except (RequestError, RequestFailed, socket.error), e:
        log.warn("Talking to: %r" % ((serv, chan),))
        log.warn(e)
        

