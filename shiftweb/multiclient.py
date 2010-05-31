"""
send updates to shiftweb servers across multiple machines
"""
import logging
from restkit import Resource, RequestError
from shiftweb import hexFromRgb
log = logging.getLogger()

def setColor8(lightName, rgb):
    """takes 8-bit r,g,b"""
    return setColor(lightName, [x * 4 for x in rgb])

server = {
    'dash' : Resource('http://dash:9014/'),
    'slash' : Resource('http://slash:9014/'),
    }
def setColor(lightName, rgb):
    """takes 10-bit r,g,b

    returns even if the server is down
    """
    serv, chan = {
        'deskLeft' : (server['dash'], 1),
        'deskRight' : (server['dash'], 0),
        'bathroom' : (server['slash'], 0),
        }[lightName]
    try:
        serv.post("color", channel=chan, color=hexFromRgb(rgb))
    except RequestError, e:
        log.warn(e)
        

