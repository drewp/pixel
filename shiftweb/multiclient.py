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

lightResource = {
    'deskLeft' :     lambda: Resource('http://dash:9014/brite/0', timeout=2),
    'deskRight' :    lambda: Resource('http://dash:9014/brite/1', timeout=2),
    'bathroom' :     lambda: Resource('http://slash:9050/brite/0', timeout=2),
    'ari1' :         lambda: Resource('http://star:9014/brite/0', timeout=2),
    'ari2' :         lambda: Resource('http://star:9014/brite/1', timeout=2),
    'ari3' :         lambda: Resource('http://star:9014/brite/2', timeout=2),
    'bedroom' :      lambda: Resource('http://bang:9060/brite/0', timeout=2),
    'bedroomWall0' : lambda: Resource('http://bang:9060/brite/1', timeout=2),
    'bedroomWall1' : lambda: Resource('http://bang:9060/brite/2', timeout=2),
    'bedroomWall2' : lambda: Resource('http://bang:9060/brite/3', timeout=2),
    'bedroomWall3' : lambda: Resource('http://bang:9060/brite/4', timeout=2),
    'slash-zwave' :  lambda: Resource('http://slash:9082', timeout=2),
    }
def setColor(lightName, rgb):
    """takes 10-bit r,g,b

    returns even if the server is down
    """
    log.debug("setColor(%r,%r)", lightName, rgb)
    if lightName == 'bedroomBall':
        try:
            lightResource['slash-zwave']().put("/nodes/2/level", payload="%g" % (rgb[0]/1024))
        except Exception, e:
            log.warn(e) 
        return
    
    serv = lightResource[lightName]()
    try:
        h = hexFromRgb(rgb)
        log.debug("put %r to %r", h, serv)
        serv.put(payload=h, headers={"content-type":"text/plain"})

    except (RequestError, RequestFailed, socket.error), e:
        log.warn("Talking to: %r" % serv)
        log.warn(e)
        

# switch to cyclone client?
